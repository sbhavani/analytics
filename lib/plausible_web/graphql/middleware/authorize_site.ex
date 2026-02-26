defmodule PlausibleWeb.GraphQL.Middleware.AuthorizeSite do
  @moduledoc """
  GraphQL middleware for site authorization.
  Ensures the user has access to the requested site.
  """

  alias Plausible.Sites

  @behaviour Absinthe.Middleware

  def call(resolution, _opts) do
    site_id = get_site_id(resolution)

    case authorize_site_access(resolution.context.current_user, site_id) do
      :ok ->
        resolution

      {:error, :not_found} ->
        resolution
        |> Absinthe.Resolution.put_error(%{
          message: "Site not found",
          extensions: %{code: "NOT_FOUND", field: "siteId"}
        })
        |> Map.put(:halted, true)

      {:error, :forbidden} ->
        resolution
        |> Absinthe.Resolution.put_error(%{
          message: "You do not have access to this site",
          extensions: %{code: "FORBIDDEN", field: "siteId"}
        })
        |> Map.put(:halted, true)
    end
  end

  defp get_site_id(resolution) do
    # Extract site_id from arguments
    case resolution.arguments do
      %{site_id: site_id} -> site_id
      %{siteId: site_id} -> site_id
      _ -> nil
    end
  end

  defp authorize_site_access(nil, _), do: {:error, :forbidden}

  defp authorize_site_access(user, site_id) when is_binary(site_id) do
    case Sites.get_by_id(site_id, user) do
      nil -> {:error, :not_found}
      _site -> :ok
    end
  end

  defp authorize_site_access(_user, _), do: {:error, :not_found}
end
