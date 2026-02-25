defmodule Plausible.Webhooks.PayloadBuilder do
  @moduledoc """
  Builds webhook payloads for different trigger types.
  """

  @doc """
  Builds a webhook payload for the given trigger type and event data.

  ## Trigger Types
  - :visitor_spike - Notify when visitor count spikes
  - :goal_completion - Notify when a goal is completed

  ## Returns
  A map with the following structure:
  %{
    event_id: UUID.t(),
    event_type: String.t(),
    site_id: UUID.t(),
    site_domain: String.t(),
    timestamp: ISO8601 String.t(),
    data: Map.t()
  }
  """
  def build(:visitor_spike, event_data) do
    %{
      event_id: event_data[:event_id] || generate_uuid(),
      event_type: "visitor_spike",
      site_id: event_data[:site_id],
      site_domain: event_data[:site_domain],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        current_visitors: event_data[:current_visitors],
        previous_visitors: event_data[:previous_visitors],
        change_percent: event_data[:change_percent],
        threshold: event_data[:threshold]
      }
    }
  end

  def build(:goal_completion, event_data) do
    %{
      event_id: event_data[:event_id] || generate_uuid(),
      event_type: "goal_completion",
      site_id: event_data[:site_id],
      site_domain: event_data[:site_domain],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        goal_id: event_data[:goal_id],
        goal_name: event_data[:goal_name],
        count: event_data[:count] || 1
      }
    }
  end

  def build("visitor_spike", event_data), do: build(:visitor_spike, event_data)
  def build("goal_completion", event_data), do: build(:goal_completion, event_data)

  defp generate_uuid do
    UUID.uuid4()
  end
end
