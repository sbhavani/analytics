defmodule Plausible.Stats.SegmentQueryBuilder do
  @moduledoc """
  Converts filter tree structure to ClickHouse query format.
  The filter tree supports nested AND/OR groups for advanced segmentation.
  """

  alias Plausible.Stats.SQL.WhereBuilder
  alias Plausible.Stats.{ApiQueryParser, QueryBuilder, ParsedQueryParams, QueryError}

  @doc """
  Builds a ClickHouse query from a filter tree for segment preview.
  Returns the filtered query that can be used to count visitors.
  """
  @spec build_filter_clause(map()) :: {:ok, [any()]} | {:error, String.t()}
  def build_filter_clause(filter_tree) when is_map(filter_tree) do
    with {:ok, root} <- extract_root(filter_tree),
         {:ok, clause} <- build_node_clause(root) do
      {:ok, clause}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp extract_root(%{"version" => _version, "root" => root}) do
    {:ok, root}
  end

  defp extract_root(_), do: {:error, "Invalid filter tree structure"}

  # Build clause for a group node
  defp build_node_clause(%{
         "type" => "group",
         "operator" => operator,
         "children" => children
       }) do
    clauses_result =
      children
      |> Enum.map(&build_node_clause/1)
      |> collect_results()

    case clauses_result do
      {:ok, clauses} when length(clauses) == 1 ->
        {:ok, hd(clauses)}

      {:ok, clauses} when length(clauses) > 1 ->
        operator_atom = String.to_atom(operator)
        {:ok, [operator_atom, clauses]}

      {:ok, []} ->
        {:ok, true}

      error ->
        error
    end
  end

  # Build clause for a condition node
  defp build_node_clause(%{
         "type" => "condition",
         "attribute" => attribute,
         "operator" => operator,
         "value" => value,
         "negated" => negated
       }) do
    with {:ok, parsed_operator} <- parse_operator(operator),
         {:ok, filter} <-
           build_filter_clause(attribute, parsed_operator, value) do
      clause =
        if negated do
          [:not, filter]
        else
          filter
        end

      {:ok, clause}
    else
      {:error, message} -> {:error, message}
    end
  end

  defp build_node_clause(_), do: {:error, "Invalid node structure"}

  # Convert filter tree operator to Plausible filter format
  defp parse_operator("is"), do: {:ok, :is}
  defp parse_operator("is_not"), do: {:ok, :is_not}
  defp parse_operator("contains"), do: {:ok, :contains}
  defp parse_operator("contains_not"), do: {:ok, :contains_not}
  defp parse_operator("matches"), do: {:ok, :matches}
  defp parse_operator("matches_not"), do: {:ok, :matches_not}
  defp parse_operator("matches_wildcard"), do: {:ok, :matches_wildcard}
  defp parse_operator("matches_wildcard_not"), do: {:ok, :matches_wildcard_not}
  defp parse_operator("has_done"), do: {:ok, :has_done}
  defp parse_operator("has_not_done"), do: {:ok, :has_not_done}

  defp parse_operator(op), do: {:error, "Unknown operator: #{op}"}

  # Build filter clause compatible with WhereBuilder
  defp build_filter_clause(attribute, operator, value) do
    # Parse the attribute to determine dimension
    dimension = parse_dimension(attribute)

    case {operator, value} do
      {:has_done, _} ->
        {:ok, [:has_done, dimension]}

      {:has_not_done, _} ->
        {:ok, [:has_not_done, dimension]}

      {op, value} when is_binary(value) ->
        {:ok, [op, dimension, value]}

      _ ->
        {:error, "Invalid filter: #{attribute} #{operator} #{value}"}
    end
  end

  defp parse_dimension(attribute) do
    # Convert visit:country -> :country, event:page -> :page
    attribute
    |> String.replace_leading("event:props:", "event:meta:")
    |> String.replace_leading("event:", "")
    |> String.replace_leading("visit:", "")
    |> String.to_atom()
  end

  defp collect_results(results) do
    results
    |> Enum.reduce({:ok, []}, fn
      {:ok, clause}, {:ok, acc} ->
        {:ok, acc ++ [clause]}

      {:error, _}, _ ->
        {:error, "Failed to build filter clause"}

      _, {:error, _} = error ->
        error
    end)
  end

  @doc """
  Validates and builds a full query with the filter tree.
  """
  @spec build_query(Plausible.Site.t(), map(), map()) ::
          {:ok, map()} | {:error, String.t()}
  def build_query(site, filter_tree, query_params) do
    with {:ok, clause} <- build_filter_clause(filter_tree),
         :ok <- Plausible.FilterTreeValidator.validate(filter_tree) do
      # Convert to parsed filters format
      filters =
        if clause == true or (is_list(clause) and clause == [:and, []]) do
          []
        else
          [clause]
        end

      params = %{
        query_params
        | filters: filters
      }

      case QueryBuilder.build(site, params) do
        {:ok, query} ->
          {:ok, query}

        {:error, %QueryError{message: message}} ->
          {:error, message}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    else
      {:error, message} -> {:error, message}
    end
  end
end
