defmodule Plausible.GraphQL.Logger do
  @moduledoc """
  Structured logging for GraphQL operations.
  """

  require Logger

  @doc """
  Logs GraphQL query execution.
  """
  def log_query(operation, variables, context, duration_ms) do
    Logger.info(
      "GraphQL query executed",
      operation: operation,
      variables_keys: Map.keys(variables || %{}),
      authenticated: is_map(context[:auth]) and context[:auth] != %{},
      duration_ms: duration_ms
    )
  end

  @doc """
  Logs GraphQL query errors.
  """
  def log_error(operation, error, context) do
    Logger.warning(
      "GraphQL query failed",
      operation: operation,
      error: inspect(error),
      authenticated: is_map(context[:auth]) and context[:auth] != %{}
    )
  end

  @doc """
  Logs resolver execution.
  """
  def log_resolver(field, site_id, duration_ms) do
    Logger.info(
      "GraphQL resolver executed",
      field: field,
      site_id: site_id,
      duration_ms: duration_ms
    )
  end
end
