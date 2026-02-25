defmodule Plausible.GraphQL.Types.Aggregation do
  @moduledoc """
  GraphQL input type for aggregation
  """
  use Absinthe.Schema.Notation

  enum :aggregation_type do
    value :sum
    value :avg
    value :count
    value :min
    value :max
  end

  input_object :aggregation_input do
    field :type, :aggregation_type
    field :metric, :string
  end
end
