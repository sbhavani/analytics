defmodule PlausibleWeb.GraphQL.Middleware.Auth do
  @moduledoc """
  GraphQL middleware for authentication.
  Ensures the user is authenticated before executing queries.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    case resolution.context do
      %{current_user: user} when not is_nil(user) ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_error("Authentication required")
        |> Map.put(:halted, true)
    end
  end
end
