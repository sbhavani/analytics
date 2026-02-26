defmodule PlausibleWeb.GraphQL.Types.Metric do
  use Absinthe.Schema.Notation
  use Plausible
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "Metric type"
  node object :metric do
    field(:name, :string)
    field(:value, :float)
    field(:aggregation_type, :string)
    field(:period, :string)
    field(:timestamp, :datetime)
    field(:dimensions, :json)
  end

  @desc "Metric filter input"
  input_object :metric_filter do
    field(:date_range, non_null(:date_range_input))
    field(:metric_name, :string)
    field(:dimensions, list_of(:string))
  end

  @desc "Metric connection"
  connection(:node_type, :metric)
end
