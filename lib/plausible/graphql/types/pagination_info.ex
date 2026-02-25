defmodule Plausible.GraphQL.Types.PaginationInfo do
  @moduledoc """
  Type for pagination metadata
  """
  use Absinthe.Schema.Notation

  object :pagination_info do
    field :limit, :integer
    field :offset, :integer
    field :has_more, :boolean
    field :total, :integer
  end
end
