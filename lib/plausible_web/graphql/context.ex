defmodule PlausibleWeb.GraphQL.Context do
  @moduledoc """
  GraphQL context for authentication and request context
  """

  alias Plausible.Auth
  alias Plausible.Sites

  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, api_key} <- Auth.find_api_key(token),
         :ok <- Auth.ensure_api_key_not_expired(api_key),
         {:ok, site} <- Sites.get_site(api_key.site_id) do
      %{api_key: api_key, site: site, user: api_key.user}
    else
      _ -> %{}
    end
  end

  def authorize_site_access(%{site: site}, info) do
    case info do
      %{site: %{id: site_id}} when site_id == site.id -> :ok
      _ -> {:error, :unauthorized}
    end
  end

  def authorize_site_access(_, _), do: {:error, :unauthorized}
end
