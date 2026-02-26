defmodule PlausibleWeb.GraphQLController do
  @moduledoc """
  Controller for GraphQL API endpoint.
  """

  use PlausibleWeb, :controller

  alias PlausibleWeb.GraphQL.Schema

  plug(:accepts, ["json"])

  def execute(conn, %{}) do
    {:ok, query_data, _} = Plug.Conn.read_body(conn)

    case Jason.decode(query_data) do
      {:ok, %{"query" => query} = data} ->
        variables = Map.get(data, "variables", %{})
        execute_query(conn, query, variables)

      {:ok, %{"query" => _query, "operationName" => operation_name} = data} ->
        variables = Map.get(data, "variables", %{})
        execute_query(conn, data["query"], variables, operation_name)

      {:error, _reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: [%{message: "Invalid JSON body"}]})
    end
  end

  defp execute_query(conn, query, variables, _operation_name \\ nil) do
    context = %{current_user: conn.assigns[:current_user]}

    case Absinthe.run(query, Schema, variables: variables, context: context) do
      {:ok, %{data: data, errors: []}} ->
        json(conn, %{data: data})

      {:ok, %{data: data, errors: errors}} when errors != [] ->
        formatted_errors = Enum.map(errors, &format_error/1)
        json(conn, %{data: data, errors: formatted_errors})

      {:ok, %{errors: errors}} when errors != [] ->
        formatted_errors = Enum.map(errors, &format_error/1)
        json(conn, %{errors: formatted_errors})

      {:error, %Absinthe.Schema.Error{} = error} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: [%{message: "Schema error: #{inspect(error)}"}]})

      {:error, error} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: [%{message: inspect(error)}]})
    end
  end

  defp format_error(%Absinthe.ResolutionError{message: message}) do
    %{message: message}
  end

  defp format_error(%{message: message} = error) do
    %{message: message, code: error[:code]}
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end

  defp format_error(error) do
    %{message: inspect(error)}
  end
end
