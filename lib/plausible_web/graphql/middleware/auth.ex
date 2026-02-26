defmodule PlausibleWeb.GraphQL.Middleware.Auth do
  @moduledoc """
  Authentication middleware for GraphQL
  """
  use Plausible

  def call(resolution, _opts) do
    case resolution.context do
      %{current_user: _user} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_error(%{
          message: "Authentication required",
          code: "UNAUTHENTICATED",
          locations: [{:line, 1, :column}],
          path: resolution.path
        })
    end
  end
end
