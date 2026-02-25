defmodule Plausible.GraphQL.Types.PaginationInput do
  @moduledoc """
  Input type for pagination
  """
  use Absinthe.Schema.Notation

  input_object :pagination_input do
    field :limit, :integer
    field :offset, :integer
  end
end
