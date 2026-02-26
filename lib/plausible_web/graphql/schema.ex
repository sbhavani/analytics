defmodule PlausibleWeb.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for the Plausible Analytics API.

  This module defines the root query type for exposing analytics data
  including pageviews, events, and custom metrics.

  Query complexity analysis is implemented to prevent expensive queries.
  Each field has a complexity value based on its computational cost.
  """

  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers

  # Import types
  import_types(PlausibleWeb.GraphQL.Types.Pageview)
  import_types(PlausibleWeb.GraphQL.Types.Event)
  import_types(PlausibleWeb.GraphQL.Types.CustomMetric)
  import_types(PlausibleWeb.GraphQL.Types.Input)
  import_types(PlausibleWeb.GraphQL.Types.Enum)

  # Maximum allowed query complexity (prevent expensive queries)
  @max_complexity 1000

  # Query complexity analysis
  def complexity(query) do
    Absinthe.Schema.complexity(query, fn
      # List fields have higher complexity due to multiple result processing
      _, :pageviews, child_complexity ->
        10 + child_complexity

      _, :events, child_complexity ->
        10 + child_complexity

      _, :custom_metrics, child_complexity ->
        5 + child_complexity

      _, :custom_metrics_time_series, child_complexity ->
        20 + child_complexity

      # Default complexity for fields
      _, _, child_complexity ->
        1 + child_complexity
    end)
  end

  # Query root
  query do
    @desc "Query pageview data"
    field :pageviews, list_of(:pageview_aggregate) do
      arg :site_id, non_null(:string), description: "Site ID (domain)"
      arg :date_range, non_null(:date_range_input), description: "Date range for the query"
      arg :filters, :pageview_filters_input, description: "Optional filters"
      arg :aggregation, :aggregation_input, description: "Aggregation settings"

      complexity &__MODULE__.complexity/1
      resolve &Resolvers.Pageviews.pageviews/3
    end

    @desc "Query event data"
    field :events, list_of(:event_aggregate) do
      arg :site_id, non_null(:string), description: "Site ID (domain)"
      arg :date_range, non_null(:date_range_input), description: "Date range for the query"
      arg :filters, :event_filters_input, description: "Optional filters"
      arg :aggregation, :aggregation_input, description: "Aggregation settings"

      complexity &__MODULE__.complexity/1
      resolve &Resolvers.Events.events/3
    end

    @desc "Query custom metrics"
    field :custom_metrics, list_of(:custom_metric) do
      arg :site_id, non_null(:string), description: "Site ID (domain)"
      arg :date_range, :date_range_input, description: "Date range for the query"
      arg :name, :string, description: "Filter by metric name"
      arg :category, :string, description: "Filter by category"

      complexity &__MODULE__.complexity/1
      resolve &Resolvers.CustomMetrics.custom_metrics/3
    end

    @desc "Query custom metrics time series"
    field :custom_metrics_time_series, list_of(:custom_metric_time_series) do
      arg :site_id, non_null(:string), description: "Site ID (domain)"
      arg :metric_name, non_null(:string), description: "Name of the metric"
      arg :date_range, non_null(:date_range_input), description: "Date range for the query"
      arg :interval, non_null(:time_interval), description: "Time interval"

      complexity &__MODULE__.complexity/1
      resolve &Resolvers.CustomMetrics.custom_metrics_time_series/3
    end
  end

  # Object types are defined in separate modules
end
