defmodule Plausible.Graphqla.Types.EventTypes do
  @moduledoc """
  GraphQL types for event-related queries and filters
  """
  use Absinthe.Schema.Notation

  # Event filter input
  input_object :event_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :event_type, :string
  end

  # Event object type
  object :event do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :name, non_null(:string)
    field :properties, :json
    field :browser, :string
    field :device, :string
    field :country, :string
  end
end
