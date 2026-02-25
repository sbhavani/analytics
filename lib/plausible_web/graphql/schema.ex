defmodule PlausibleWeb.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for exposing analytics data.
  """

  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers

  import_types(PlausibleWeb.GraphQL.Types.Common)
  import_types(PlausibleWeb.GraphQL.Types.Pageview)
  import_types(PlausibleWeb.GraphQL.Types.Event)
  import_types(PlausibleWeb.GraphQL.Types.Metric)
  import_types(PlausibleWeb.GraphQL.Types.Aggregate)
  import_types(PlausibleWeb.GraphQL.Types.Filters)

  # Apply query complexity middleware to all queries
  middleware PlausibleWeb.GraphQL.Middleware.QueryComplexity,
    max_complexity: 1000,
    field_cost: 1,
    list_cost: 5,
    connection_cost: 10,
    nesting_discount: 0.5

  query do
    @desc "Get pageviews for a site"
    field :pageviews, :pageview_connection do
      arg :site_id, non_null(:string)
      arg :date_range, non_null(:date_range_input)
      arg :filter, :pageview_filter
      arg :pagination, :pagination_input
      arg :sort, list_of(:sort_input)

      resolve &Resolvers.Pageviews.list_pageviews/3
    end

    @desc "Get events for a site"
    field :events, :event_connection do
      arg :site_id, non_null(:string)
      arg :date_range, non_null(:date_range_input)
      arg :filter, :event_filter
      arg :pagination, :pagination_input

      resolve &Resolvers.Events.list_events/3
    end

    @desc "Get custom metrics for a site"
    field :custom_metrics, list_of(:custom_metric) do
      arg :site_id, non_null(:string)
      arg :date_range, :date_range_input

      resolve &Resolvers.Metrics.list_custom_metrics/3
    end

    @desc "Get aggregated metrics for a site"
    field :aggregate, :aggregate_result do
      arg :site_id, non_null(:string)
      arg :date_range, non_null(:date_range_input)
      arg :metrics, non_null(list_of(:string))
      arg :filter, :event_filter

      resolve &Resolvers.Aggregate.get_aggregate/3
    end

    @desc "Get timeseries data for a site"
    field :timeseries, :timeseries_result do
      arg :site_id, non_null(:string)
      arg :date_range, non_null(:date_range_input)
      arg :metrics, non_null(list_of(:string))
      arg :interval, :time_interval

      resolve &Resolvers.Aggregate.get_timeseries/3
    end
  end
end
