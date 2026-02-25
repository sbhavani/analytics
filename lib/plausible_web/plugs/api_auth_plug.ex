defmodule PlausibleWeb.Plugs.APIAuth do
  @moduledoc """
  Plug for authorizing access to the GraphQL Analytics API.

  This plug uses the existing AuthorizePublicAPI plug with the stats:read scope
  to authenticate API key bearer tokens. It also extracts and validates the site_id
  from GraphQL query variables.
  """

  use PlausibleWeb, :controller

  alias PlausibleWeb.Plugs.AuthorizePublicAPI

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # Extract site_id from GraphQL variables if present
    site_id = get_site_id_from_request(conn)

    conn =
      if site_id do
        Map.put(conn, :params, Map.put(conn.params, "site_id", site_id))
      else
        conn
      end

    # Set the required scope for GraphQL API
    conn = assign(conn, :api_scope, "stats:read:*")
    conn = assign(conn, :api_context, :site)

    # Delegate to the existing authorization plug
    AuthorizePublicAPI.call(conn, [])
  end

  defp get_site_id_from_request(conn) do
    case conn.body_params do
      %{"variables" => %{"siteId" => site_id}} when is_binary(site_id) ->
        site_id

      %{"variables" => %{"site_id" => site_id}} when is_binary(site_id) ->
        site_id

      _ ->
        nil
    end
  end
end
