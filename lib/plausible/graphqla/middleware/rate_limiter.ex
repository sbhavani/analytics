defmodule Plausible.Graphqla.Middleware.RateLimiter do
  @moduledoc """
  Rate limiting middleware for GraphQL API
  """
  @behaviour Absinthe.Middleware

  @rate_limit 100 # requests per minute

  def call(resolution, _opts) do
    user_id = get_user_id(resolution)

    if user_id do
      case check_rate_limit(user_id) do
        :ok ->
          resolution

        {:error, :rate_limited} ->
          %{resolution |
            errors: [ %{message: "RATE_LIMITED: Too many requests. Max #{@rate_limit} per minute"} ]
          }
      end
    else
      resolution
    end
  end

  defp get_user_id(resolution) do
    case resolution.context do
      %{current_user: user} when user != nil -> user.id
      _ -> nil
    end
  end

  # In production, this would use a proper rate limiting solution
  # like Redis or ETS-based rate limiting
  defp check_rate_limit(_user_id) do
    # Simplified rate limiting - in production use:
    # - Redis-based rate limiting with sliding window
    # - Or ETS-based in-memory rate limiting
    :ok
  end
end
