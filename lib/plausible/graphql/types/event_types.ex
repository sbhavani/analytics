defmodule Plausible.GraphQL.Types.EventTypes do
  @moduledoc """
  GraphQL types for event data.
  """

  use Absinthe.Schema.Notation

  @desc "An event represents a tracked user interaction"
  object :event do
    field :name, :string, description: "Event type (e.g., signup, click)"
    field :timestamp, :datetime, description: "When the event occurred"
    field :properties, :string, description: "Custom event properties"
    field :visitor_id, :string, description: "Anonymous visitor identifier"
  end

  @desc "Input filter for event queries"
  input_object :event_filter_input do
    field :name, :string, description: "Event name to filter by"
    field :name_pattern, :string, description: "Event name pattern to match (supports wildcards)"
    field :goal_id, :id, description: "Goal ID to filter events by"
    field :visitor_id, :string, description: "Visitor ID to filter events by"
    field :properties, :string, description: "Custom properties to filter by"
  end
end
