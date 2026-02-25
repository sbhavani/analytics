defmodule PlausibleWeb.GraphQL.Types.MetricDataPoint do
  @moduledoc """
  GraphQL type for metric data points (used in time-series data).
  """

  use Absinthe.Schema.Notation

  object :metric_data_point do
    @desc "The timestamp of the data point"
    field :timestamp, non_null(:date_time)

    @desc "The metric value at this timestamp"
    field :value, non_null(:float)
  end
end
