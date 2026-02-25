defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook HTTP POST requests.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Site.WebhookDelivery
  alias Plausible.Webhook

  use Oban.Worker, queue: :webhooks, max_attempts: 3

  @http_timeout 30_000
  @max_redirects 3

  @impl Oban.Worker
  def perform(%{args: %{"delivery_id" => delivery_id}}, _opts \\ nil) do
    delivery = Repo.get(WebhookDelivery, delivery_id) |> Repo.preload(:webhook)

    if delivery && delivery.webhook.enabled do
      deliver_webhook(delivery)
    else
      :ok
    end
  end

  defp deliver_webhook(delivery) do
    payload_json = Jason.encode!(delivery.payload)
    signature = Webhook.generate_signature(delivery.webhook.secret, delivery.payload)

    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Signature", "sha256=#{signature}"},
      {"X-Webhook-Event", delivery.trigger_type},
      {"User-Agent", "Plausible-Analytics-Webhook/1.0"}
    ]

    case make_request(delivery.webhook.url, payload_json, headers) do
      {:ok, status_code, response_body} ->
        handle_success(delivery, status_code, response_body)

      {:error, reason} ->
        handle_failure(delivery, reason)
    end
  end

  defp make_request(url, body, headers) do
    case Req.request(
           method: :post,
           url: url,
           body: body,
           headers: headers,
           receive_timeout: @http_timeout,
           max_redirects: @max_redirects
         ) do
      {:ok, %{status: status, body: body}} ->
        {:ok, status, truncate_response(body)}

      {:error, %{reason: reason}} ->
        {:error, inspect(reason)}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp handle_success(delivery, status_code, response_body) do
    if status_code >= 200 and status_code < 300 do
      delivery
      |> WebhookDelivery.mark_success(status_code, response_body)
      |> Repo.update!()

      {:ok, :delivered}
    else
      handle_failure(delivery, "HTTP #{status_code}")
    end
  end

  defp handle_failure(delivery, reason) do
    updated = delivery |> WebhookDelivery.increment_attempt() |> Repo.update!()

    if updated.attempts < Webhook.max_retry_attempts() do
      delay = Webhook.get_retry_delay(updated.attempts)
      next_retry = NaiveDateTime.add(NaiveDateTime.utc_now(), delay, :second)

      updated
      |> WebhookDelivery.schedule_retry(next_retry)
      |> Repo.update!()

      {:retry, delay}
    else
      updated
      |> WebhookDelivery.mark_exhausted()
      |> Repo.update!()

      {:error, :exhausted}
    end
  end

  defp truncate_response(body) when is_binary(body) do
    if String.length(body) > 1000 do
      String.slice(body, 0, 1000) <> "..."
    else
      body
    end
  end

  defp truncate_response(body), do: inspect(body)
end
