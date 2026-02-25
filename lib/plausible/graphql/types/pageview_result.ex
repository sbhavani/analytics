defmodule Plausible.GraphQL.Types.PageviewResult do
  @moduledoc """
  Type for pageview query results
  """
  use Absinthe.Schema.Notation

  object :pageview_result do
    field :data, list_of(:pageview)
    field :pagination, :pagination_info
    field :total, :integer
  end
end
