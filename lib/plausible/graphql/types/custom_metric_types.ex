defmodule Plausible.GraphQL.Types.CustomMetricTypes do
  @moduledoc """
  GraphQL types for custom metric data.
  """

  use Absinthe.Schema.Notation

  @desc "A custom metric represents a user-defined business metric"
  object :custom_metric do
    field :name, :string, description: "Metric identifier"
    field :value, :float, description: "Metric value"
    field :timestamp, :datetime, description: "When the metric was recorded"
    field :dimensions, :string, description: "Additional grouping dimensions"
  end

  @desc "Input filter for custom metric queries"
  input_object :metric_filter_input do
    field :name, :string, description: "Metric name to filter by"
  end
end
