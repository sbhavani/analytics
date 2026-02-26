defmodule PlausibleWeb.GraphQL.Schema do
  use Absinthe.Schema
  use Plausible
  use Absinthe.Relay.Schema, :modern

  alias PlausibleWeb.GraphQL.Resolvers
  alias PlausibleWeb.GraphQL.Middleware.ValidatePagination
  alias PlausibleWeb.GraphQL.Middleware.ErrorHandler

  import_types(Absinthe.Plug.Types)
  import_types(PlausibleWeb.GraphQL.Types)

  # Run error handler after all resolvers
  middleware ErrorHandler

  query do
    @desc "Get pageviews for a site"
    connection field :pageviews, node_type: :pageview do
      arg(:filter, :pageview_filter)
      arg(:pagination, :pagination_input)
      arg(:sort, :sort_input)

      middleware(ValidatePagination)
      resolve(&Resolvers.Pageviews.pageviews/3)
    end

    @desc "Get events for a site"
    connection field :events, node_type: :event do
      arg(:filter, :event_filter)
      arg(:pagination, :pagination_input)
      arg(:sort, :sort_input)

      middleware(ValidatePagination)
      resolve(&Resolvers.Events.events/3)
    end

    @desc "Get aggregated metrics for a site"
    connection field :metrics, node_type: :metric do
      arg(:filter, :metric_filter)
      arg(:aggregation_type, non_null(:aggregation_type))
      arg(:time_grouping, non_null(:time_grouping))
      arg(:pagination, :pagination_input)

      middleware(ValidatePagination)
      resolve(&Resolvers.Metrics.metrics/3)
    end
  end
end
