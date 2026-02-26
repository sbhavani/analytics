defmodule PlausibleWeb.Plugs.RateLimitGraphQL do
  @moduledoc """
  Rate limiting middleware for the GraphQL API.

  This plug provides rate limiting specifically for GraphQL API requests,
  working in conjunction with the existing authentication in AuthorizePublicAPI.
  It uses the team or user from the connection assigns to determine the rate limit key.

  Rate limiting is applied per team (for team-scoped API keys) or per user
  (for legacy API keys), with configurable limits for:
    - Hourly request limit
    - Burst limit (requests per short period)

  The plug uses separate rate limit keys from the REST API so GraphQL requests
  are tracked independently.

  The plug expects either `:current_team` or `:current_user` to be present
  in the connection assigns (set by the upstream AuthorizePublicAPI plug).
  """

  import Plug.Conn

  alias Plausible.RateLimit

  require Logger

  @hourly_limit_config_key :graphql_hourly_request_limit
  @burst_limit_config_key :graphql_burst_request_limit
  @burst_period_seconds_config_key :graphql_burst_period_seconds

  # Default limits - can be overridden in config
  @default_hourly_limit 600
  @default_burst_limit 60
  @default_burst_period_seconds 10

  def init(opts) do
    %{
      hourly_limit: Keyword.get(opts, :hourly_limit, default_hourly_limit()),
      burst_limit: Keyword.get(opts, :burst_limit, default_burst_limit()),
      burst_period_seconds: Keyword.get(opts, :burst_period_seconds, default_burst_period_seconds())
    }
  end

  def call(conn, opts) do
    with {:ok, limit_key, hourly_limit} <- get_rate_limit_params(conn),
         :ok <- check_hourly_rate_limit(limit_key, hourly_limit),
         :ok <- check_burst_rate_limit(limit_key, opts) do
      conn
    else
      {:error, :rate_limit_exceeded, message} ->
        send_rate_limit_error(conn, message)

      {:error, :no_rate_limit_key} ->
        # If we can't determine a rate limit key, allow the request
        # This handles cases where authentication hasn't been set up yet
        conn
    end
  end

  # Generate rate limit keys that are separate from the REST API
  defp get_rate_limit_params(conn) do
    cond do
      team = conn.assigns[:current_team] ->
        # Use a GraphQL-specific key: graphql:team:identifier
        {:ok, "graphql:team:#{team.identifier}", get_team_hourly_limit(team)}

      user = conn.assigns[:current_user] ->
        # Use a GraphQL-specific key: graphql:legacy_user:user_id
        {:ok, "graphql:legacy_user:#{user.id}", default_hourly_limit()}

      true ->
        {:error, :no_rate_limit_key}
    end
  end

  defp get_team_hourly_limit(team) do
    # Use team's configured hourly limit if available, otherwise use default
    team.hourly_api_request_limit || default_hourly_limit()
  end

  defp check_hourly_rate_limit(limit_key, hourly_limit) do
    case RateLimit.check_rate(limit_key, to_timeout(hour: 1), hourly_limit) do
      {:allow, _} ->
        :ok

      {:deny, _} ->
        {:error, :rate_limit_exceeded,
         "Too many GraphQL API requests. The limit is #{hourly_limit} per hour. Please contact us to request more capacity."}
    end
  end

  defp check_burst_rate_limit(limit_key, opts) do
    burst_period_seconds = opts.burst_period_seconds
    burst_request_limit = opts.burst_limit

    case RateLimit.check_rate(
           limit_key,
           to_timeout(second: burst_period_seconds),
           burst_request_limit
         ) do
      {:allow, _} ->
        :ok

      {:deny, _} ->
        {:error, :rate_limit_exceeded,
         "Too many GraphQL API requests in a short period of time. The limit is #{burst_request_limit} per #{burst_period_seconds} seconds. Please throttle your requests."}
    end
  end

  defp send_rate_limit_error(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(429, Jason.encode!(%{errors: [%{message: message}]}))
    |> halt()
  end

  defp to_timeout(seconds: seconds), do: seconds * 1000
  defp to_timeout(hour: 1), do: 60 * 60 * 1000

  # Config helpers with fallback to defaults
  defp default_hourly_limit do
    Application.get_env(:plausible, @hourly_limit_config_key, @default_hourly_limit)
  end

  defp default_burst_limit do
    Application.get_env(:plausible, @burst_limit_config_key, @default_burst_limit)
  end

  defp default_burst_period_seconds do
    Application.get_env(:plausible, @burst_period_seconds_config_key, @default_burst_period_seconds)
  end
end
