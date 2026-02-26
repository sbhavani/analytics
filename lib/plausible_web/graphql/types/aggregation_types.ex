defmodule PlausibleWeb.GraphQL.Types.AggregationTypes do
  @moduledoc """
  GraphQL types for aggregation functionality.

  This module defines types for count, sum, and average aggregations
  as specified in User Story 5.
  """

  use Absinthe.Schema.Notation

  alias PlausibleWeb.GraphQL.Types.CommonTypes

  @desc "Result of a count aggregation"
  object :count_aggregation do
    field :value, non_null(:integer), description: "The counted value"
    field :dimension, :string, description: "Optional dimension grouping"
  end

  @desc "Result of a sum aggregation"
  object :sum_aggregation do
    field :value, non_null(:float), description: "The summed value"
    field :field, :string, description: "The field that was summed"
    field :dimension, :string, description: "Optional dimension grouping"
  end

  @desc "Result of an average aggregation"
  object :average_aggregation do
    field :value, non_null(:float), description: "The averaged value"
    field :field, :string, description: "The field that was averaged"
    field :dimension, :string, description: "Optional dimension grouping"
  end

  @desc "Union of all aggregation result types"
  union :aggregation_result do
    types [:count_aggregation, :sum_aggregation, :average_aggregation, :aggregate_result]

    resolve_type fn
      %{aggregation_type: :count}, _ -> :count_aggregation
      %{aggregation_type: :sum}, _ -> :sum_aggregation
      %{aggregation_type: :average}, _ -> :average_aggregation
      %{value: value} when is_integer(value), _ -> :count_aggregation
      %{value: _}, _ -> :aggregate_result
      _, _ -> :aggregate_result
    end
  end

  @desc "Aggregation breakdown by dimension"
  object :aggregation_breakdown do
    field :dimension_value, non_null(:string), description: "The dimension value"
    field :aggregations, non_null(list_of(non_null(:aggregate_result))), description: "Aggregations for this dimension"
  end

  @desc "Time series aggregation result"
  object :time_series_aggregation do
    field :date, non_null(:date), description: "The date for this data point"
    field :values, non_null(:json), description: "Map of metric names to values"
  end
end
