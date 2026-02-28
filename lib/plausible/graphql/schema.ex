defmodule Plausible.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for the Plausible Analytics API.

  This module defines the root query types for accessing
  pageviews, events, and custom metrics through GraphQL.
  """

  use Absinthe.Schema

  alias Plausible.GraphQL.Resolvers

  # Custom scalar types - define before importing types
  scalar :json do
    parse fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        case Jason.decode(value) do
          {:ok, map} -> {:ok, map}
          _ -> :error
        end
      %Absinthe.Blueprint.Input.Object{fields: fields} ->
        {:ok, fields}
      _ ->
        :error
    end

    serialize fn map ->
      Jason.encode!(map)
    end
  end

  # Import Absinthe built-in scalar types (datetime, date, time, naive_datetime, decimal)
  import_types(Absinthe.Type.Custom)

  # Import types from submodules
  import_types(Plausible.GraphQL.Types)
  import_types(Plausible.GraphQL.Types.PageviewTypes)
  import_types(Plausible.GraphQL.Types.EventTypes)
  import_types(Plausible.GraphQL.Types.CustomMetricTypes)
  import_types(Plausible.GraphQL.Types.CommonTypes)

  query do
    # Pageview queries
    field :pageviews, list_of(:pageview) do
      arg :site_id, non_null(:id)
      arg :filter, :pageview_filter_input
      arg :date_range, non_null(:date_range_input)
      arg :limit, :integer, default_value: 100
      arg :offset, :integer, default_value: 0

      resolve &Resolvers.Pageview.list_pageviews/3
    end

    field :pageview_aggregate, :aggregate_result do
      arg :site_id, non_null(:id)
      arg :filter, :pageview_filter_input
      arg :date_range, non_null(:date_range_input)
      arg :aggregation, non_null(:aggregation_input)

      resolve &Resolvers.Pageview.aggregate_pageviews/3
    end

    # Event queries
    field :events, list_of(:event) do
      arg :site_id, non_null(:id)
      arg :filter, :event_filter_input
      arg :date_range, non_null(:date_range_input)
      arg :limit, :integer, default_value: 100
      arg :offset, :integer, default_value: 0

      resolve &Resolvers.Event.list_events/3
    end

    field :event_aggregate, :aggregate_result do
      arg :site_id, non_null(:id)
      arg :filter, :event_filter_input
      arg :date_range, non_null(:date_range_input)
      arg :aggregation, non_null(:aggregation_input)

      resolve &Resolvers.Event.aggregate_events/3
    end

    # Custom metric queries
    field :custom_metrics, list_of(:custom_metric) do
      arg :site_id, non_null(:id)
      arg :filter, :metric_filter_input
      arg :date_range, non_null(:date_range_input)

      resolve &Resolvers.CustomMetric.list_custom_metrics/3
    end

    field :custom_metric_aggregate, :aggregate_result do
      arg :site_id, non_null(:id)
      arg :filter, :metric_filter_input
      arg :date_range, non_null(:date_range_input)
      arg :aggregation, non_null(:aggregation_input)

      resolve &Resolvers.CustomMetric.aggregate_custom_metrics/3
    end
  end
end
