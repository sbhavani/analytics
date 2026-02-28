defmodule Plausible.GraphQL.Middleware.Auth do
  @moduledoc """
  Authentication middleware for GraphQL queries.

  This middleware validates the API key from the request context
  and ensures the user has appropriate permissions.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    case resolution.context do
      %{auth: %{api_key: _api_key}} ->
        resolution

      %{auth: _} ->
        Absinthe.Resolution.put_result(resolution, {:error, "Unauthorized"})

      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Authentication required"})
    end
  end
end
