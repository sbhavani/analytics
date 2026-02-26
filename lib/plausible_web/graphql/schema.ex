defmodule PlausibleWeb.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for the Analytics API.
  Provides queries for pageviews, events, and custom metrics.
  """

  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers
  alias PlausibleWeb.GraphQL.Middleware.Logging

  # Import types
  import_types(PlausibleWeb.GraphQL.Types.PageviewTypes)
  import_types(PlausibleWeb.GraphQL.Types.EventTypes)
  import_types(PlausibleWeb.GraphQL.Types.CustomMetricTypes)
  import_types(PlausibleWeb.GraphQL.Types.CommonTypes)
  import_types(PlausibleWeb.GraphQL.Types.InputTypes)

  # Query type
  object :query do
    @desc "Query pageview data for a site"
    field :pageviews, :pageview_result do
      arg :site_id, non_null(:id)
      arg :date_range, :date_range_input
      arg :filters, list_of(:filter_input)
      arg :pagination, :pagination_input
      arg :aggregation, :aggregation_input

      resolve(&Resolvers.PageviewResolver.pageviews/3)
      middleware(Logging)
    end

    @desc "Query event data for a site"
    field :events, :event_result do
      arg :site_id, non_null(:id)
      arg :date_range, :date_range_input
      arg :filters, list_of(:filter_input)
      arg :pagination, :pagination_input
      arg :aggregation, :aggregation_input

      resolve(&Resolvers.EventResolver.events/3)
      middleware(Logging)
    end

    @desc "Query custom metrics for a site"
    field :custom_metrics, :custom_metric_result do
      arg :site_id, non_null(:id)
      arg :date_range, :date_range_input
      arg :filters, list_of(:filter_input)
      arg :pagination, :pagination_input
      arg :aggregation, :aggregation_input

      resolve(&Resolvers.CustomMetricResolver.custom_metrics/3)
      middleware(Logging)
    end
  end

  # Mutation type (for future use)
  object :mutation do
    # mutations can be added here
  end

  # Subscription type (for future use)
  object :subscription do
    # subscriptions can be added here
  end
end
