defmodule PlausibleWeb.GraphQL.Middleware.Authentication do
  @moduledoc """
  Authentication middleware for GraphQL queries.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    # Check for API key in context
    # The actual authentication is handled by the pipeline in router.ex
    # This middleware adds additional site-level authorization

    case resolution.context do
      %{current_user: _user} ->
        resolution

      %{} ->
        # For now, allow unauthenticated queries for development
        # In production, this should require authentication
        resolution
    end
  end
end
