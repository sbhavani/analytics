defmodule Plausible.Webhooks.TriggerEvaluator do
  @moduledoc """
  Evaluates triggers and fires webhooks.
  """
  require Logger

  alias Plausible.Webhooks
  alias Plausible.Webhooks.Trigger
  alias Plausible.Webhooks.Triggers.VisitorSpike
  alias Plausible.Webhooks.Triggers.GoalCompletion

  @doc """
  Evaluates all active triggers for a site and fires webhooks if conditions are met.

  This function is called periodically (e.g., every minute) to check for trigger conditions.
  """
  def evaluate_site(site) do
    Logger.debug("Evaluating webhooks for site",
      site_id: site.id,
      domain: site.domain
    )

    webhooks = Webhooks.list_webhooks_for_site(site.id)
    active_webhooks = Enum.filter(webhooks, & &1.active)

    Logger.debug("Found webhooks for site",
      site_id: site.id,
      total_webhooks: length(webhooks),
      active_webhooks: length(active_webhooks)
    )

    Enum.each(active_webhooks, fn webhook ->
      evaluate_webhook_triggers(webhook)
    end)
  end

  defp evaluate_webhook_triggers(webhook) do
    triggers = webhook.triggers

    Enum.each(triggers, fn trigger ->
      case trigger.type do
        "visitor_spike" ->
          evaluate_visitor_spike(webhook, trigger)

        "goal_completion" ->
          evaluate_goal_completion(webhook, trigger)

        _ ->
          # Unknown trigger type, skip
          nil
      end
    end)
  end

  defp evaluate_visitor_spike(webhook, trigger) do
    case VisitorSpike.evaluate(webhook.site, trigger.threshold) do
      {:ok, nil} ->
        # No spike detected
        Logger.debug("Visitor spike trigger - no spike detected",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          threshold: trigger.threshold
        )
        :skip

      {:ok, event_data} ->
        Logger.info("Visitor spike trigger - condition met",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          threshold: trigger.threshold,
          visitors: event_data[:visitors]
        )
        # Trigger spike detected - fire webhook
        fire_webhook(webhook, :visitor_spike, event_data)

      {:error, reason} ->
        Logger.warning("Visitor spike trigger evaluation failed",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          error: inspect(reason)
        )
        {:error, reason}
    end
  end

  defp evaluate_goal_completion(webhook, trigger) do
    case GoalCompletion.evaluate(webhook.site, trigger.goal_id) do
      {:ok, nil} ->
        # No goals completed
        Logger.debug("Goal completion trigger - no goals completed",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          goal_id: trigger.goal_id
        )
        :skip

      {:ok, event_data} ->
        Logger.info("Goal completion trigger - condition met",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          goal_id: trigger.goal_id,
          completions: event_data[:completions]
        )
        # Goals completed - fire webhook
        fire_webhook(webhook, :goal_completion, event_data)

      {:error, reason} ->
        Logger.warning("Goal completion trigger evaluation failed",
          webhook_id: webhook.id,
          trigger_id: trigger.id,
          goal_id: trigger.goal_id,
          error: inspect(reason)
        )
        {:error, reason}
    end
  end

  defp fire_webhook(webhook, trigger_type, event_data) do
    # Check for deduplication - skip if we already sent this event recently
    event_id = event_data[:event_id]

    if event_id && Webhooks.delivery_exists?(webhook.id, event_id) do
      Logger.debug("Webhook delivery skipped - duplicate event",
        webhook_id: webhook.id,
        event_id: event_id
      )
      :skip
    else
      # Create delivery record
      {:ok, delivery} = Webhooks.create_delivery(%{
        webhook_id: webhook.id,
        event_id: event_id || UUID.uuid4(),
        url: webhook.url,
        status: "pending",
        attempt: 1,
        payload: Plausible.Webhooks.PayloadBuilder.build(trigger_type, event_data),
        trigger_type: to_string(trigger_type),
        event_data: event_data
      })

      Logger.info("Webhook trigger fired - delivery queued",
        webhook_id: webhook.id,
        site_id: webhook.site_id,
        delivery_id: delivery.id,
        trigger_type: trigger_type,
        event_id: delivery.event_id
      )

      # Queue the delivery job
      %{delivery_id: delivery.id}
      |> Plausible.Workers.DeliverWebhook.new()
      |> Oban.insert()

      {:ok, delivery}
    end
  end
end
