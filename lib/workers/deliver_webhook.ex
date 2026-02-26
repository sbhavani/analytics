defmodule Plausible.Workers.DeliverWebhook do
  @moduledoc """
  Oban worker for delivering webhook payloads
  """
  use Plausible
  use Plausible.Repo
  use Oban.Worker, queue: :webhooks

  alias Plausible.Webhooks
  alias Plausible.Site.{Webhook, WebhookTrigger}
  alias Plausible.HTTPClient

  @max_retries 5
  @receive_timeout 30_000

  @impl Oban.Worker
  def perform(%Job{args: %{"webhook_id" => webhook_id, "trigger_id" => trigger_id, "payload" => payload}}) do
    webhook = Repo.get(Webhook, webhook_id) |> Repo.preload(:site)

    if webhook && webhook.enabled do
      trigger = Repo.get(WebhookTrigger, trigger_id)

      if trigger && trigger.enabled do
        deliver(webhook, trigger, payload)
      else
        :skip
      end
    else
      :skip
    end
  end

  defp deliver(webhook, trigger, payload) do
    headers = [
      {"content-type", "application/json"},
      {"user-agent", "Plausible-Webhook/1.0"},
      {"x-plausible-signature", signature(payload, webhook.secret)}
    ]

    payload_json = Jason.encode!(payload)

    case HTTPClient.post(webhook.url, headers, payload_json, receive_timeout: @receive_timeout) do
      {:ok, %{status: status}} when status >= 200 and status < 300 ->
        log_delivery(webhook.id, trigger.id, payload, {:ok, %{status: status}})
        :ok

      {:ok, %{status: status, body: body}} ->
        log_delivery(webhook.id, trigger.id, payload, {:error, %{status: status, body: body}})
        {:error, :http_error}

      {:error, error} ->
        log_delivery(webhook.id, trigger.id, payload, {:error, error})
        {:error, error}
    end
  end

  defp signature(payload, secret) when is_map(payload) do
    payload_json = Jason.encode!(payload)
    signature(payload_json, secret)
  end

  defp signature(payload_json, secret) do
    "sha256=#{:crypto.hmac(:sha256, secret, payload_json) |> Base.encode16()}"
  end

  defp log_delivery(webhook_id, trigger_id, payload, result) do
    attrs = %{
      webhook_id: webhook_id,
      trigger_id: trigger_id,
      payload: payload,
      attempt: 1,
      success: match?({:ok, _}, result)
    }

    attrs =
      case result do
        {:ok, %{status: status}} ->
          Map.merge(attrs, %{status_code: status})

        {:error, %{reason: %{status: status, body: body}}} ->
          Map.merge(attrs, %{
            status_code: status,
            response_body: body,
            error_message: "HTTP #{status}"
          })

        {:error, error} ->
          Map.merge(attrs, %{error_message: inspect(error)})
      end

    %Plausible.Site.WebhookDelivery{}
    |> Ecto.Changeset.change(attrs)
    |> Repo.insert!()
  end

  @impl Oban.Worker
  def backoff(%Job{attempt: attempt}) do
    # Exponential backoff: 30s, 2m, 10m, 1h
    case attempt do
      1 -> 30
      2 -> 120
      3 -> 600
      4 -> 3600
      _ -> 3600
    end
  end

  @impl Oban.Worker
  def timeout(%Job{}), do: @receive_timeout
end
