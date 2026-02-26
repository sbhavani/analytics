defmodule PlausibleWeb.Webhooks.DeliverWebhook do
  @moduledoc """
  Oban job for delivering webhook notifications
  """
  use Plausible
  use Plausible.Repo
  use Oban.Worker, queue: :webhook_notifications
  require Logger

  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery

  @timeout 30_000

  @impl Oban.Worker
  def perform(%Job{args: %{"delivery_id" => delivery_id}}) do
    delivery = Repo.get!(Delivery, delivery_id)
    webhook = Repo.preload(delivery, :webhook)

    Logger.info("Starting webhook delivery",
      delivery_id: delivery_id,
      webhook_id: webhook.id,
      site_id: webhook.site_id,
      event_type: delivery.event_type,
      url: webhook.url
    )

    deliver(webhook, delivery)
  end

  defp deliver(%Webhook{} = webhook, %Delivery{} = delivery) do
    payload = build_payload(delivery)

    headers = [
      {"content-type", "application/json"},
      {"x-webhook-event", delivery.event_type},
      {"x-webhook-site-id", webhook.site_id},
      {"user-agent", "Plausible-Analytics-Webhook/1.0"}
    ]

    case Plausible.HTTPClient.post(webhook.url, headers, payload, timeout: @timeout) do
      {:ok, %{status: status}} when status >= 200 and status < 300 ->
        delivery
        |> Delivery.mark_as_success(status, nil)
        |> Repo.update()

        Logger.info("Webhook delivered successfully",
          delivery_id: delivery.id,
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          event_type: delivery.event_type,
          response_code: status
        )

        :ok

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body)
        delivery
        |> Delivery.mark_as_failed(status, error_message)
        |> Repo.update()

        Logger.warning("Webhook delivery failed with non-2xx status",
          delivery_id: delivery.id,
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          event_type: delivery.event_type,
          response_code: status,
          error_message: error_message
        )

        :ok

      {:error, %Plausible.HTTPClient.Non200Error{reason: %{status: status, body: body}}} ->
        error_message = extract_error_message(body)
        delivery
        |> Delivery.mark_as_failed(status, error_message)
        |> Repo.update()

        Logger.warning("Webhook delivery failed - non-200 error",
          delivery_id: delivery.id,
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          event_type: delivery.event_type,
          response_code: status,
          error_message: error_message
        )

        :ok

      {:error, reason} when is_atom(reason) or is_exception(reason) ->
        error_message = format_error(reason)
        delivery
        |> Delivery.mark_as_failed(nil, error_message)
        |> Repo.update()

        Logger.error("Webhook delivery failed with error",
          delivery_id: delivery.id,
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          event_type: delivery.event_type,
          error: error_message
        )

        :ok
    end
  end

  defp build_payload(%Delivery{payload: payload}) do
    payload
  end

  defp extract_error_message(body) when is_map(body) do
    case Jason.encode(body) do
      {:ok, json} -> json
      _ -> inspect(body)
    end
  end

  defp extract_error_message(_), do: "Unknown error"

  defp format_error(reason) when is_atom(reason) do
    Atom.to_string(reason)
  end

  defp format_error(reason) when is_exception(reason) do
    Exception.message(reason)
  end

  defp format_error(reason) do
    inspect(reason)
  end
end
