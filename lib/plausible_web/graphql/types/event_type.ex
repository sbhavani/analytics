defmodule PlausibleWeb.GraphQL.Types.EventType do
  @moduledoc """
  GraphQL types for event-related data.
  """

  use Absinthe.Schema.Notation

  @desc "Represents a custom event with aggregated data"
  object :event_result do
    field :name, non_null(:string), description: "The name of the event"
    field :count, non_null(:integer), description: "Number of times the event occurred"
    field :properties, :json, description: "Event properties as JSON"
    field :timestamp, :date_time, description: "Timestamp of the event"
  end
end
