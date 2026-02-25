defmodule Plausible.GraphQL.Types.AggregationInput do
  @moduledoc """
  Input type for aggregation functions
  """
  use Absinthe.Schema.Notation

  enum :aggregation_function do
    value(:sum, description: "Sum of all values")
    value(:count, description: "Count of records")
    value(:avg, description: "Average of all values")
    value(:min, description: "Minimum value")
    value(:max, description: "Maximum value")
  end

  enum :granularity do
    value(:hour, description: "Hourly aggregation")
    value(:day, description: "Daily aggregation")
    value(:week, description: "Weekly aggregation")
    value(:month, description: "Monthly aggregation")
  end

  input_object :aggregation_input do
    non_null(:aggregation_function)
    field :function, non_null(:aggregation_function)

    field :granularity, :granularity
  end
end
