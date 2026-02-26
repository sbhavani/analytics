defmodule PlausibleWeb.GraphQL.Context do
  @moduledoc """
  GraphQL context for authentication and authorization.

  This module provides the context for GraphQL queries, including
  user authentication and site authorization.
  """

  alias Plausible.Auth
  alias Plausible.Sites

  alias PlausibleWeb.GraphQL.Logger, as: GQLLogger

  @doc """
  Build the GraphQL context from connection.
  """
  def build_context(conn) do
    # Try to get user from session
    user = PlausibleWeb.AuthPlug.get_user(conn)

    # If no session user, try API key
    {user, auth_method} = if user do
      {user, :session}
    else
      case get_api_key(conn) do
        nil ->
          {nil, nil}

        api_key ->
          {Auth.find_api_key(api_key), :api_key}
      end
    end

    context = %{
      user: user,
      site: nil,
      conn: conn
    }

    # Log context build (structured logging per T044)
    GQLLogger.log_context_build(context, auth_method)

    context
  end

  defp get_api_key_user(conn) do
    case get_api_key(conn) do
      nil ->
        nil

      api_key ->
        Auth.find_api_key(api_key)
    end
  end

  defp get_api_key(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> key] -> key
      _ -> nil
    end
  end

  @doc """
  Authorize access to a site for the current user.
  """
  def authorize_site(%{user: user}, site_id) when is_binary(site_id) do
    case Sites.get_by_domain(site_id) do
      nil ->
        # Log unauthorized attempt for site not found
        GQLLogger.log_authorization(get_user_id(user), site_id, false)
        {:error, :site_not_found}

      site ->
        authorized = Sites.is_member?(user, site)
        GQLLogger.log_authorization(get_user_id(user), site_id, authorized)

        if authorized do
          {:ok, site}
        else
          {:error, :unauthorized}
        end
    end
  end

  def authorize_site(_, _), do: {:error, :invalid_site_id}

  defp get_user_id(user) do
    case user do
      nil -> nil
      _ -> Map.get(user, :id) || Map.get(user, :email) || "unknown"
    end
  end
end
