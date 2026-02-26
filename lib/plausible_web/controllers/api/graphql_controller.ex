defmodule PlausibleWeb.Api.GraphQLController do
  @moduledoc """
  GraphQL API controller for analytics data.

  This controller handles GraphQL queries for pageviews, events,
  and custom metrics.
  """

  use PlausibleWeb, :controller
  use PlausibleWeb.Plugs.ErrorHandler

  alias PlausibleWeb.GraphQL
  alias PlausibleWeb.GraphQL.Schema
  alias PlausibleWeb.GraphQL.Context

  require Logger

  # Telemetry for measuring GraphQL response times
  @telemetry_event [:plausible, :graphql, :execute]

  # Maximum allowed query complexity (prevent expensive queries)
  @max_complexity 1000

  action_fallback PlausibleWeb.FallbackController

  @doc """
  Execute a GraphQL query.
  """
  def execute(conn, %{ "query" => query } = params) do
    # Extract operation info for logging
    operation_name = extract_operation_name(query)

    # Log incoming GraphQL request (structured logging per T044)
    Logger.info("GraphQL request received",
      operation: operation_name,
      has_variables: Map.has_key?(params, "variables"),
      has_operation_name: Map.has_key?(params, "operationName"),
      remote_ip: format_ip(conn),
      user_agent: get_user_agent(conn),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )

    # Check query complexity before execution
    case validate_complexity(query, params) do
      {:ok, complexity} ->
        start_time = System.monotonic_time(:millisecond)
        result = do_execute(conn, query, params)

        # Emit telemetry (per SC-002: track response times)
        duration = System.monotonic_time(:millisecond) - start_time
        :telemetry.execute(@telemetry_event, %{duration: duration}, %{})

        # Log successful completion with structured data
        Logger.info("GraphQL request completed",
          operation: operation_name,
          complexity: complexity,
          duration_ms: duration,
          status: :success,
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        )

        result

      {:error, :complexity_exceeded} ->
        Logger.warning("GraphQL query rejected: complexity exceeded limit",
          operation: operation_name,
          max_complexity: @max_complexity,
          remote_ip: format_ip(conn),
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        )
        conn
        |> put_status(:bad_request)
        |> json(%{
          errors: [%{
            message: "Query complexity exceeds maximum allowed (#{@max_complexity}). Please simplify your query or reduce the number of requested fields.",
            extensions: %{code: "COMPLEXITY_EXCEEDED"}
          }]
        })

      {:error, reason} ->
        Logger.warning("GraphQL query validation failed",
          operation: operation_name,
          reason: inspect(reason),
          remote_ip: format_ip(conn),
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
        )
        conn
        |> put_status(:bad_request)
        |> json(%{
          errors: [%{
            message: "Invalid query",
            extensions: %{code: "VALIDATION_ERROR"}
          }]
        })
    end
  end

  def execute(conn, _) do
    Logger.warning("GraphQL request missing query parameter",
      remote_ip: format_ip(conn),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    )

    conn
    |> put_status(:bad_request)
    |> json(%{
      errors: [%{
        message: "Missing 'query' parameter",
        extensions: %{code: "VALIDATION_ERROR"}
      }]
    })
  end

  # Validate query complexity before execution
  defp validate_complexity(query, params) do
    variables = Map.get(params, "variables", %{})

    case Absinthe.Analysis.analyse_query(query, Schema, variables: variables) do
      {:ok, %{complexity: complexity}} when complexity > @max_complexity ->
        {:error, :complexity_exceeded}

      {:ok, %{complexity: complexity}} ->
        {:ok, complexity}

      {:ok, _analysis} ->
        {:ok, 0}

      {:error, _error} ->
        {:error, :analysis_failed}
    end
  end

  # Private implementation for error handling
  defp do_execute(conn, query, params) do
    context = Context.build_context(conn)

    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operationName")

    result = Absinthe.run(query, Schema,
      variables: variables,
      operation_name: operation_name,
      context: context
    )

    case result do
      {:ok, %{data: data, errors: nil}} ->
        json(conn, %{data: data})

      {:ok, %{data: data, errors: errors}} when errors != [] ->
        # GraphQL can return data along with errors
        Logger.warning("GraphQL query completed with errors", errors: inspect(errors))
        conn
        |> put_status(:bad_request)
        |> json(%{data: data, errors: format_errors(errors)})

      {:ok, %{errors: errors}} when errors != [] ->
        Logger.warning("GraphQL query failed", errors: inspect(errors))
        conn
        |> put_status(:bad_request)
        |> json(%{errors: format_errors(errors)})

      {:error, error} ->
        Logger.error("GraphQL execution error", error: inspect(error))
        # Return a user-friendly error message (per SC-006)
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          errors: [%{
            message: "An error occurred while processing your request. Please try again.",
            extensions: %{code: "INTERNAL_ERROR"}
          }]
        })
    end
  end

  # Format errors with descriptive messages (per SC-006)
  defp format_errors(errors) do
    Enum.map(errors, fn error ->
      %{
        message: format_error_message(error),
        locations: format_locations(error),
        path: format_path(error.path),
        extensions: %{code: error_code(error), field: error_field(error)}
      }
    end)
  end

  # Provide helpful error messages
  defp format_error_message(%{message: message, validation: validation}) do
    case validation do
      %{type: type, description: desc} ->
        "Validation error: #{desc}"

      _ ->
        message
    end
  end

  defp format_error_message(%{message: message}) do
    message
  end

  defp format_error_message(error) when is_atom(error) do
    Atom.to_string(error)
  end

  defp format_error_message(error) do
    inspect(error)
  end

  defp format_locations(%{locations: locations}) when is_list(locations) do
    Enum.map(locations, fn %{line: line, column: column} ->
      %{line: line, column: column}
    end)
  end

  defp format_locations(_), do: nil

  defp format_path(nil), do: nil
  defp format_path(path) when is_list(path) do
    Enum.map(path, &to_string/1)
  end
  defp format_path(path), do: [to_string(path)]

  defp error_code(%{validation: _}), do: "VALIDATION_ERROR"
  defp error_code(%{code: code}), do: code
  defp error_code(_), do: "EXECUTION_ERROR"

  defp error_field(%{field: field}), do: field
  defp error_field(_), do: nil

  # Helper to extract the root operation name from a query
  defp extract_operation_name(query) when is_binary(query) do
    case Regex.run(~r/(?:query|mutation|subscription)\s+(\w+)/, query) do
      [_, name] -> name
      _ -> "anonymous"
    end
  end
  defp extract_operation_name(_), do: "unknown"

  # Helper to format the remote IP address
  defp format_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        String.split(forwarded, ",") |> List.first() |> String.trim()

      _ ->
        case conn.remote_ip do
          nil -> nil
          ip -> :inet.ntoa(ip) |> to_string()
        end
    end
  end

  # Helper to get the user agent
  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [ua] -> ua
      _ -> nil
    end
  end
end
