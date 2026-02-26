defmodule PlausibleWeb.GraphQL.Helpers.AggregationHelper do
  @moduledoc """
  Helper module for handling data aggregation in GraphQL queries.
  """

  alias Plausible.Stats

  @doc """
  Parse aggregation input and return metrics for stats queries.

  ## Examples

      iex> parse_aggregation(%{type: :count})
      {:ok, %{metrics: [:visitors]}}

      iex> parse_aggregation(%{type: :sum, field: "value"})
      {:ok, %{metrics: [:sum_values]}}
  """
  def parse_aggregation(nil), do: {:ok, nil}

  def parse_aggregation(%{type: type}) do
    case type do
      :count ->
        {:ok, %{metrics: [:visitors], aggregation: :sum}}

      :sum ->
        {:ok, %{metrics: [:sum_values], aggregation: :sum}}

      :average ->
        {:ok, %{metrics: [:average], aggregation: :avg}}

      _ ->
        {:error, "Unknown aggregation type: #{type}"}
    end
  end

  @doc """
  Determine if the query should return aggregated results.
  """
  def should_aggregate?(nil), do: false
  def should_aggregate?(_), do: true

  @doc """
  Format aggregation result for GraphQL response.
  """
  def format_aggregate_result(results, type, dimension \\ nil) do
    case results do
      %{visitors: count} when type == :count ->
        {:ok, %{aggregation_type: type, value: Float.round(count, 2), dimension: dimension}}

      %{sum_values: sum} when type == :sum ->
        {:ok, %{aggregation_type: type, value: Float.round(sum, 2), dimension: dimension}}

      %{average: avg} when type == :average ->
        {:ok, %{aggregation_type: type, value: Float.round(avg, 2), dimension: dimension}}

      _ ->
        {:ok, %{aggregation_type: type, value: 0.0, dimension: dimension}}
    end
  end
end
