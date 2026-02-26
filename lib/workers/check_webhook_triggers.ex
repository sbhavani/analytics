defmodule Plausible.Workers.CheckWebhookTriggers do
  @moduledoc """
  Oban worker for checking webhook trigger conditions
  """
  use Plausible
  use Plausible.Repo
  alias Plausible.Site
  alias Plausible.{Webhooks, Stats}
  alias Plausible.Workers.DeliverWebhook

  use Oban.Worker, queue: :webhooks
  @min_interval_hours 1

  @impl Oban.Worker
  def perform(_job, now \\ NaiveDateTime.utc_now(:second)) do
    today = NaiveDateTime.to_date(now)

    # Get all enabled triggers with their webhooks and sites
    triggers = Webhooks.list_all_enabled_triggers_with_preloads()

    for trigger <- triggers do
      if ok_to_check?(trigger.webhook.site) do
        check_trigger(trigger, now)
      end
    end

    :ok
  end

  defp check_trigger(trigger, now) do
    case trigger.trigger_type do
      :visitor_spike ->
        check_visitor_spike(trigger, now)

      :goal_completion ->
        check_goal_completion(trigger, now)
    end
  end

  defp check_visitor_spike(trigger, now) do
    # Check if enough time has passed since last delivery for this trigger
    if can_fire_trigger?(trigger) do
      current_visitors = Stats.Clickhouse.current_visitors(trigger.webhook.site)

      if current_visitors >= trigger.threshold do
        payload = Webhooks.build_spike_payload(trigger, trigger.webhook.site, current_visitors)
        enqueue_delivery(trigger, payload)
      end
    end
  end

  defp check_goal_completion(trigger, now) do
    # Check if enough time has passed since last delivery for this trigger
    if can_fire_trigger?(trigger) && trigger.goal do
      # Get goal completions in the last hour
      completions = get_goal_completions(trigger.webhook.site, trigger.goal_id)

      if completions > 0 do
        payload = Webhooks.build_goal_payload(trigger, trigger.webhook.site, completions)
        enqueue_delivery(trigger, payload)
      end
    end
  end

  defp get_goal_completions(site, goal_id) do
    query = Plausible.Stats.QueryBuilder.build!(site, %Plausible.Stats.ParsedQueryParams{
      metrics: [: conversions],
      filters: [[:is, "event:goal", [goal_id]]],
      input_date_range: :today
    })

    case Plausible.Stats.query(site, query) do
      %{results: [%{conversions: conversions}]} -> conversions
      _ -> 0
    end
  end

  defp can_fire_trigger?(trigger) do
    # Check last delivery - don't fire too frequently
    last_delivery =
      Repo.one(
        from d in Plausible.Site.WebhookDelivery,
          where: d.trigger_id == ^trigger.id,
          where: d.success == true,
          order_by: [desc: :inserted_at],
          limit: 1
      )

    case last_delivery do
      nil -> true
      delivery ->
        hours_since = NaiveDateTime.diff(NaiveDateTime.utc_now(), delivery.inserted_at, :hour)
        hours_since >= @min_interval_hours
    end
  end

  defp enqueue_delivery(trigger, payload) do
    %{webhook_id: trigger.webhook.id, trigger_id: trigger.id, payload: payload}
    |> DeliverWebhook.new()
    |> Oban.insert!()

    # Note: we don't update last_sent here since we log deliveries
    # The can_fire_trigger? function checks delivery history
  end

  on_ee do
    defp ok_to_check?(site) do
      Plausible.Sites.regular?(site) or
        (Plausible.Sites.consolidated?(site) and
           Plausible.ConsolidatedView.ok_to_display?(site.team))
    end
  else
    defp ok_to_check?(_site), do: true
  end
end
