defmodule Plausible.Webhooks.Integration do
  @moduledoc """
  This module provides integration points for triggering webhooks.
  Call these functions when events occur in the system.
  """
  alias Plausible.Webhooks.WebhookNotifier

  @doc """
  Called when a goal is completed.
  """
  def deliver_goal_completed(site, goal, visitor_id, count \\ 1, revenue \\ nil) do
    webhooks = Plausible.Webhooks.get_webhooks_for_trigger(site.id, "goal.completed")

    for webhook <- webhooks do
      payload = WebhookNotifier.build_goal_payload(site, goal, visitor_id, count, revenue)
      Task.start(fn -> WebhookNotifier.deliver(webhook, "goal.completed", payload) end)
    end

    :ok
  end

  @doc """
  Called when visitor count exceeds threshold.
  """
  def deliver_visitor_spike(site, current_visitors, threshold, increase_percentage, window_minutes) do
    webhooks = Plausible.Webhooks.get_webhooks_for_trigger(site.id, "visitor.spike")

    for webhook <- webhooks do
      payload = WebhookNotifier.build_visitor_spike_payload(
        current_visitors,
        threshold,
        increase_percentage,
        window_minutes
      )
      Task.start(fn -> WebhookNotifier.deliver(webhook, "visitor.spike", payload) end)
    end

    :ok
  end
end
