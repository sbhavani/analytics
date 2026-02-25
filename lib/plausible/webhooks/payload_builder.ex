defmodule Plausible.Webhooks.PayloadBuilder do
  @moduledoc """
  Builds webhook payloads for different event types.
  """

  @spec build_goal_completion(map()) :: map()
  def build_goal_completion(%{
        site: site,
        goal: goal,
        visitor_count: visitor_count,
        path: path,
        referrer: referrer
      }) do
    %{
      event: "goal_completion",
      site_id: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        goal_id: goal.id,
        goal_name: goal.display_name || goal.event_name,
        goal_type: goal |> Plausible.Goal.type() |> Atom.to_string(),
        visitor_count: visitor_count,
        path: path,
        referrer: referrer || ""
      }
    }
  end

  @spec build_visitor_spike(map()) :: map()
  def build_visitor_spike(%{
        site: site,
        current_visitors: current_visitors,
        threshold: threshold,
        sources: sources,
        pages: pages
      }) do
    %{
      event: "visitor_spike",
      site_id: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        current_visitors: current_visitors,
        threshold: threshold,
        change_type: "spike",
        top_sources: Enum.take(sources, 3),
        top_pages: Enum.take(pages, 3)
      }
    }
  end

  @spec build_custom_event(map()) :: map()
  def build_custom_event(%{
        site: site,
        event_name: event_name,
        visitor_count: visitor_count,
        path: path,
        props: props
      }) do
    %{
      event: "custom_event",
      site_id: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        event_name: event_name,
        visitor_count: visitor_count,
        path: path || "",
        props: props || %{}
      }
    }
  end

  @spec build_error_condition(map()) :: map()
  def build_error_condition(%{
        site: site,
        error_type: error_type,
        message: message,
        details: details
      }) do
    %{
      event: "error_condition",
      site_id: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        error_type: error_type,
        message: message,
        details: details || %{}
      }
    }
  end

  @spec build_test(map()) :: map()
  def build_test(%{site: site}) do
    %{
      event: "test",
      site_id: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        message: "This is a test webhook from Plausible Analytics"
      }
    }
  end
end
