defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook payloads to configured endpoints.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Site.{Webhook, WebhookTrigger, WebhookDelivery}

  use Oban.Worker,
    queue: :webhook_delivery,
    max_attempts: 4,
    retry_with: [delay: &webhook_retry_delay/1]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    webhook_id = args["webhook_id"]
    trigger_id = args["trigger_id"]
    event_type = args["event_type"]
    payload = args["payload"]

    webhook = Repo.get(Webhook, webhook_id) |> Repo.preload(:triggers)

    if webhook && webhook.enabled do
      deliver_webhook(webhook, trigger_id, event_type, payload)
    else
      :ok
    end
  end

  defp deliver_webhook(webhook, trigger_id, event_type, payload) do
    # Create delivery record
    {:ok, delivery} =
      Site.create_webhook_delivery(%{
        webhook_id: webhook.id,
        trigger_id: trigger_id,
        event_type: event_type,
        payload: payload,
        attempt_number: 1
      })

    # Sign the payload
    signature = sign_payload(payload, webhook.secret)

    # Send HTTP POST
    headers = [
      {"content-type", "application/json"},
      {"x-signature", "sha256=#{signature}"},
      {"user-agent", "Plausible-Analytics/1.0"}
    ]

    case Plausible.HTTPClient.post(webhook.url, headers, payload) do
      {:ok, %{status: status, body: body}} when status >= 200 and status < 300 ->
        Site.update_webhook_delivery(delivery, %{
          status_code: status,
          response_body: body
        })

      {:ok, %{status: status, body: body}} ->
        Site.update_webhook_delivery(delivery, %{
          status_code: status,
          response_body: body,
          error_message: "HTTP error"
        })

        {:error, :delivery_failed}

      {:error, reason} ->
        error_message = inspect(reason)

        Site.update_webhook_delivery(delivery, %{
          error_message: error_message
        })

        {:error, reason}
    end
  end

  defp sign_payload(payload, secret) when is_map(payload) do
    payload_json = Jason.encode!(payload)

    :crypto.mac(
      :hmac,
      :sha256,
      secret,
      payload_json
    )
    |> Base.encode16(case: :lower)
  end

  # Retry with exponential backoff: 1min, 10min, 60min
  defp webhook_retry_delay(attempt) do
    case attempt do
      1 -> :timer.minutes(1)
      2 -> :timer.minutes(10)
      3 -> :timer.minutes(60)
      _ -> :timer.minutes(60)
    end
  end
end
