defmodule PlausibleWeb.GraphQL.Types.Metric do
  @moduledoc """
  GraphQL types for custom metrics.
  """

  use Absinthe.Schema.Notation

  @desc "A custom metric"
  object :custom_metric do
    field :name, non_null(:string)
    field :value, non_null(:float)
    field :previous_value, :float
    field :change, :float
    field :historical_values, list_of(:metric_data_point)
  end

  @desc "A single metric data point for historical values"
  object :metric_data_point do
    field :timestamp, :datetime
    field :value, non_null(:float)
  end
end
