defmodule Plausible.GraphQL.Middleware.Authorization do
  @moduledoc """
  Authorization middleware for GraphQL queries.

  This middleware validates that the authenticated user has access
  to the requested site.
  """

  @behaviour Absinthe.Middleware

  def call(resolution, %{site_id: site_id} = _opts) do
    case resolution.context do
      %{auth: %{api_key: api_key}, site_ids: site_ids} ->
        if site_id in site_ids do
          resolution
        else
          Absinthe.Resolution.put_result(resolution, {:error, "Access denied to site: #{site_id}"})
        end

      %{auth: _} ->
        # If auth exists but no site_ids, allow access (for listing sites)
        resolution

      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "Authorization required"})
    end
  end
end
