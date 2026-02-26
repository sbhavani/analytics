defmodule Plausible.Graphqla.Types.CustomMetricTypes do
  @moduledoc """
  GraphQL types for custom metric-related queries and filters
  """
  use Absinthe.Schema.Notation

  # Custom metric filter input
  input_object :custom_metric_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :metric_name, :string
  end

  # Custom metric object type
  object :custom_metric do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :name, non_null(:string)
    field :value, non_null(:float)
    field :site_id, non_null(:id)
  end
end
