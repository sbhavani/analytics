defmodule Plausible.GraphQL.Types.EventData do
  @moduledoc """
  GraphQL type for event data
  """
  use Absinthe.Schema.Notation

  object :event_data do
    field :name, :string
    field :count, :integer
    field :unique_visitors, :integer
  end
end
