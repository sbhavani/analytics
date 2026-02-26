defmodule PlausibleWeb.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for analytics API.
  """

  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers
  alias PlausibleWeb.GraphQL.Types
  alias PlausibleWeb.GraphQL.InputTypes

  import_types(Types)
  import_types(InputTypes)

  query do
    @desc "Get pageview data with optional filtering"
    field :pageviews, list_of(:pageview_result) do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:limit, :integer)
      arg(:offset, :integer)

      resolve(&Resolvers.pageviews/3)
    end

    @desc "Get aggregated pageview metrics"
    field :pageviews_aggregate, :aggregate_result do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:aggregation, non_null(:aggregation_input))

      resolve(&Resolvers.pageviews_aggregate/3)
    end

    @desc "Get pageview timeseries data"
    field :pageviews_timeseries, list_of(:time_series_point) do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:interval, non_null(:time_grouping))

      resolve(&Resolvers.pageviews_timeseries/3)
    end

    @desc "Get event data with optional filtering"
    field :events, list_of(:event_result) do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:event_type, :string)
      arg(:limit, :integer)
      arg(:offset, :integer)

      resolve(&Resolvers.events/3)
    end

    @desc "Get aggregated event metrics"
    field :events_aggregate, :aggregate_result do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:event_type, :string)
      arg(:aggregation, non_null(:aggregation_input))

      resolve(&Resolvers.events_aggregate/3)
    end

    @desc "Get custom metrics for a site"
    field :custom_metrics, list_of(:custom_metric_result) do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)

      resolve(&Resolvers.custom_metrics/3)
    end

    @desc "Get combined analytics data"
    field :analytics, list_of(:time_series_point) do
      arg(:site_id, non_null(:id))
      arg(:filter, :filter_input)
      arg(:metrics, non_null(list_of(:string)))
      arg(:interval, :time_grouping)

      resolve(&Resolvers.analytics/3)
    end
  end
end
