defmodule Plausible.Webhooks.Trigger do
  @moduledoc """
  Module for triggering webhook notifications when events occur
  """
  use Plausible
  use Plausible.Repo
  require Logger
  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery
  alias Plausible.Webhooks.Payload
  alias PlausibleWeb.Webhooks.DeliverWebhook

  @doc """
  Trigger webhooks when a goal is completed
  """
  def trigger_goal_completion(site, goal, event_data) do
    webhooks = Webhooks.get_enabled_webhooks_for_event(site, "goal_completion")

    Logger.info("Goal completion event - checking webhooks",
      site_id: site.id,
      goal_id: goal.id,
      goal_name: goal.display_name,
      webhook_count: length(webhooks)
    )

    payload_data = %{
      goal_id: goal.id,
      goal_name: goal.display_name,
      visitor_id: Map.get(event_data, :visitor_id),
      path: Map.get(event_data, :path),
      revenue: Map.get(event_data, :revenue)
    }

    for webhook <- webhooks do
      trigger_webhook(webhook, site, "goal_completion", payload_data)
    end
  end

  @doc """
  Trigger webhooks when a visitor spike is detected
  """
  def trigger_visitor_spike(site, spike_data) do
    webhooks = Webhooks.get_enabled_webhooks_for_event(site, "visitor_spike")

    Logger.info("Visitor spike event - checking webhooks",
      site_id: site.id,
      visitor_count: Map.get(spike_data, :visitor_count),
      threshold: Map.get(spike_data, :threshold),
      webhook_count: length(webhooks)
    )

    for webhook <- webhooks do
      trigger_webhook(webhook, site, "visitor_spike", spike_data)
    end
  end

  defp trigger_webhook(webhook, site, event_type, event_data) do
    payload = build_payload(site, event_type, event_data)

    case Webhooks.create_delivery(webhook, %{
           event_type: event_type,
           payload: payload
         }) do
      {:ok, delivery} ->
        DeliverWebhook.enqueue(delivery.id)

        Logger.info("Webhook triggered and queued for delivery",
          webhook_id: webhook.id,
          site_id: site.id,
          delivery_id: delivery.id,
          event_type: event_type,
          url: webhook.url
        )

        :ok

      {:error, changeset} ->
        Logger.error("Failed to create webhook delivery",
          webhook_id: webhook.id,
          site_id: site.id,
          event_type: event_type,
          errors: inspect(changeset.errors)
        )

        {:error, :failed_to_create_delivery}
    end
  end

  defp build_payload(site, "goal_completion", data) do
    Payload.build_goal_completion_payload(site, data)
  end

  defp build_payload(site, "visitor_spike", data) do
    Payload.build_visitor_spike_payload(site, data)
  end

  defp build_payload(_site, _event_type, _data) do
    %{}
  end
end
