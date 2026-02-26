defmodule Plausible.Graphqla.Middleware.QueryComplexity do
  @moduledoc """
  Middleware for analyzing and limiting GraphQL query complexity.

  This middleware calculates the complexity of incoming queries based on:
  - Field selection counts
  - Pagination limits
  - Aggregation granularity

  Queries exceeding the maximum complexity are rejected to prevent
  expensive operations that could degrade service performance.
  """

  @behaviour Absinthe.Middleware

  # Maximum allowed complexity score
  @max_complexity 1000

  def call(resolution, _opts) do
    complexity = calculate_complexity(resolution)

    if complexity > @max_complexity do
      resolution
      |> Absinthe.Resolution.put_result({:error, %{message: "Query complexity #{complexity} exceeds maximum allowed #{@max_complexity}"}})
    else
      resolution
    end
  end

  defp calculate_complexity(resolution) do
    %{arguments: args, definition: %{schema_node: schema_node}} = resolution

    base_complexity = complexity_for_field(schema_node.identifier)
    pagination_complexity = pagination_complexity(args)
    aggregation_complexity = aggregation_complexity(args)

    base_complexity + pagination_complexity + aggregation_complexity
  end

  # Base complexity for each query type
  defp complexity_for_field(:pageviews), do: 10
  defp complexity_for_field(:pageview_aggregations), do: 20
  defp complexity_for_field(:events), do: 10
  defp complexity_for_field(:event_aggregations), do: 20
  defp complexity_for_field(:custom_metrics), do: 10
  defp complexity_for_field(:custom_metric_aggregations), do: 20
  defp complexity_for_field(_), do: 1

  # Complexity from pagination
  defp pagination_complexity(args) do
    pagination = args[:pagination] || %{}
    limit = pagination[:limit] || 100
    # Complexity scales with limit - each item adds complexity
    min(limit, 500) * 2
  end

  # Complexity from aggregation settings
  defp aggregation_complexity(args) do
    granularity = args[:granularity]

    case granularity do
      :hour -> 100
      :day -> 50
      :week -> 25
      :month -> 10
      _ -> 0
    end
  end
end
