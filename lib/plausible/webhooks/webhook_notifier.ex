defmodule Plausible.Webhooks.WebhookNotifier do
  @moduledoc """
  Service for delivering webhook notifications
  """
  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.WebhookDelivery

  require Logger

  @max_retries 3
  @retry_delays [60_000, 300_000, 1_800_000] # 1min, 5min, 30min

  def deliver(webhook, event_type, event_data) do
    payload = build_payload(webhook, event_type, event_data)

    case Webhooks.create_delivery(webhook, event_type, payload) do
      {:ok, delivery} ->
        deliver_with_retry(delivery, webhook)

      error ->
        Logger.error("Failed to create webhook delivery", error: inspect(error))
        error
    end
  end

  def deliver_test(webhook) do
    payload = build_test_payload(webhook)

    case Webhooks.create_delivery(webhook, "webhook.test", payload) do
      {:ok, delivery} ->
        deliver_with_retry(delivery, webhook)

      error ->
        Logger.error("Failed to create test webhook delivery", error: inspect(error))
        error
    end
  end

  defp deliver_with_retry(delivery, webhook) do
    case make_request(delivery, webhook) do
      {:ok, response_code} when response_code >= 200 and response_code < 300 ->
        Webhooks.update_delivery_status(delivery, :delivered, response_code)
        Logger.info("Webhook delivered successfully", webhook_id: webhook.id, delivery_id: delivery.id)

      {:ok, response_code} when response_code == 429 ->
        handle_retry(delivery, webhook, :rate_limited)

      {:ok, response_code} when response_code >= 500 ->
        handle_retry(delivery, webhook, :server_error)

      {:ok, response_code} ->
        Webhooks.update_delivery_status(delivery, :failed, response_code)
        Logger.warning("Webhook delivery failed", webhook_id: webhook.id, delivery_id: delivery.id, response_code: response_code)

      {:error, reason} ->
        handle_retry(delivery, webhook, reason)
    end
  end

  defp handle_retry(delivery, webhook, reason) do
    if delivery.retry_count < @max_retries do
      schedule_retry(delivery, webhook)
      {:retrying, delivery.retry_count + 1}
    else
      Webhooks.update_delivery_status(delivery, :failed, nil, "Max retries exceeded: #{reason}")
      Logger.error("Webhook delivery failed after max retries", webhook_id: webhook.id, delivery_id: delivery.id)
      {:failed, :max_retries_exceeded}
    end
  end

  defp schedule_retry(delivery, webhook) do
    delay = Enum.at(@retry_delays, delivery.retry_count, 1_800_000)

    Webhooks.increment_retry_count(delivery)
    Webhooks.update_delivery_status(delivery, :retrying)

    # In production, use Oban or similar for delayed jobs
    # For now, we'll just log and let it be picked up by a worker
    Logger.info("Scheduling webhook retry", webhook_id: webhook.id, delivery_id: delivery.id, delay_ms: delay)

    Task.start(fn ->
      Process.sleep(delay)
      deliver_with_retry(Webhooks.Repo.reload!(delivery), webhook)
    end)
  end

  defp make_request(delivery, webhook) do
    payload_json = Jason.encode!(delivery.payload)
    signature = generate_signature(payload_json, webhook.secret)
    timestamp = System.system_time(:second)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Plausible-Signature", signature},
      {"X-Plausible-Event", delivery.event_type},
      {"X-Plausible-Timestamp", "#{timestamp}"}
    ]

    case Req.post(webhook.url, body: payload_json, headers: headers, timeout: 30_000) do
      {:ok, %{status: status}} ->
        {:ok, status}

      {:error, reason} ->
        Logger.error("Webhook request failed", reason: inspect(reason))
        {:error, reason}
    end
  end

  def generate_signature(payload, secret) do
    :crypto.mac(:hmac, :sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  def build_payload(webhook, "goal.completed", data) do
    %{
      event: "goal.completed",
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        goal_id: data.goal_id,
        goal_name: data.goal_name,
        visitor_id: data.visitor_id,
        count: data.count || 1,
        revenue: data.revenue
      }
    }
  end

  def build_payload(webhook, "visitor.spike", data) do
    %{
      event: "visitor.spike",
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        current_visitors: data.current_visitors,
        threshold: data.threshold,
        increase_percentage: data.increase_percentage,
        window_minutes: data.window_minutes
      }
    }
  end

  def build_payload(webhook, event_type, data) do
    %{
      event: event_type,
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: data
    }
  end

  def build_test_payload(webhook) do
    %{
      event: "webhook.test",
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        message: "This is a test webhook from Plausible Analytics"
      }
    }
  end

  def build_goal_payload(site, goal, visitor_id, count \\ 1, revenue \\ nil) do
    %{
      goal_id: goal.id,
      goal_name: goal.name,
      visitor_id: visitor_id,
      count: count,
      revenue: revenue
    }
  end

  def build_visitor_spike_payload(current_visitors, threshold, increase_percentage, window_minutes) do
    %{
      current_visitors: current_visitors,
      threshold: threshold,
      increase_percentage: increase_percentage,
      window_minutes: window_minutes
    }
  end
end
