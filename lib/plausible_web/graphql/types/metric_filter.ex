defmodule PlausibleWeb.GraphQL.Types.MetricFilter do
  use Absinthe.Schema.Notation

  @desc "Metric filter input"
  input_object :metric_filter do
    field(:date_range, :date_range_input)
    field(:metric_name, :string)
    field(:dimensions, list_of(:string))
  end
end
