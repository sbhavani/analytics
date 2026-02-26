defmodule PlausibleWeb.GraphQLController do
  @moduledoc """
  Controller for GraphQL API
  """
  use Plausible
  use PlausibleWeb, :controller

  alias PlausibleWeb.GraphQL.Schema

  # Rate limiting configuration for GraphQL API
  @graphql_rate_limit_scale 60_000  # 1 minute
  @graphql_rate_limit_max 100  # 100 requests per minute

  plug :put_view, json: PlausibleWeb.JSONView

  # Rate limiting plug
  plug :check_rate_limit when action in [:execute]

  defp check_rate_limit(conn, _opts) do
    # Check rate limit based on user or IP
    limit_key = case conn.assigns[:current_user] do
      nil -> "graphql:ip:#{PlausibleWeb.RemoteIp.get(conn)}"
      user -> "graphql:user:#{user.id}"
    end

    case Plausible.RateLimit.check_rate(
           Plausible.RateLimit,
           limit_key,
           @graphql_rate_limit_scale,
           @graphql_rate_limit_max
         ) do
      {:allow, _} ->
        conn

      {:deny, _} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{errors: [%{message: "Too many requests. Rate limit: #{@graphql_rate_limit_max} per minute"}]})
        |> halt()
    end
  end

  def execute(conn, %{}) do
    conn = %{conn | body_params: Map.put(conn.body_params, "operationName", Map.get(conn.body_params, "operationName"))}

    case Absinthe.Plug.execute(conn, schema: Schema, analyze_complexity: true, max_complexity: 250) do
      %{assigns: %{absinthe: %{result: result}}, private: %{phoenix_format: "json"}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(result))

      %{assigns: %{absinthe: %{result: _result}}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, ~s({"errors": [{"message": "Only JSON format supported"}]}))

      {:error, conn, %{message: message}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: [%{message: message}]}))
    end
  end

  # Handle POST with query in body
  def execute(conn, %{"query" => query} = params) do
    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operationName")

    start_time = System.monotonic_time(:millisecond)

    result = Absinthe.run(query, Schema,
      variables: variables,
      operation_name: operation_name,
      context: build_context(conn)
    )

    execution_time = System.monotonic_time(:millisecond) - start_time

    # Log performance metrics
    Plausible.Logger.info("GraphQL query executed in #{execution_time}ms")

    case result do
      {:ok, %{data: data, errors: nil}} ->
        json(conn, %{data: data})

      {:ok, %{data: data, errors: errors}} when is_list(errors) and errors != [] ->
        json(conn, %{data: data, errors: errors})

      {:error, %{message: message}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: [%{message: message}]})
    end
  end

  # Handle GET requests
  def execute(conn, %{"query" => query} = params) do
    variables = Map.get(params, "variables", %{})
    operation_name = Map.get(params, "operationName")

    result = Absinthe.run(query, Schema,
      variables: variables,
      operation_name: operation_name,
      context: build_context(conn)
    )

    case result do
      {:ok, %{data: data, errors: nil}} ->
        json(conn, %{data: data})

      {:ok, %{data: data, errors: errors}} when is_list(errors) and errors != [] ->
        json(conn, %{data: data, errors: errors})

      {:error, %{message: message}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: [%{message: message}]})
    end
  end

  def execute(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: [%{message: "Invalid request. Expected query parameter"}]})
  end

  defp build_context(conn) do
    current_user = Map.get(conn.assigns, :current_user)

    %{
      current_user: current_user,
      site: Map.get(conn.assigns, :site),
      remote_ip: PlausibleWeb.RemoteIp.get(conn)
    }
  end
end
