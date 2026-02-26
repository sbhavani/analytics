defmodule PlausibleWeb.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for the Analytics API
  """

  use Absinthe.Schema

  alias PlausibleWeb.GraphQL.Resolvers.Analytics
  alias PlausibleWeb.GraphQL.Resolvers.Metrics
  alias PlausibleWeb.GraphQL.Middleware.HandleErrors

  import_types PlausibleWeb.GraphQL.Types.Enums
  import_types PlausibleWeb.GraphQL.Types.InputTypes
  import_types PlausibleWeb.GraphQL.Types.AnalyticsTypes
  import_types PlausibleWeb.GraphQL.Types.ErrorTypes

  # Run error handling middleware
  middleware HandleErrors

  query do
    @desc "Get aggregate metrics for a site"
    field :aggregate, :aggregate_result do
      arg :site_id, non_null(:id)
      arg :input, non_null(:aggregate_input)

      resolve &Analytics.aggregate/3
    end

    @desc "Get breakdown by dimension"
    field :breakdown, list_of(:breakdown_result) do
      arg :site_id, non_null(:id)
      arg :input, non_null(:breakdown_input)

      resolve &Analytics.breakdown/3
    end

    @desc "Get time series data"
    field :timeseries, list_of(:time_series_point) do
      arg :site_id, non_null(:id)
      arg :input, non_null(:time_series_input)

      resolve &Analytics.timeseries/3
    end

    @desc "Get custom metrics for a site"
    field :custom_metrics, list_of(:custom_metric) do
      arg :site_id, non_null(:id)

      resolve &Metrics.custom_metrics/3
    end
  end
end
