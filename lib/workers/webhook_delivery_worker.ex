defmodule Plausible.Workers.WebhookDeliveryWorker do
  @moduledoc """
  Worker for delivering webhook notifications with retry logic
  """
  use Plausible
  use Plausible.Repo
  use Oban.Worker, queue: :webhook_delivery, max_attempts: 3

  alias Plausible.WebhookNotifications
  alias Plausible.WebhookNotifications.Delivery

  @retry_delays [
    30_000,  # 30 seconds
    300_000  # 5 minutes
  ]

  @impl true
  def perform(%Oban.Job{args: %{"delivery_log_id" => delivery_log_id}}) do
    delivery_log =
      WebhookNotifications.DeliveryLog
      |> Repo.get!(delivery_log_id)
      |> Repo.preload(webhook_config: [:site])

    # Check if webhook is still active
    unless delivery_log.webhook_config.is_active do
      {:cancel, "Webhook is disabled"}
    end

    deliver_webhook(delivery_log)
  end

  defp deliver_webhook(delivery_log) do
    webhook = delivery_log.webhook_config
    payload = Jason.encode!(delivery_log.payload)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Event", delivery_log.event_type},
      {"X-Webhook-Signature", Delivery.generate_signature(payload, webhook.secret)}
    ]

    case Plausible.HTTPClient.post(webhook.endpoint_url, headers, payload, timeout: 30_000) do
      {:ok, %{status: status_code, body: body}} when status_code >= 200 and status_code < 300 ->
        WebhookNotifications.mark_delivery_success(delivery_log, status_code, body)
        :ok

      {:ok, %{status: status_code, body: body}} ->
        handle_failure(delivery_log, status_code, body)

      {:error, %Plausible.HTTPClient.Non200Error{reason: %{status: status_code, body: body}}} ->
        handle_failure(delivery_log, status_code, body)

      {:error, reason} ->
        handle_failure(delivery_log, nil, inspect(reason))
    end
  end

  defp handle_failure(delivery_log, status_code, response_body) do
    attempt_number = delivery_log.attempt_number

    cond do
      # Non-retryable error (4xx)
      status_code && status_code >= 400 && status_code < 500 ->
        WebhookNotifications.mark_delivery_failure(delivery_log, status_code, response_body, attempt_number)
        {:cancel, "Permanent failure - HTTP #{status_code}"}

      # Retryable error (5xx or network error)
      true ->
        if attempt_number < 3 do
          # Schedule retry with exponential backoff
          delay = Enum.at(@retry_delays, attempt_number - 1, 300_000)

          %{delivery_log_id: delivery_log.id}
          |> __MODULE__.new(schedule_in: delay)
          |> Oban.insert!()

          WebhookNotifications.update_delivery_log(delivery_log, %{
            status: "pending",
            attempt_number: attempt_number + 1
          })

          {:snooze, delay}
        else
          WebhookNotifications.mark_delivery_failure(delivery_log, status_code, response_body, attempt_number)
          {:cancel, "Max retry attempts reached"}
        end
    end
  end
end
