defmodule PlausibleWeb.Plugs.RateLimitGraphQL do
  @moduledoc """
  Rate limiting plug for GraphQL endpoint.

  Limits requests to 100 per minute per API key.
  """

  import Plug.Conn
  alias PlausibleWeb.Endpoint.GraphQL

  @rate_limit 100
  @time_window :timer.minutes(1)

  def init(opts), do: opts

  def call(conn, _opts) do
    api_key = get_req_header(conn, "authorization")
              |> List.first()

    if api_key do
      check_rate_limit(conn, api_key)
    else
      conn
    end
  end

  defp check_rate_limit(conn, api_key) do
    key = "rate_limit:graphql:#{api_key}"

    case ExRated.check_rate(key, @rate_limit, @time_window) do
      {:ok, _count} ->
        conn

      {:error, _count} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:too_many_requests, Jason.encode!(%{error: "Rate limit exceeded. Maximum #{@rate_limit} requests per minute."}))
        |> halt()
    end
  end
end
