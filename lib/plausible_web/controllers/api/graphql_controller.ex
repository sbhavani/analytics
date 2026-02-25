defmodule PlausibleWeb.Api.GraphQLController do
  @moduledoc """
  Controller for GraphQL API endpoints
  """
  use PlausibleWeb, :controller

  require OpenTelemetry.Tracer

  alias Plausible.GraphQL.Schema

  plug :put_view, json: PlausibleWeb.JSONView

  def execute(conn, %{ "query" => query } = params) do
    start_time = System.monotonic_time(:millisecond)
    context = build_context(conn)
    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operation_name")

    # Log the incoming GraphQL request
    Logger.info(
      "GraphQL request received",
      operation_name: operation_name,
      site_id: context.site && context.site.domain,
      query_length: String.length(query)
    )

    result = Absinthe.run(query, Schema,
      variables: variables,
      operation_name: operation_name,
      context: context
    )

    # Calculate duration
    duration = System.monotonic_time(:millisecond) - start_time

    # Add OpenTelemetry span
    OpenTelemetry.Tracer.with_span "graphql.query" do
      OpenTelemetry.Tracer.set_attributes([
        {:operation_name, operation_name || "anonymous"},
        {:duration_ms, duration},
        {:site, context.site && context.site.domain}
      ])

      case result do
        {:ok, %{data: data, errors: []}} ->
          Logger.info(
            "GraphQL request completed",
            operation_name: operation_name,
            duration_ms: duration,
            status: "success"
          )

          conn
          |> put_status(200)
          |> json(%{data: data})

        {:ok, %{data: data, errors: errors}} when errors != [] ->
          Logger.warning(
            "GraphQL request completed with errors",
            operation_name: operation_name,
            duration_ms: duration,
            error_count: length(errors)
          )

          conn
          |> put_status(200)
          |> json(%{data: data, errors: format_errors(errors)})

        {:error, %{errors: errors}} ->
          Logger.error(
            "GraphQL request failed",
            operation_name: operation_name,
            duration_ms: duration,
            error_count: length(errors)
          )

          conn
          |> put_status(400)
          |> json(%{errors: format_errors(errors)})

        {:error, error} ->
          Logger.error(
            "GraphQL request error",
            operation_name: operation_name,
            duration_ms: duration,
            error: inspect(error)
          )

          conn
          |> put_status(500)
          |> json(%{errors: [%{message: "Internal server error: #{inspect(error)}"}]})
      end
    end
  end

  def execute(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{errors: [%{message: "Missing query parameter"}]})
  end

  defp build_context(conn) do
    %{
      site: conn.assigns[:site],
      user: conn.assigns[:current_user],
      team: conn.assigns[:current_team]
    }
  end

  defp format_errors(errors) when is_list(errors) do
    Enum.map(errors, &format_error/1)
  end

  defp format_error(%{message: message, path: path}) do
    %{
      message: message,
      path: path |> Enum.map(&to_string/1)
    }
  end

  defp format_error(%{message: message}) do
    %{message: message}
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end
end
