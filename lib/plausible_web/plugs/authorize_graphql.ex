defmodule PlausibleWeb.Plugs.AuthorizeGraphQL do
  @moduledoc """
  Plug to authorize GraphQL API requests and enforce rate limiting.
  """

  import Plug.Conn

  alias Plausible.RateLimit

  # 100 requests per minute as per the constraint in plan.md
  @rate_limit_scale 60_000
  @rate_limit_max 100

  def init(opts), do: opts

  def call(conn, _opts) do
    # Check rate limit first
    case check_rate_limit(conn) do
      :ok ->
        # Check for API key or session-based authentication
        cond do
          # API key authentication
          api_key = get_req_header(conn, "authorization") |> parse_api_key() ->
            assign(conn, :api_key, api_key)

          # Session-based authentication
          user = get_session(conn, :current_user) ->
            assign(conn, :current_user, user)

          # No authentication
          true ->
            conn
        end

      {:error, message} ->
        conn
        |> put_status(:too_many_requests)
        |> Phoenix.Controller.json(%{errors: [%{message: message}]})
        |> halt()
    end
  end

  defp check_rate_limit(conn) do
    key = get_rate_limit_key(conn)

    case RateLimit.check_rate(key, @rate_limit_scale, @rate_limit_max) do
      {:allow, _count} ->
        :ok

      {:deny, _limit} ->
        {:error, "Rate limit exceeded. The limit is #{@rate_limit_max} requests per minute."}
    end
  end

  defp get_rate_limit_key(conn) do
    # Priority: API key > user > IP address
    cond do
      api_key = get_req_header(conn, "authorization") |> parse_api_key() ->
        {"graphql:api_key", api_key}

      user = get_session(conn, :current_user) ->
        {"graphql:user", user.id}

      true ->
        ip = get_remote_ip(conn)
        {"graphql:ip", ip}
    end
  end

  defp get_remote_ip(conn) do
    forwarded_for = get_req_header(conn, "x-forwarded-for") |> List.first()

    if forwarded_for do
      String.split(forwarded_for, ",") |> List.first() |> String.trim()
    else
      to_string(:inet.ntoa(conn.remote_ip))
    end
  end

  defp parse_api_key(["Bearer " <> key]), do: key
  defp parse_api_key([key]), do: key
  defp parse_api_key(_), do: nil
end
