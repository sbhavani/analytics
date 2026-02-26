defmodule PlausibleWeb.GraphQL.Types.Event do
  @moduledoc """
  GraphQL types for event data.
  """

  use Absinthe.Schema.Notation

  @desc "Event aggregate data"
  object :event_aggregate do
    field :count, :integer, description: "Total count of events"
    field :visitors, :integer, description: "Unique visitors who triggered events"
    field :event_name, :string, description: "Event name"
    field :group, :string, description: "Group value (if grouped by dimension)"
  end
end
