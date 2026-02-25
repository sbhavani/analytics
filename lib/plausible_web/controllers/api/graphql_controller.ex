defmodule PlausibleWeb.Api.GraphQLController do
  @moduledoc """
  Controller for handling GraphQL API requests
  """
  use PlausibleWeb, :controller

  alias Plausible.GraphQL.Schema
  alias Plausible.GraphQL.ErrorHandler
  alias PlausibleWeb.Plugs.AuthorizeGraphQLAPI

  plug AuthorizeGraphQLAPI

  action_fallback(PlausibleWeb.FallbackController)

  def execute(conn, %{ "_json" => params }) do
    execute_query(conn, params)
  end

  def execute(conn, params) when is_map(params) do
    execute_query(conn, params)
  end

  def execute(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: [%{message: "Invalid request body"}]})
  end

  defp execute_query(conn, params) do
    query = Map.get(params, "query")
    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operationName")

    context = %{
      site: conn.assigns[:site],
      current_user: conn.assigns[:current_user],
      api_key: conn.assigns[:current_api_key]
    }

    Absinthe.run(query, Schema,
      variables: variables,
      operation_name: operation_name,
      context: context
    )
    |> handle_result(conn)
  end

  defp handle_result({:ok, %{data: data, errors: []}}, conn) do
    conn
    |> put_status(:ok)
    |> json(%{data: data})
  end

  defp handle_result({:ok, %{data: data, errors: errors}}, conn) do
    formatted_errors = Enum.map(errors, &ErrorHandler.handle_error/1)

    conn
    |> put_status(:ok)
    |> json(%{data: data, errors: formatted_errors})
  end

  defp handle_result({:error, error}, conn) do
    formatted_error = ErrorHandler.handle_error(error)

    conn
    |> put_status(:bad_request)
    |> json(%{errors: [formatted_error]})
  end
end
