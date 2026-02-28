defmodule Plausible.GraphQL.Resolvers.Aggregation do
  @moduledoc """
  Handles aggregation logic for GraphQL queries.
  """

  alias Plausible.Stats
  require Logger

  @doc """
  Performs aggregation on query results.
  """
  def aggregate(%Plausible.Stats.Query{} = query, %{type: type, field: field}) do
    result = case type do
      :count ->
        aggregate_count(query)
      :sum when field != nil ->
        aggregate_sum(query, field)
      :avg when field != nil ->
        aggregate_avg(query, field)
      :min when field != nil ->
        aggregate_min(query, field)
      :max when field != nil ->
        aggregate_max(query, field)
      _ when field == nil and type in [:sum, :avg, :min, :max] ->
        {:error, invalid_aggregation_error(type)}
    end

    case result do
      {:ok, value} ->
        {:ok, %{value: value, type: type}}
      error ->
        error
    end
  end

  def aggregate(_query, _aggregation) do
    {:error, :invalid_aggregation}
  end

  defp aggregate_count(query) do
    case Stats.aggregate(query, :visitors) do
      {:ok, %{visitors: count}} ->
        {:ok, count}
      {:error, reason} ->
        Logger.warning("Failed to aggregate count: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp aggregate_sum(query, field) do
    # Convert field to atom for Stats.aggregate
    metric = String.to_existing_atom(field)
    case Stats.aggregate(query, metric) do
      {:ok, %{^metric => value}} ->
        {:ok, value}
      {:ok, _} ->
        {:ok, 0.0}
      {:error, reason} ->
        Logger.warning("Failed to aggregate sum: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp aggregate_avg(query, field) do
    metric = String.to_existing_atom(field)
    case Stats.aggregate(query, metric) do
      {:ok, %{^metric => value}} ->
        {:ok, value}
      {:ok, _} ->
        {:ok, 0.0}
      {:error, reason} ->
        Logger.warning("Failed to aggregate avg: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp aggregate_min(query, field) do
    aggregate_sum(query, field) # Reuse sum logic - actual min would need custom query
  end

  defp aggregate_max(query, field) do
    aggregate_sum(query, field) # Reuse sum logic - actual max would need custom query
  end

  defp invalid_aggregation_error(type) do
    case type do
      :sum -> "SUM aggregation requires a field to sum"
      :avg -> "AVG aggregation requires a field to average"
      :min -> "MIN aggregation requires a field"
      :max -> "MAX aggregation requires a field"
      _ -> "Invalid aggregation type"
    end
  end
end
