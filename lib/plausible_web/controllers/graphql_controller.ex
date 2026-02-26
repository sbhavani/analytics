defmodule PlausibleWeb.GraphQLController do
  @moduledoc """
  Controller for handling GraphQL API requests.
  """

  use PlausibleWeb, :controller
  require Logger

  alias PlausibleWeb.GraphQL.Schema

  def execute(conn, %{ "query" => query } = params) do
    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operation_name")

    context = build_context(conn)

    start_time = System.system_time(:millisecond)

    result = Absinthe.run(query, Schema, variables: variables, operation_name: operation_name, context: context)

    # Log the query execution
    log_data = build_log_data(query, variables, operation_name, start_time, result, conn)
    log_query_result(result, log_data)

    case result do
      {:ok, %{data: data, errors: []}} ->
        conn
        |> put_status(:ok)
        |> json(%{data: data})

      {:ok, %{data: data, errors: errors}} ->
        formatted_errors = format_errors(errors)

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{data: data, errors: formatted_errors})

      {:error, %{errors: errors}} ->
        formatted_errors = format_errors(errors)

        conn
        |> put_status(:bad_request)
        |> json(%{errors: formatted_errors})

      {:error, error} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: [%{message: "Internal server error: #{inspect(error)}"}]})
    end
  end

  def execute(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: [%{message: "Missing query parameter"}]})
  end

  defp build_context(conn) do
    # Get the current user from the session
    user = get_session(conn, :current_user)

    %{
      current_user: user,
      remote_ip: get_remote_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    }
  end

  defp get_remote_ip(conn) do
    forwarded_for = get_req_header(conn, "x-forwarded-for") |> List.first()

    if forwarded_for do
      String.split(forwarded_for, ",") |> List.first() |> String.trim()
    else
      to_string(:inet.ntoa(conn.remote_ip))
    end
  end

  defp format_errors(errors) when is_list(errors) do
    Enum.map(errors, &format_error/1)
  end

  defp format_error(%Absinthe.Resolution{errors: errors}) do
    format_errors(errors)
  end

  defp format_error(error) when is_map(error) do
    %{
      message: error[:message] || error.message || "Unknown error",
      locations: format_locations(error[:locations]),
      path: error[:path],
      extensions: error[:extensions] || %{}
    }
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end

  defp format_locations(nil), do: []
  defp format_locations(locations) when is_list(locations) do
    Enum.map(locations, fn loc ->
      %{
        line: loc[:line] || loc.line,
        column: loc[:column] || loc.column
      }
    end)
  end

  defp build_log_data(query, variables, operation_name, start_time, result, conn) do
    duration = System.system_time(:millisecond) - start_time

    %{
      query: extract_query_name(query),
      operation_name: operation_name || extract_operation_name(query),
      variables: sanitize_variables(variables),
      duration_ms: duration,
      remote_ip: get_remote_ip(conn),
      user_agent: get_req_header(conn, "user-agent") |> List.first(),
      has_errors: has_errors?(result),
      error_count: get_error_count(result)
    }
  end

  defp log_query_result({:ok, %{errors: errors}}, log_data) when errors != [] do
    Logger.warning("GraphQL query completed with errors", log_data)
  end

  defp log_query_result({:error, _}, log_data) do
    Logger.warning("GraphQL query failed", log_data)
  end

  defp log_query_result(_result, log_data) do
    Logger.info("GraphQL query executed", log_data)
  end

  defp extract_operation_name(query) when is_binary(query) do
    case Regex.run(~r/(query|mutation|subscription)\s+(\w+)/, query) do
      [_, _type, name] -> name
      _ -> nil
    end
  end

  defp extract_operation_name(_), do: nil

  defp extract_query_name(query) when is_binary(query) do
    # Extract the main field being queried
    case Regex.run(~r/(pageviews|events|custom_metrics)/, query) do
      [_, name] -> name
      _ -> nil
    end
  end

  defp extract_query_name(_), do: nil

  defp sanitize_variables(variables) when is_map(variables) do
    variables
    |> Map.drop(["password", "token", "secret", "api_key", "authorization"])
    |> Enum.map(fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  defp sanitize_variables(_), do: %{}

  defp sanitize_value(value) when is_binary(value) do
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

  defp has_errors?({:ok, %{errors: errors}}), do: errors != []
  defp has_errors?({:error, _}), do: true
  defp has_errors?(_), do: false

  defp get_error_count({:ok, %{errors: errors}}), do: length(errors || [])
  defp get_error_count({:error, %{errors: errors}}), do: length(errors || [])
  defp get_error_count({:error, _}), do: 1
  defp get_error_count(_), do: 0
end
