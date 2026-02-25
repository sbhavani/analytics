defmodule Plausible.GraphQL.Types.EventFilterInput do
  @moduledoc """
  Input type for filtering events
  """
  use Absinthe.Schema.Notation

  input_object :event_filter_input do
    field :event_name, :string
    field :properties, :json
    field :url_pattern, :string
  end
end
