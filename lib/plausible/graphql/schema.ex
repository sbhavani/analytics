defmodule Plausible.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for Plausible Analytics API
  """
  use Absinthe.Schema

  # Import types
  import_types(Plausible.GraphQL.Types.Site)
  import_types(Plausible.GraphQL.Types.PageviewData)
  import_types(Plausible.GraphQL.Types.EventData)
  import_types(Plausible.GraphQL.Types.CustomMetric)
  import_types(Plausible.GraphQL.Types.TimeSeriesData)
  import_types(Plausible.GraphQL.Types.DateRange)
  import_types(Plausible.GraphQL.Types.PeriodType)
  import_types(Plausible.GraphQL.Types.FilterInput)
  import_types(Plausible.GraphQL.Types.Aggregation)

  # Import introspection types for GraphQL introspection support
  import_types(Absinthe.Type.Introspection)

  # Query complexity settings for rate limiting
  @max_complexity 1000

  query do
    @desc "Query analytics data for a specific site"
    field :analytics, :analytics_result do
      arg :site_id, non_null(:id)
      arg :date_range, :date_range_input
      arg :filters, :filter_input
      arg :aggregation, :aggregation_input

      # Complexity analysis for rate limiting
      # Base complexity + complexity based on requested fields
      complexity &__MODULE__.calculate_complexity/2

      resolve(&Plausible.GraphQL.Resolvers.Analytics.analytics/3)
    end

    # GraphQL introspection queries
    import_fields :introspection_query_fields
  end

  object :analytics_result do
    field :pageviews, :pageview_data
    field :events, list_of(:event_data)
    field :custom_metrics, list_of(:custom_metric)
    field :timeseries, list_of(:time_series_data)
    field :metadata, :query_metadata
  end

  object :query_metadata do
    field :site, :site
    field :date_range, :date_range_output
    field :sampling_rate, :float
  end

  # Complexity calculation for the analytics query
  # This calculates cost based on requested fields and arguments
  def calculate_complexity(args, child_complexity) do
    base = 1

    # Add complexity for date range (longer ranges = more data points for timeseries)
    date_range_complexity = calculate_date_range_complexity(args[:date_range])

    # Add complexity for filters (complex filters require more processing)
    filters_complexity = calculate_filters_complexity(args[:filters])

    base + date_range_complexity + filters_complexity + child_complexity
  end

  defp calculate_date_range_complexity(nil), do: 0

  defp calculate_date_range_complexity(date_range) do
    case date_range do
      %{from: from, to: to} when is_struct(from, Date) and is_struct(to, Date) ->
        days = Date.diff(to, from) + 1
        # Timeseries complexity scales with number of days
        # Each day is a data point in the timeseries
        min(days, 365)

      _ ->
        0
    end
  end

  defp calculate_filters_complexity(nil), do: 0

  defp calculate_filters_complexity(filters) do
    # Each filter adds complexity
    # More filters = more complex query
    case filters do
      %{filters: filter_list} when is_list(filter_list) ->
        length(filter_list) * 2

      _ ->
        0
    end
  end

  # Enable query complexity analysis for rate limiting
  def max_complexity, do: @max_complexity
end
