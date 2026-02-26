defmodule PlausibleWeb.GraphQL.Middleware.Logging do
  @moduledoc """
  GraphQL middleware for structured logging of all queries.

  Logs query details including operation name, field being accessed,
  user information, variables, and execution status.
  """

  require Logger

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    start_time = System.system_time(:millisecond)

    # Store start time in resolution for later use
    resolution
    |> Map.put(:__logging_start_time__, start_time)
  end

  @doc """
  Logs the result of a GraphQL operation after execution.
  Call this from the controller or as a final middleware in the chain.
  """
  def log_result(resolution, query, variables, operation_name \\ nil) do
    start_time = resolution.__logging_start_time__ || System.system_time(:millisecond)
    duration = System.system_time(:millisecond) - start_time

    log_data = build_log_data(resolution, query, variables, operation_name, duration)

    # Log at appropriate level based on result
    case resolution do
      %{errors: errors} when errors != [] ->
        Logger.warning("GraphQL query failed", log_data)

      _ ->
        Logger.info("GraphQL query executed", log_data)
    end
  end

  defp build_log_data(resolution, query, variables, operation_name, duration) do
    %{
      operation_name: operation_name || extract_operation_name(query),
      query_field: extract_field_name(resolution),
      user_id: get_user_id(resolution),
      site_id: get_site_id(resolution),
      remote_ip: resolution.context[:remote_ip],
      user_agent: resolution.context[:user_agent],
      variables: sanitize_variables(variables),
      duration_ms: duration,
      has_errors: has_errors?(resolution),
      error_count: length(resolution.errors || [])
    }
  end

  defp extract_operation_name(query) when is_binary(query) do
    # Try to extract operation name from query string
    # Look for patterns like "query OperationName" or "mutation OperationName"
    case Regex.run(~r/(query|mutation|subscription)\s+(\w+)/, query) do
      [_, _type, name] -> name
      _ -> nil
    end
  end

  defp extract_operation_name(_), do: nil

  defp extract_field_name(resolution) do
    case resolution do
      %{definition: %{schema_node: %{name: name}}} -> name
      _ -> nil
    end
  end

  defp get_user_id(resolution) do
    case resolution.context do
      %{current_user: user} when not is_nil(user) ->
        case user do
          %{id: id} -> id
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp get_site_id(resolution) do
    case resolution.arguments do
      %{site_id: site_id} -> site_id
      %{siteId: site_id} -> site_id
      _ -> nil
    end
  end

  defp sanitize_variables(variables) when is_map(variables) do
    # Remove potentially sensitive keys
    variables
    |> Map.drop(["password", "token", "secret", "api_key", "authorization"])
    |> Enum.map(fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  defp sanitize_variables(_), do: %{}

  defp sanitize_value(value) when is_binary(value) do
    # Truncate long strings to avoid log bloat
    if String.length(value) > 100 do
      String.slice(value, 0, 100) <> "..."
    else
      value
    end
  end

  defp sanitize_value(value) when is_map(value) do
    sanitize_variables(value)
  end

  defp sanitize_value(value) when is_list(value) do
    Enum.map(value, &sanitize_value/1)
  end

  defp sanitize_value(value), do: value

  defp has_errors?(resolution) do
    case resolution do
      %{errors: errors} when errors != [] -> true
      _ -> false
    end
  end
end
