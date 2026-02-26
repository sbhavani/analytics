defmodule PlausibleWeb.GraphqlController do
  @moduledoc """
  Controller for GraphQL API endpoint
  """
  use PlausibleWeb, :controller
  alias Plausible.Graphqla.Schema

  require Logger
  plug :put_view, json: PlausibleWeb.JSONView

  # Maximum allowed query complexity
  @max_complexity 1000

  def execute(conn, %{ "query" => query, "variables" => variables }) do
    start_time = System.monotonic_time(:millisecond)
    context = %{ current_user: conn.assigns[:current_user] }

    # Log the GraphQL query
    Logger.info("graphql_query",
      query: String.slice(query, 0, 200),
      user_id: context.current_user && context.current_user.id,
      ip: Enum.join(Tuple.to_list(conn.remote_ip), ".")
    )

    result = Absinthe.run(query, Schema,
      variables: variables,
      context: context,
      max_complexity: @max_complexity
    )

    # Log query duration
    duration = System.monotonic_time(:millisecond) - start_time
    Logger.info("graphql_query_complete", duration_ms: duration)

    case result do
      {:ok, %{data: data, errors: []}} ->
        conn
        |> put_status(:ok)
        |> json(%{data: data})

      {:ok, %{data: data, errors: errors}} when errors != [] ->
        formatted_errors = format_errors(errors)
        conn
        |> put_status(:ok)
        |> json(%{data: data, errors: formatted_errors})

      {:error, %{errors: errors}} ->
        formatted_errors = format_errors(errors)
        conn
        |> put_status(:bad_request)
        |> json(%{errors: formatted_errors})
    end
  end

  def execute(conn, %{ "query" => query }) do
    execute(conn, %{ "query" => query, "variables" => %{}})
  end

  def execute(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: [%{message: "Invalid GraphQL request - query required"}]})
  end

  defp format_errors(errors) when is_list(errors) do
    Enum.map(errors, &format_error/1)
  end

  defp format_error(%{message: message, path: path}) do
    %{
      message: message,
      path: path || []
    }
  end

  defp format_error(error) when is_binary(error) do
    %{message: error}
  end

  defp format_error(error) do
    %{message: inspect(error)}
  end
end
