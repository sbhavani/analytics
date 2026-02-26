defmodule PlausibleWeb.GraphQL.Types.CustomMetricTypes do
  @moduledoc """
  GraphQL types for custom metric data.
  """

  use Absinthe.Schema.Notation

  @desc "A single custom metric"
  object :custom_metric do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :value, non_null(:float)
    field :timestamp, non_null(:datetime)
    field :site_id, non_null(:id)
    field :dimensions, :json
  end

  @desc "Edge in the custom metric connection"
  object :custom_metric_edge do
    field :node, non_null(:custom_metric)
    field :cursor, non_null(:string)
  end

  @desc "Paginated list of custom metrics"
  object :custom_metric_connection do
    field :edges, non_null(list_of(non_null(:custom_metric_edge)))
    field :page_info, non_null(:page_info)
    field :total_count, non_null(:integer)
  end

  @desc "Result type for custom metric queries (connection or aggregation)"
  union :custom_metric_result do
    types [:custom_metric_connection, :aggregate_result]

    resolve_type fn
      %{aggregation_type: _}, _ ->
        :aggregate_result
      _, _ ->
        :custom_metric_connection
    end
  end
end
