defmodule Plausible.Graphqla.Schema do
  @moduledoc """
  GraphQL schema for the Plausible Analytics API
  """
  use Absinthe.Schema

  alias Plausible.Graphqla.Resolvers.{
    PageviewResolver,
    EventResolver,
    CustomMetricResolver,
    AggregationResolver
  }

  # Maximum complexity allowed for a single query
  @max_complexity 1000

  # Scalar types
  scalar :date, Plausible.Graphqla.Types.Scalars.Date do
    parse &Absinthe.Type.Scalar.parse/1
    serialize &Absinthe.Type.Scalar.serialize/1
  end

  scalar :datetime, Plausible.Graphqla.Types.Scalars.DateTime do
    parse &Absinthe.Type.Scalar.parse/1
    serialize &Absinthe.Type.Scalar.serialize/1
  end

  scalar :json, Plausible.Graphqla.Types.Scalars.JSON do
    parse &Absinthe.Type.Scalar.parse/1
    serialize &Absinthe.Type.Scalar.serialize/1
  end

  # Enums
  enum :time_granularity do
    value :hour
    value :day
    value :week
    value :month
  end

  # Input types
  input_object :date_range_input do
    field :from, non_null(:date)
    field :to, non_null(:date)
  end

  input_object :pagination_input do
    field :limit, :integer, default_value: 100
    field :offset, :integer, default_value: 0
  end

  input_object :pageview_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :url_pattern, :string
  end

  input_object :event_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :event_type, :string
  end

  input_object :custom_metric_filter_input do
    field :site_id, non_null(:id)
    field :date_range, :date_range_input
    field :metric_name, :string
  end

  # Connection types
  connection node_type: :pageview
  connection node_type: :event
  connection node_type: :custom_metric

  # Object types
  object :pageview do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :url, non_null(:string)
    field :referrer, :string
    field :browser, :string
    field :device, :string
    field :country, :string
  end

  object :event do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :name, non_null(:string)
    field :properties, :json
    field :browser, :string
    field :device, :string
    field :country, :string
  end

  object :custom_metric do
    field :id, non_null(:id)
    field :timestamp, non_null(:datetime)
    field :name, non_null(:string)
    field :value, non_null(:float)
    field :site_id, non_null(:id)
  end

  object :aggregation_result do
    field :key, :string
    field :count, :integer
    field :sum, :float
    field :average, :float
  end

  # Queries
  query do
    # Pageview queries
    field :pageviews, :pageview_connection do
      arg :filter, :pageview_filter_input
      arg :pagination, :pagination_input
      complexity &__MODULE__.query_complexity/2
      resolve &PageviewResolver.list_pageviews/2
    end

    field :pageview_aggregations, list_of(:aggregation_result) do
      arg :filter, :pageview_filter_input
      arg :granularity, :time_granularity
      complexity &__MODULE__.query_complexity/2
      resolve &AggregationResolver.pageview_aggregations/2
    end

    # Event queries
    field :events, :event_connection do
      arg :filter, :event_filter_input
      arg :pagination, :pagination_input
      complexity &__MODULE__.query_complexity/2
      resolve &EventResolver.list_events/2
    end

    field :event_aggregations, list_of(:aggregation_result) do
      arg :filter, :event_filter_input
      arg :group_by, :string
      complexity &__MODULE__.query_complexity/2
      resolve &AggregationResolver.event_aggregations/2
    end

    # Custom metric queries
    field :custom_metrics, :custom_metric_connection do
      arg :filter, :custom_metric_filter_input
      arg :pagination, :pagination_input
      complexity &__MODULE__.query_complexity/2
      resolve &CustomMetricResolver.list_custom_metrics/2
    end

    field :custom_metric_aggregations, list_of(:aggregation_result) do
      arg :filter, :custom_metric_filter_input
      complexity &__MODULE__.query_complexity/2
      resolve &AggregationResolver.custom_metric_aggregations/2
    end
  end

  # Complexity calculation function
  # Called by Absinthe to calculate query complexity
  def query_complexity(args, %{complexity: child_complexity}) do
    base = base_complexity(args)
    pagination = pagination_complexity(args)
    aggregation = aggregation_complexity(args)

    # For connections, child_complexity is the complexity of edges
    # We add it to our calculation
    base + pagination + aggregation + child_complexity
  end

  def query_complexity(args, _) do
    base = base_complexity(args)
    pagination = pagination_complexity(args)
    aggregation = aggregation_complexity(args)

    base + pagination + aggregation
  end

  # Base complexity by field type
  defp base_complexity(%{filter: %{site_id: _}}), do: 10
  defp base_complexity(_), do: 1

  # Complexity from pagination settings
  defp pagination_complexity(args) do
    case args[:pagination] do
      %{limit: limit} when is_integer(limit) -> min(limit, 500) * 2
      _ -> 200  # Default limit of 100 * 2
    end
  end

  # Complexity from aggregation granularity
  defp aggregation_complexity(args) do
    case args[:granularity] do
      :hour -> 100
      :day -> 50
      :week -> 25
      :month -> 10
      _ -> 0
    end
  end
end
