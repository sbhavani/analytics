defmodule PlausibleWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting the GraphQL API endpoint.

  This plug uses the existing RateLimit module to enforce per-team
  rate limits for GraphQL queries. It checks both hourly limits
  and burst limits (shorter time windows).

  The plug expects `:current_team` to be present in conn.assigns
  after authentication.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Plausible.RateLimit

  require Logger

  @default_hourly_limit 600
  @default_burst_limit 60
  @default_burst_period_seconds 60

  def init(opts \\ []) do
    %{
      hourly_limit: Keyword.get(opts, :hourly_limit, @default_hourly_limit),
      burst_limit: Keyword.get(opts, :burst_limit, @default_burst_limit),
      burst_period: Keyword.get(opts, :burst_period, @default_burst_period_seconds) * 1000
    }
  end

  def call(conn, %{hourly_limit: hourly_limit, burst_limit: burst_limit, burst_period: burst_period}) do
    # Get the rate limit key from the team or API key
    limit_key = get_rate_limit_key(conn)

    if limit_key do
      with :ok <- check_hourly_rate_limit(limit_key, hourly_limit),
           :ok <- check_burst_rate_limit(limit_key, burst_limit, burst_period) do
        conn
      else
        {:error, :hourly_limit_exceeded, message} ->
          Logger.warning("[RateLimit] Hourly limit exceeded for key: #{limit_key}")
          send_rate_limit_error(conn, message)

        {:error, :burst_limit_exceeded, message} ->
          Logger.warning("[RateLimit] Burst limit exceeded for key: #{limit_key}")
          send_rate_limit_error(conn, message)
      end
    else
      # No rate limit key found - allow request but log warning
      Logger.warning("[RateLimit] No rate limit key found for request")
      conn
    end
  end

  defp get_rate_limit_key(conn) do
    cond do
      team = conn.assigns[:current_team] ->
        "graphql:team:#{team.identifier}"

      api_key = conn.assigns[:api_key] and api_key.id ->
        "graphql:api_key:#{api_key.id}"

      true ->
        nil
    end
  end

  defp check_hourly_rate_limit(limit_key, hourly_limit) do
    # 1 hour = 3600 * 1000 milliseconds
    case RateLimit.check_rate(limit_key, 3_600_000, hourly_limit) do
      {:allow, _count} ->
        :ok

      {:deny, _limit} ->
        {:error, :hourly_limit_exceeded,
         "Hourly rate limit exceeded. The limit is #{hourly_limit} requests per hour."}
    end
  end

  defp check_burst_rate_limit(limit_key, burst_limit, burst_period) do
    case RateLimit.check_rate("#{limit_key}:burst", burst_period, burst_limit) do
      {:allow, _count} ->
        :ok

      {:deny, _limit} ->
        {:error, :burst_limit_exceeded,
         "Too many requests in a short period. The limit is #{burst_limit} requests per minute."}
    end
  end

  defp send_rate_limit_error(conn, message) do
    conn
    |> put_status(429)
    |> json(%{errors: [%{message: message}]})
    |> halt()
  end
end
