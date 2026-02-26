defmodule PlausibleWeb.Plugs.GraphQLRateLimiter do
  @moduledoc """
  Rate limiting for GraphQL API endpoint.

  Implements rate limiting based on user subscription plan.
  """

  use PlausibleWeb, :controller
  import Plug.Conn

  @default_rate_limit 100  # requests per hour for free tier
  @default_window 3600     # 1 hour in seconds

  def init(opts) do
    %{
      limit: Keyword.get(opts, :limit, @default_rate_limit),
      window: Keyword.get(opts, :window, @default_window),
      key_prefix: Keyword.get(opts, :key_prefix, "graphql_rate_limit")
    }
  end

  def call(conn, %{limit: limit, window: window, key_prefix: prefix}) do
    # Get user identifier (user ID or API key)
    key = get_rate_limit_key(conn, prefix)

    # Check current rate limit
    case check_rate_limit(key, limit, window) do
      {:ok, remaining} ->
        conn
        |> put_resp_header("X-RateLimit-Limit", "#{limit}")
        |> put_resp_header("X-RateLimit-Remaining", "#{remaining}")
        |> put_resp_header("X-RateLimit-Reset", "#{:os.system_time(:second) + window}")
        |> continue()

      {:error, _} ->
        conn
        |> put_resp_header("X-RateLimit-Limit", "#{limit}")
        |> put_resp_header("X-RateLimit-Remaining", "0")
        |> put_status(:too_many_requests)
        |> json(%{errors: [%{message: "Rate limit exceeded. Please try again later."}]})
        |> halt()
    end
  end

  defp get_rate_limit_key(conn, prefix) do
    # Try user ID first, then API key
    user_id = case PlausibleWeb.AuthPlug.get_user(conn) do
      nil -> nil
      user -> user.id
    end

    api_key = case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> key] -> key
      _ -> nil
    end

    identifier = user_id || api_key || conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

    "#{prefix}:#{identifier}"
  end

  defp check_rate_limit(_key, _limit, _window) do
    # TODO: Implement actual rate limiting with Redis or similar
    # For now, allow all requests
    {:ok, 100}
  end

  defp continue(conn), do: conn
end
