defmodule PlausibleWeb.GraphQL.Resolvers.Helpers.Aggregation do
  @moduledoc """
  Helper module for handling aggregation operations in GraphQL queries.
  """

  @doc """
  Converts a GraphQL aggregation input to Plausible.Stats metrics.
  """
  def to_stats_metrics(nil), do: []

  def to_stats_metrics(%{type: type, field: field}) do
    case type do
      :count -> ["visitors"]
      :sum -> [convert_field_to_metric(field, "sum")]
      :avg -> [convert_field_to_metric(field, "avg")]
      :min -> [convert_field_to_metric(field, "min")]
      :max -> [convert_field_to_metric(field, "max")]
      _ -> ["visitors"]
    end
  end

  defp convert_field_to_metric(nil, _), do: "visitors"

  defp convert_field_to_metric(field, aggregation) do
    "#{aggregation}:#{field}"
  end

  @doc """
  Applies aggregation to query results.
  """
  def apply_aggregation(results, %{type: type}) when is_list(results) do
    case type do
      :count -> %{count: length(results)}
      :sum -> aggregate_numeric(results, :sum)
      :avg -> aggregate_numeric(results, :avg)
      :min -> aggregate_numeric(results, :min)
      :max -> aggregate_numeric(results, :max)
      _ -> %{count: length(results)}
    end
  end

  def apply_aggregation(results, _), do: results

  defp aggregate_numeric(results, operation) do
    numeric_values =
      results
      |> Enum.flat_map(fn
        %{view_count: v} -> [v]
        %{count: v} -> [v]
        %{unique_visitors: v} -> [v]
        %{value: v} -> [v]
        _ -> []
      end)
      |> Enum.reject(&is_nil/1)

    case numeric_values do
      [] ->
        %{value: 0}

      values ->
        result =
          case operation do
            :sum -> Enum.sum(values)
            :avg -> Enum.sum(values) / length(values)
            :min -> Enum.min(values)
            :max -> Enum.max(values)
          end

        %{value: result}
    end
  end
end
