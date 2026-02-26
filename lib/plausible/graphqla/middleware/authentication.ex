defmodule Plausible.Graphqla.Middleware.Authentication do
  @moduledoc """
  GraphQL authentication middleware using existing Plausible auth
  """
  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    case resolution.context do
      %{current_user: _user} ->
        resolution

      _ ->
        %{resolution |
          errors: [ %{message: "UNAUTHENTICATED: Missing or invalid authentication"} ]
        }
    end
  end
end
