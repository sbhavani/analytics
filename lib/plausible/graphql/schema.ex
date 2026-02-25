defmodule Plausible.GraphQL.Schema do
  @moduledoc """
  Main GraphQL schema for the Analytics API
  """
  use Absinthe.Schema

  alias Plausible.GraphQL.Resolvers.PageviewResolver
  alias Plausible.GraphQL.Resolvers.EventResolver
  alias Plausible.GraphQL.Resolvers.MetricResolver

  # Import types
  import_types(Plausible.GraphQL.Types.DateRangeInput)
  import_types(Plausible.GraphQL.Types.AggregationInput)
  import_types(Plausible.GraphQL.Types.PaginationInput)
  import_types(Plausible.GraphQL.Types.PageviewFilterInput)
  import_types(Plausible.GraphQL.Types.EventFilterInput)
  import_types(Plausible.GraphQL.Types.MetricFilterInput)
  import_types(Plausible.GraphQL.Types.PaginationInfo)
  import_types(Plausible.GraphQL.Types.Pageview)
  import_types(Plausible.GraphQL.Types.PageviewResult)
  import_types(Plausible.GraphQL.Types.Event)
  import_types(Plausible.GraphQL.Types.EventResult)
  import_types(Plausible.GraphQL.Types.CustomMetric)
  import_types(Plausible.GraphQL.Types.MetricResult)

  query do
    @desc "Get pageview analytics data"
    field :pageviews, :pageview_result do
      arg(:site_id, non_null(:string))
      arg(:date_range, non_null(:date_range_input))
      arg(:filters, :pageview_filter_input)
      arg(:aggregation, :aggregation_input)
      arg(:pagination, :pagination_input)

      resolve(&PageviewResolver.resolve_pageviews/3)
    end

    @desc "Get event analytics data"
    field :events, :event_result do
      arg(:site_id, non_null(:string))
      arg(:date_range, non_null(:date_range_input))
      arg(:filters, :event_filter_input)
      arg(:aggregation, :aggregation_input)
      arg(:pagination, :pagination_input)

      resolve(&EventResolver.resolve_events/3)
    end

    @desc "Get custom metric data"
    field :metrics, :metric_result do
      arg(:site_id, non_null(:string))
      arg(:date_range, non_null(:date_range_input))
      arg(:filters, non_null(:metric_filter_input))
      arg(:aggregation, :aggregation_input)
      arg(:pagination, :pagination_input)

      resolve(&MetricResolver.resolve_metrics/3)
    end
  end
end
