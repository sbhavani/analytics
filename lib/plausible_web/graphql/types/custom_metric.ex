defmodule PlausibleWeb.GraphQL.Types.CustomMetric do
  @moduledoc """
  GraphQL types for custom metrics data.
  """

  use Absinthe.Schema.Notation

  @desc "Custom metric"
  object :custom_metric do
    field :id, :id, description: "Unique identifier"
    field :name, :string, description: "Name of the custom metric"
    field :display_name, :string, description: "Display label"
    field :value, :float, description: "Current value"
    field :unit, :string, description: "Metric unit (e.g., 'seconds', 'currency', 'percentage')"
    field :category, :string, description: "Category for grouping"
  end

  @desc "Custom metric time series data point"
  object :custom_metric_time_series do
    field :timestamp, :string, description: "Timestamp of the data point"
    field :value, :float, description: "Metric value at this timestamp"
  end
end
