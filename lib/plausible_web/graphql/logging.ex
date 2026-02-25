defmodule PlausibleWeb.GraphQL.Logging do
  @moduledoc """
  Structured logging for GraphQL queries.

  Provides functions to log GraphQL query execution with relevant context
  including query text, operation name, variables, user context, and timing.
  """

  require Logger

  @doc """
  Logs a GraphQL query execution.

  ## Parameters
    - query: The GraphQL query string
    - operation_name: The name of the operation (if specified)
    - variables: Map of variables passed to the query
    - context: Map containing current_user, site, and api_key
    - duration_ms: Execution time in milliseconds

  ## Example
      Logging.log_query(query, "GetPageviews", %{site_id: 123}, %{user: user}, 45)
  """
  def log_query(query, operation_name, variables, context, duration_ms) do
    Logger.info(
      "GraphQL query executed",
      %{
        query: sanitize_query(query),
        operation_name: operation_name,
        variables: sanitize_variables(variables),
        user_id: context[:current_user] && context[:current_user].id,
        site_id: context[:site] && context[:site].id,
        api_key_id: context[:api_key] && context[:api_key].id,
        duration_ms: duration_ms
      }
    )
  end

  @doc """
  Logs a GraphQL query error.

  ## Parameters
    - query: The GraphQL query string
    - operation_name: The name of the operation (if specified)
    - error: The error that occurred
    - context: Map containing current_user, site, and api_key
  """
  def log_error(query, operation_name, error, context) do
    Logger.error(
      "GraphQL query failed",
      %{
        query: sanitize_query(query),
        operation_name: operation_name,
        error: inspect_error(error),
        user_id: context[:current_user] && context[:current_user].id,
        site_id: context[:site] && context[:site].id,
        api_key_id: context[:api_key] && context[:api_key].id
      }
    )
  end

  @doc """
  Logs a GraphQL batch query execution.

  ## Parameters
    - operations: List of operations in the batch
    - context: Map containing current_user, site, and api_key
    - duration_ms: Execution time in milliseconds
  """
  def log_batch(operations, context, duration_ms) do
    Logger.info(
      "GraphQL batch query executed",
      %{
        operation_count: length(operations),
        operations: Enum.map(operations, &sanitize_operation/1),
        user_id: context[:current_user] && context[:current_user].id,
        site_id: context[:site] && context[:site].id,
        api_key_id: context[:api_key] && context[:api_key].id,
        duration_ms: duration_ms
      }
    )
  end

  # Sanitize query to avoid logging sensitive data
  defp sanitize_query(nil), do: nil
  defp sanitize_query(query) when is_binary(query) do
    # Truncate very long queries
    if String.length(query) > 1000 do
      String.slice(query, 0, 1000) <> "..."
    else
      query
    end
  end

  # Sanitize variables to avoid logging sensitive data
  defp sanitize_variables(nil), do: %{}
  defp sanitize_variables(variables) when is_map(variables) do
    sensitive_keys = ~w(password token secret key api_key api_key_id)

    variables
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      key = to_string(k)
      if key in sensitive_keys do
        {k, "[REDACTED]"}
      else
        {k, v}
      end
    end)
    |> Map.new()
  end

  defp sanitize_operation(op) when is_map(op) do
    Map.take(op, [:operation_name, :query])
    |> Map.update(:query, nil, &sanitize_query/1)
  end
  defp sanitize_operation(op), do: op

  defp inspect_error(error) when is_binary(error), do: error
  defp inspect_error(error), do: inspect(error)
end
