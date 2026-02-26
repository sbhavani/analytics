defmodule Plausible.WebhookNotifications.TriggerEvaluator do
  @moduledoc """
  Evaluates event triggers and fires webhooks when conditions are met
  """
  alias Plausible.{Repo, WebhookNotifications}
  alias Plausible.Stats

  @doc """
  Evaluates all triggers for a site and fires webhooks if conditions are met
  """
  def evaluate_triggers(site, event_type, event_data) do
    webhooks = WebhookNotifications.list_webhooks(site)

    for webhook <- webhooks,
        webhook.is_active do
      triggers = WebhookNotifications.get_enabled_triggers(webhook)

      for trigger <- triggers do
        if should_fire?(trigger, event_type, event_data) do
          fire_webhook(webhook, trigger, event_type, event_data)
        end
      end
    end
  end

  @doc """
  Evaluates visitor spike triggers
  """
  def evaluate_visitor_spike(site, current_visitors, baseline_visitors) do
    webhooks = WebhookNotifications.list_webhooks(site)

    for webhook <- webhooks,
        webhook.is_active do
      triggers = WebhookNotifications.get_enabled_triggers(webhook)

      for trigger <- triggers,
          trigger.trigger_type == "visitor_spike" do
        threshold = trigger.threshold_value || 200
        increase_percentage = calculate_increase_percentage(current_visitors, baseline_visitors)

        if increase_percentage >= threshold do
          payload = %{
            event: "visitor_spike",
            site_id: site.id,
            timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
            data: %{
              current_visitors: current_visitors,
              baseline_visitors: baseline_visitors,
              increase_percentage: increase_percentage
            }
          }

          {:ok, log} = WebhookNotifications.create_delivery_log(webhook, "visitor_spike", payload)

          # Queue delivery worker
          %{delivery_log_id: log.id}
          |> Plausible.Workers.WebhookDeliveryWorker.new()
          |> Oban.insert!()
        end
      end
    end
  end

  @doc """
  Evaluates goal completion triggers
  """
  def evaluate_goal_completion(site, goal, count) do
    webhooks = WebhookNotifications.list_webhooks(site)

    for webhook <- webhooks,
        webhook.is_active do
      triggers = WebhookNotifications.get_enabled_triggers(webhook)

      for trigger <- triggers,
          trigger.trigger_type == "goal_completion" do
        payload = %{
          event: "goal_completion",
          site_id: site.id,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
          data: %{
            goal_name: goal.name,
            goal_id: goal.id,
            count: count,
            revenue: goal.revenue
          }
        }

        {:ok, log} = WebhookNotifications.create_delivery_log(webhook, "goal_completion", payload)

        # Queue delivery worker
        %{delivery_log_id: log.id}
        |> Plausible.Workers.WebhookDeliveryWorker.new()
        |> Oban.insert!()
      end
    end
  end

  defp should_fire?(trigger, event_type, _event_data) do
    trigger.trigger_type == event_type && trigger.is_enabled
  end

  defp fire_webhook(webhook, trigger, event_type, event_data) do
    payload = %{
      event: event_type,
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: event_data
    }

    {:ok, log} = WebhookNotifications.create_delivery_log(webhook, event_type, payload)

    # Queue delivery worker
    %{delivery_log_id: log.id}
    |> Plausible.Workers.WebhookDeliveryWorker.new()
    |> Oban.insert!()
  end

  defp calculate_increase_percentage(current, baseline) when baseline > 0 do
    ((current - baseline) / baseline) * 100
    |> Float.round(0)
    |> trunc()
  end

  defp calculate_increase_percentage(_current, _baseline) do
    0
  end
end
