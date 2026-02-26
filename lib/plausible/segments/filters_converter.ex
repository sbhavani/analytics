defmodule Plausible.Segments.FiltersConverter do
  @moduledoc """
  Converter module for transforming filter expressions to legacy query filters.

  This module handles conversion between the new tree-based filter expression format
  and the legacy flat filter format used by the query builder.
  """

  alias Plausible.Segments.Expression

  @doc """
  Convert a filter expression to query filters.

  Takes a FilterExpression map and returns a list of filters in the format
  expected by the query builder: [operation, dimension, clauses]

  ## Examples

      iex> expression = %{version: 1, rootGroup: %{id: "1", operator: :AND, conditions: [
      ...>   %{id: "c1", field: "country", operator: :equals, value: "US"}
      ...> ]}}
      iex> FiltersConverter.to_query_filters(expression)
      [[:is, "country", ["US"]]]
  """
  @spec to_query_filters(Expression.filter_expression()) :: [[any()]]
  def to_query_filters(expression) do
    Expression.to_legacy_filters(expression)
  end

  @doc """
  Convert a filter expression to API format filters.

  Returns filters in the format expected by the segment_data JSON structure.
  """
  @spec to_api_filters(Expression.filter_expression()) :: [map()]
  def to_api_filters(expression) do
    expression
    |> Expression.to_legacy_filters()
    |> Enum.map(&filter_to_map/1)
  end

  defp filter_to_filter([op, dim, clauses]) do
    %{
      "filter" => [op, dim, clauses]
    }
  end

  defp filter_to_map(filter) when is_list(filter) do
    filter_to_map(filter, %{})
  end

  defp filter_to_map([op, dim, clauses], acc) do
    Map.merge(acc, %{
      "operator" => op,
      "dimension" => dim,
      "clauses" => clauses
    })
  end

  @doc """
  Build a complete segment_data map with both legacy filters and expression.

  This maintains backward compatibility while supporting the new expression format.
  """
  @spec build_segment_data(Expression.filter_expression(), map()) :: map()
  def build_segment_data(expression, labels \\ %{}) do
    %{
      "filters" => to_api_filters(expression),
      "expression" => expression,
      "labels" => labels
    }
  end

  @doc """
  Extract expression from segment_data if present, otherwise build from legacy filters.
  """
  @spec extract_expression(map()) :: Expression.filter_expression() | nil
  def extract_expression(segment_data) when is_map(segment_data) do
    if Map.has_key?(segment_data, "expression") do
      segment_data["expression"]
    else
      # Convert legacy filters to expression for backward compatibility
      if Map.has_key?(segment_data, "filters") do
        filters_to_expression(segment_data["filters"])
      else
        nil
      end
    end
  end

  @doc """
  Convert legacy filter format back to expression format.
  """
  @spec filters_to_expression([map()]) :: Expression.filter_expression()
  def filters_to_expression(filters) when is_list(filters) do
    conditions = Enum.map(filters, &filter_to_condition/1)

    %{
      version: 1,
      rootGroup: %{
        id: generate_id(),
        operator: :AND,
        conditions: conditions
      }
    }
  end

  defp filter_to_condition(%{"dimension" => dim, "operator" => op, "clauses" => clauses}) do
    %{
      id: generate_id(),
      field: dim,
      operator: operator_to_atom(op),
      value: hd(clauses)
    }
  end

  defp filter_to_condition([op, dim, clauses]) do
    %{
      id: generate_id(),
      field: dim,
      operator: operator_to_atom(op),
      value: hd(clauses)
    }
  end

  defp operator_to_atom("is"), do: :equals
  defp operator_to_atom("is_not"), do: :not_equals
  defp operator_to_atom("contains"), do: :contains
  defp operator_to_atom("contains_not"), do: :not_contains
  defp operator_to_atom("matches"), do: :matches_regex
  defp operator_to_atom("is_not_null"), do: :is_set
  defp operator_to_atom("is_null"), do: :is_not_set
  defp operator_to_atom(op) when is_atom(op), do: op

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
