defmodule Plausible.GraphQL.Types.MetricResult do
  @moduledoc """
  Type for custom metric query results
  """
  use Absinthe.Schema.Notation

  object :metric_result do
    field :data, list_of(:custom_metric)
    field :pagination, :pagination_info
    field :aggregated, :float
  end
end
