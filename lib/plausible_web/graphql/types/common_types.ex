defmodule PlausibleWeb.GraphQL.Types.CommonTypes do
  @moduledoc """
  Common GraphQL types used across the Analytics API.
  """

  use Absinthe.Schema.Notation

  # Import aggregation_type from InputTypes to avoid duplication
  import_types(PlausibleWeb.GraphQL.Types.InputTypes)

  @desc "Pagination metadata"
  object :page_info do
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
    field :start_cursor, :string
    field :end_cursor, :string
  end

  @desc "Aggregation result"
  object :aggregate_result do
    field :aggregation_type, non_null(:aggregation_type)
    field :value, non_null(:float)
    field :dimension, :string
  end
end
