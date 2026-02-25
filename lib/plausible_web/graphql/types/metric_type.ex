defmodule PlausibleWeb.GraphQL.Types.MetricType do
  @moduledoc """
  GraphQL types for custom metrics.
  """

  use Absinthe.Type.Notation

  @desc "A custom metric with its current value and optional historical data"
  object :custom_metric do
    field :name, non_null(:string), description: "The name of the metric"
    field :value, non_null(:float), description: "The current value of the metric"
    field :historical, list_of(:metric_data_point), description: "Historical data points for time-series metrics"
  end
end
