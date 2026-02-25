defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook notifications with retry logic.
  """
  use Plausible
  use Plausible.Repo
  use Oban.Worker, queue: :webhook_notifications

  alias Plausible.Site.Webhook
  alias Plausible.Site.WebhookDelivery
  alias Plausible.Webhooks

  @max_attempts 3
  @backoff_intervals [60, 300, 900] # 1min, 5min, 15min in seconds
  @http_timeout 30_000

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"webhook_id" => webhook_id, "delivery_id" => delivery_id}}) do
    webhook = Repo.get(Webhook, webhook_id)
    delivery = Repo.get(WebhookDelivery, delivery_id)

    cond do
      is_nil(webhook) ->
        {:cancel, "webhook not found"}

      not webhook.enabled ->
        {:cancel, "webhook disabled"}

      is_nil(delivery) ->
        {:cancel, "delivery not found"}

      true ->
        deliver(webhook, delivery)
    end
  end

  defp deliver(webhook, delivery) do
    payload = Jason.encode!(delivery.payload)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Event", delivery.event_type},
      {"X-Webhook-Site-Id", webhook.site.domain}
    ]
    |> add_signature_header(webhook.secret, payload)

    case make_request(webhook.url, payload, headers) do
      {:ok, status_code, response_body} ->
        handle_success(delivery, status_code, response_body)
        :ok

      {:error, reason} ->
        handle_failure(delivery, reason)
    end
  end

  defp make_request(url, body, headers) do
    case HTTPoison.post(url, body, headers, timeout: @http_timeout, recv_timeout: @http_timeout) do
      {:ok, %{status_code: code, body: body}} ->
        {:ok, code, body}

      {:error, %{reason: reason}} ->
        {:error, inspect(reason)}
    end
  end

  defp handle_success(delivery, status_code, response_body) do
    delivery
    |> WebhookDelivery.mark_success(status_code, response_body)
    |> Repo.update!()

    Logger.info("Webhook delivered successfully", webhook_id: delivery.webhook_id, status: status_code)
  end

  defp handle_failure(delivery, reason) do
    attempts = delivery.attempts + 1

    if attempts >= @max_attempts do
      delivery
      |> WebhookDelivery.mark_failed(nil, reason)
      |> Repo.update!()

      # Check if webhook should be disabled
      webhook = Repo.get(Webhook, delivery.webhook_id)
      Webhooks.disable(webhook)

      Logger.error("Webhook delivery failed after max attempts",
        webhook_id: delivery.webhook_id,
        attempts: attempts,
        reason: reason
      )

      {:discard, "max attempts reached"}
    else
      next_retry_at = calculate_next_retry(attempts)

      delivery
      |> WebhookDelivery.mark_retrying(next_retry_at)
      |> Repo.update!()

      # Schedule retry
      %{webhook_id: delivery.webhook_id, delivery_id: delivery.id}
      |> __MODULE__.new(scheduled_at: next_retry_at)
      |> Oban.insert!()

      Logger.warning("Webhook delivery failed, scheduling retry",
        webhook_id: delivery.webhook_id,
        attempts: attempts,
        next_retry: next_retry_at
      )

      :ok
    end
  end

  defp calculate_next_retry(attempt) do
    interval = Enum.at(@backoff_intervals, attempt - 1, 900)
    NaiveDateTime.add(NaiveDateTime.utc_now(), interval, :second)
  end

  defp add_signature_header(headers, nil, _payload), do: headers
  defp add_signature_header(headers, "", _payload), do: headers

  defp add_signature_header(headers, secret, payload) do
    signature = :crypto.mac(:hmac, :sha256, secret, payload)
    signature_hex = Base.encode16(signature, case: :lower)
    [{"X-Webhook-Signature", "sha256=#{signature_hex}"} | headers]
  end
end
