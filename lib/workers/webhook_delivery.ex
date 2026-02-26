defmodule Plausible.Workers.WebhookDelivery do
  @moduledoc """
  Oban worker for delivering webhook events.
  Implements retry logic with exponential backoff and rate limiting.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Site.WebhookEvent
  alias Plausible.Site.WebhookDeliveryLog
  alias Plausible.Site.Webhook

  use Oban.Worker, queue: :webhooks, max_attempts: 3

  @retry_delays [
    60_000,    # 1 minute
    300_000,   # 5 minutes
    1_800_000  # 30 minutes
  ]

  @rate_limit_seconds 60  # Max 1 delivery per webhook per minute

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"webhook_event_id" => event_id}, attempt: attempt}) do
    event = Repo.get!(WebhookEvent, event_id) |> Repo.preload(:webhook)

    if event.status == "pending" or event.status == "delivering" do
      if rate_limited?(event.webhook) do
        {:retry, "Rate limited - will retry"}
      else
        deliver_event(event, attempt)
      end
    else
      :skip
    end
  end

  defp rate_limited?(webhook) do
    case webhook.last_sent do
      nil ->
        false

      last_sent ->
        seconds_since_last_sent = NaiveDateTime.diff(NaiveDateTime.utc_now(), last_sent, :second)
        seconds_since_last_sent < @rate_limit_seconds
    end
  end

  defp deliver_event(event, attempt) do
    webhook = event.webhook

    # Mark as delivering
    event
    |> WebhookEvent.mark_delivering()
    |> Repo.update!()

    # Attempt delivery
    case Plausible.Webhooks.deliver_webhook(webhook, event.payload) do
      {:ok, status_code, response_body} ->
        # Log success with response body for debugging
        %WebhookDeliveryLog{}
        |> WebhookDeliveryLog.changeset(%{
          webhook_event_id: event.id,
          status_code: status_code,
          response_body: response_body,
          delivered_at: NaiveDateTime.utc_now()
        })
        |> Repo.insert!()

        # Mark event as delivered
        event
        |> WebhookEvent.mark_delivered()
        |> Repo.update!()

        # Update webhook last_sent
        webhook
        |> Ecto.Changeset.change(last_sent: NaiveDateTime.utc_now())
        |> Repo.update!()

        :ok

      {:error, message, response_body} ->
        # Log failure with response body for debugging
        %WebhookDeliveryLog{}
        |> WebhookDeliveryLog.changeset(%{
          webhook_event_id: event.id,
          error_message: message,
          response_body: response_body
        })
        |> Repo.insert!()

        # Check if we've exhausted all retry attempts
        if attempt >= @max_attempts do
          # Mark as failed after max retries exhausted
          event
          |> WebhookEvent.mark_failed()
          |> Repo.update!()

          {:error, "Max attempts exhausted: #{message}"}
        else
          # Signal Oban to retry with exponential backoff
          {:retry, message}
        end
    end
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    base_delay = Enum.at(@retry_delays, attempt - 1, 300_000)
    # Add jitter: random value between 0 and 30% of base delay
    jitter = round(base_delay * :rand.uniform() * 0.3)
    base_delay + jitter
  end
end
