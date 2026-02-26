defmodule Plausible.Graphqla.Types.AggregationTypes do
  @moduledoc """
  GraphQL types for aggregation results and time granularity
  """
  use Absinthe.Schema.Notation

  # Time granularity enum
  enum :time_granularity do
    value :hour
    value :day
    value :week
    value :month
  end

  # Aggregation result object
  object :aggregation_result do
    field :key, :string
    field :count, :integer
    field :sum, :float
    field :average, :float
  end
end
