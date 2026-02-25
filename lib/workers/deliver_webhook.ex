defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook payloads.
  """
  use Plausible
  use Plausible.Repo
  use Oban.Worker, queue: :webhooks, max_attempts: 3
  require Logger

  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery
  alias Plausible.Webhooks.PayloadSigner
  alias Plausible.Webhooks.PayloadBuilder

  # Retry delays: 1 min, 5 min, 15 min (total 30 min max)
  @retry_delays [60_000, 300_000, 900_000]

  def perform(%Oban.Job{args: %{"delivery_id" => delivery_id}}) do
    delivery = Repo.get!(Delivery, delivery_id)
    webhook = Repo.get!(Webhook, delivery.webhook_id)

    Logger.info("Starting webhook delivery",
      delivery_id: delivery.id,
      webhook_id: webhook.id,
      site_id: webhook.site_id,
      url: webhook.url,
      trigger_type: delivery.trigger_type,
      attempt: delivery.attempt
    )

    # Check if webhook is still active
    if webhook.active do
      deliver_webhook(delivery, webhook)
    else
      Logger.warning("Webhook delivery skipped - webhook is inactive",
        delivery_id: delivery.id,
        webhook_id: webhook.id
      )
      {:cancel, "Webhook is inactive"}
    end
  rescue
    e in Oban.CancelableError ->
      Logger.error("Webhook delivery cancelled",
        delivery_id: delivery_id,
        error: inspect(e)
      )
      {:cancel, "Job cancelled: #{inspect(e)}"}

    e ->
      Logger.error("Webhook delivery failed with unexpected error",
        delivery_id: delivery_id,
        error: inspect(e)
      )
      # For other errors, attempt retry
      {:error, inspect(e)}
  end

  defp deliver_webhook(delivery, webhook) do
    # Build the payload
    payload = PayloadBuilder.build(delivery.trigger_type, delivery.event_data)

    # Sign the payload if secret is configured
    headers = build_headers(webhook, payload)

    # Make the HTTP request
    case make_http_request(webhook.url, payload, headers) do
      {:ok, status_code, response_body} ->
        handle_success(delivery, status_code, response_body)

      {:error, reason} ->
        handle_failure(delivery, reason)
    end
  end

  defp build_headers(webhook, payload) do
    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Event-ID", to_string(webhook.id)},
      {"X-Webhook-Event-Type", "webhook_event"}
    ]

    # Add signature if secret is configured
    if webhook.secret do
      signature = PayloadSigner.sign(payload, webhook.secret)
      headers ++ [{"X-Webhook-Signature", "sha256=#{signature}"}]
    else
      headers
    end
  end

  defp make_http_request(url, payload, headers) do
    # Use HTTPoison to make the request
    case HTTPoison.post(url, Jason.encode!(payload), headers, [
           timeout: 30_000,
           recv_timeout: 30_000
         ]) do
      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:ok, code, String.slice(body, 0, 4096)}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, inspect(reason)}
    end
  end

  defp handle_success(delivery, status_code, response_body) when status_code >= 200 and status_code < 300 do
    # Update delivery as successful
    delivery
    |> Ecto.Changeset.change(%{
      status: Delivery.status_success(),
      response_code: status_code,
      response_body: response_body
    })
    |> Repo.update!()

    Logger.info("Webhook delivered successfully",
      delivery_id: delivery.id,
      webhook_id: delivery.webhook_id,
      status_code: status_code,
      attempt: delivery.attempt
    )

    :ok
  end

  defp handle_success(delivery, status_code, response_body) when status_code >= 400 and status_code < 500 do
    # Client error - don't retry
    delivery
    |> Ecto.Changeset.change(%{
      status: Delivery.status_failed(),
      response_code: status_code,
      response_body: response_body,
      error_message: "Client error: #{status_code}"
    })
    |> Repo.update!()

    Logger.warning("Webhook delivery failed - client error (not retrying)",
      delivery_id: delivery.id,
      webhook_id: delivery.webhook_id,
      status_code: status_code,
      error: "Client error: #{status_code}"
    )

    {:cancel, "Client error - not retrying"}
  end

  defp handle_success(delivery, status_code, response_body) do
    # Server error or other - will retry
    handle_failure(delivery, "Server error: #{status_code}")
  end

  defp handle_failure(delivery, reason) do
    new_attempt = delivery.attempt + 1

    if new_attempt <= 3 do
      # Schedule retry with exponential backoff
      delay = Enum.at(@retry_delays, new_attempt - 2, 900_000)

      delivery
      |> Ecto.Changeset.change(%{
        status: Delivery.status_retrying(),
        attempt: new_attempt,
        error_message: String.slice(reason, 0, 1024)
      })
      |> Repo.update!()

      Logger.warning("Webhook delivery failed - scheduling retry",
        delivery_id: delivery.id,
        webhook_id: delivery.webhook_id,
        attempt: new_attempt,
        max_attempts: 3,
        delay_ms: delay,
        error: reason
      )

      # Schedule retry job
      %{delivery_id: delivery.id}
      |> __MODULE__.new(schedule_in: delay)
      |> Oban.insert!()

      {:scheduled, delay}
    else
      # Max attempts reached - mark as failed
      delivery
      |> Ecto.Changeset.change(%{
        status: Delivery.status_failed(),
        attempt: new_attempt,
        error_message: String.slice(reason, 0, 1024)
      })
      |> Repo.update!()

      Logger.error("Webhook delivery failed - max retries exceeded",
        delivery_id: delivery.id,
        webhook_id: delivery.webhook_id,
        total_attempts: new_attempt,
        error: reason
      )

      {:cancel, "Max retries exceeded"}
    end
  end

  # Timeout error handling
  def timeout(%Oban.Job{args: %{"delivery_id" => delivery_id}}) do
    delivery = Repo.get!(Delivery, delivery_id)
    Logger.warning("Webhook delivery timed out",
      delivery_id: delivery.id,
      webhook_id: delivery.webhook_id,
      attempt: delivery.attempt
    )
    handle_failure(delivery, "Request timeout")
  end
end
