defmodule Plausible.GraphQL.Types.MetricFilterInput do
  @moduledoc """
  Input type for filtering custom metrics
  """
  use Absinthe.Schema.Notation

  input_object :metric_filter_input do
    non_null(:string)
    field :metric_name, non_null(:string)
  end
end
