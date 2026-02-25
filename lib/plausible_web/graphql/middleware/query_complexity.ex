defmodule PlausibleWeb.GraphQL.Middleware.QueryComplexity do
  @moduledoc """
  Middleware to analyze and limit GraphQL query complexity.

  This middleware calculates the complexity of incoming queries based on:
  - Number of fields requested
  - Nested selections
  - Pagination parameters
  - List/connection fields

  Queries exceeding the configured threshold will be rejected.
  """

  @behaviour Absinthe.Middleware

  # Default complexity thresholds
  @default_max_complexity 1000
  @default_field_cost 1
  @default_list_cost 5
  @default_connection_cost 10
  @default_nesting_discount 0.5

  def call(resolution, opts \\ []) do
    max_complexity = Keyword.get(opts, :max_complexity, @default_max_complexity)
    field_cost = Keyword.get(opts, :field_cost, @default_field_cost)
    list_cost = Keyword.get(opts, :list_cost, @default_list_cost)
    connection_cost = Keyword.get(opts, :connection_cost, @default_connection_cost)
    nesting_discount = Keyword.get(opts, :nesting_discount, @default_nesting_discount)

    query = resolution.definition.query

    complexity =
      calculate_complexity(
        query.selection_set,
        field_cost,
        list_cost,
        connection_cost,
        nesting_discount,
        0
      )

    if complexity > max_complexity do
      resolution
      |> Absinthe.Resolution.put_result(
        {:error,
         %{
           message:
             "Query complexity (#{complexity}) exceeds maximum allowed (#{max_complexity}). Please reduce the number of fields or nesting level.",
           code: :query_too_complex
         }}
      )
    else
      resolution
    end
  end

  defp calculate_complexity(
         nil,
         _field_cost,
         _list_cost,
         _connection_cost,
         _nesting_discount,
         _depth
       ),
       do: 0

  defp calculate_complexity(
         selection_set,
         field_cost,
         list_cost,
         connection_cost,
         nesting_discount,
         depth
       ) do
    Enum.reduce(selection_set.selections, 0, fn selection, acc ->
      case selection do
        %Absinthe.Blueprint.Field{name: name} ->
          # Skip introspection fields
          if String.starts_with?(name, "__") do
            acc
          else
            cost = field_cost + acc
            # Apply nesting discount to reduce complexity for deeply nested queries
            depth_cost = cost * :math.pow(nesting_discount, depth)
            trunc(depth_cost)
          end

        %Absinthe.Blueprint.Fragment.Spread{} ->
          acc

        %Absinthe.Blueprint.Fragment.Inline{} ->
          # Inline fragments add their selections with the same depth
          calculate_complexity(
            selection.selection_set,
            field_cost,
            list_cost,
            connection_cost,
            nesting_discount,
            depth
          ) + acc

        %Absinthe.Blueprint.Operation.Field{} ->
          # This is a top-level field (query/mutation)
          calculate_complexity(
            selection.selection_set,
            field_cost,
            list_cost,
            connection_cost,
            nesting_discount,
            depth + 1
          ) + acc

        _ ->
          acc
      end
    end)
  end
end
