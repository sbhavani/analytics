defmodule Plausible.GraphQL.Types.EventResult do
  @moduledoc """
  Type for event query results
  """
  use Absinthe.Schema.Notation

  object :event_result do
    field :data, list_of(:event)
    field :pagination, :pagination_info
    field :total, :integer
  end
end
