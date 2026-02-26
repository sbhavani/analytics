defmodule Plausible.Webhooks.Payload do
  @moduledoc """
  Module for building webhook payloads
  """

  @spec build_visitor_spike_payload(Plausible.Site.t(), map()) :: map()
  def build_visitor_spike_payload(site, data) do
    %{
      event_type: "visitor_spike",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        visitor_count: Map.get(data, :visitor_count, 0),
        threshold: Map.get(data, :threshold, 0),
        period_start: Map.get(data, :period_start),
        period_end: Map.get(data, :period_end),
        change_percentage: Map.get(data, :change_percentage, 0.0)
      }
    }
  end

  @spec build_goal_completion_payload(Plausible.Site.t(), map()) :: map()
  def build_goal_completion_payload(site, data) do
    %{
      event_type: "goal_completion",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        goal_id: Map.get(data, :goal_id),
        goal_name: Map.get(data, :goal_name),
        visitor_id: Map.get(data, :visitor_id),
        path: Map.get(data, :path),
        revenue: Map.get(data, :revenue)
      }
    }
  end

  @spec build_test_payload(Plausible.Site.t()) :: map()
  def build_test_payload(site) do
    %{
      event_type: "test",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        message: "This is a test webhook from Plausible Analytics"
      }
    }
  end
end
