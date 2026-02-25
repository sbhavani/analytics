defmodule PlausibleWeb.Api.GraphQLController do
  use PlausibleWeb, :controller
  use PlausibleWeb.Plugs.ErrorHandler

  alias PlausibleWeb.GraphQL.Schema
  alias PlausibleWeb.GraphQL.ErrorHandler
  alias PlausibleWeb.GraphQL.Logging

  plug(:put_view, json: PlausibleWeb.JSONView)

  def execute(conn, _params) do
    %{params: params, body_params: body_params} = conn

    query = Map.get(body_params, "query")
    operation_name = Map.get(body_params, "operationName")
    variables = Map.get(body_params, "variables", %{})

    context = build_context(conn)

    start_time = System.monotonic_time(:millisecond)

    result = Absinthe.run(query, Schema, variables: variables, operation_name: operation_name, context: context)

    duration_ms = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, %{data: data, errors: []}} ->
        Logging.log_query(query, operation_name, variables, context, duration_ms)
        json(conn, %{data: data})

      {:ok, %{data: data, errors: errors}} ->
        Logging.log_query(query, operation_name, variables, context, duration_ms)
        formatted_errors = ErrorHandler.format_errors(errors)
        conn
        |> put_status(:bad_request)
        |> json(%{data: data, errors: formatted_errors})

      {:error, %{errors: errors}} ->
        Logging.log_error(query, operation_name, errors, context)
        formatted_errors = ErrorHandler.format_errors(errors)
        conn
        |> put_status(:bad_request)
        |> json(%{errors: formatted_errors})
    end
  end

  defp build_context(conn) do
    %{
      current_user: conn.assigns[:current_user],
      site: conn.assigns[:site],
      api_key: conn.assigns[:api_key]
    }
  end
end
