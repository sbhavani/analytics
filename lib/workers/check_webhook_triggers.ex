defmodule Plausible.Workers.CheckWebhookTriggers do
  @moduledoc """
  Oban worker for checking webhook trigger conditions.
  Runs periodically to check if visitor spikes or goal completions meet trigger criteria.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Stats.Clickhouse
  alias Plausible.Site

  use Oban.Worker, queue: :webhook_triggers

  @impl Oban.Worker
  def perform(_job) do
    check_visitor_spike_triggers()
    check_goal_completion_triggers()

    :ok
  end

  defp check_visitor_spike_triggers do
    # Get all enabled visitor_spike triggers
    triggers =
      Repo.all(
        from t in Site.WebhookTrigger,
          where: t.trigger_type == "visitor_spike" and t.enabled == true,
          inner_join: w in assoc(t, :webhook),
          where: w.enabled == true,
          preload: [webhook: w]
      )

    for trigger <- triggers do
      current_visitors = Clickhouse.current_visitors(trigger.webhook.site)

      if current_visitors >= trigger.threshold do
        fire_webhook_trigger(trigger, %{
          current_visitors: current_visitors,
          threshold: trigger.threshold
        })
      end
    end
  end

  defp check_goal_completion_triggers do
    # Get all enabled goal_completion triggers
    triggers =
      Repo.all(
        from t in Site.WebhookTrigger,
          where: t.trigger_type == "goal_completion" and t.enabled == true,
          inner_join: w in assoc(t, :webhook),
          where: w.enabled == true,
          preload: [:webhook, :goal]
      )

    for trigger <- triggers do
      # Check for recent goal completions
      # This is a simplified check - in production you'd want to track what was already notified
      recent_count = get_recent_goal_count(trigger.webhook.site, trigger.goal_id)

      if recent_count > 0 do
        fire_webhook_trigger(trigger, %{
          goal_id: trigger.goal_id,
          goal_name: trigger.goal.name,
          count: recent_count
        })
      end
    end
  end

  defp fire_webhook_trigger(trigger, event_data) do
    site = trigger.webhook.site

    payload = %{
      event_type: trigger.trigger_type,
      site_id: site.id,
      site_domain: site.domain,
      timestamp: NaiveDateTime.utc_now() |> DateTime.from_naive!("UTC") |> DateTime.to_iso8601(),
      data: event_data
    }

    # Queue the delivery job
    %{  webhook_id: trigger.webhook.id,
      trigger_id: trigger.id,
      event_type: trigger.trigger_type,
      payload: payload
    }
    |> Plausible.Workers.DeliverWebhook.new()
    |> Oban.insert!()
  end

  defp get_recent_goal_count(site, goal_id) do
    # Query ClickHouse for goal completions in the last minute
    # This is a placeholder - actual implementation would query the events table
    # For now, we'll return 0 as a conservative default
    # In production, you'd query clickhouse for the count
    0
  end
end
