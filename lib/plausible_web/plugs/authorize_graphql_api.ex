defmodule PlausibleWeb.Plugs.AuthorizeGraphQLAPI do
  @moduledoc """
  Plug for authorizing GraphQL API requests.

  This plug validates the API key from the Authorization header
  and assigns the current user and site to the connection.
  """

  use Plausible.Repo

  import Plug.Conn

  alias Plausible.Auth
  alias Plausible.RateLimit

  require Logger

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with {:ok, token} <- get_bearer_token(conn),
         {:ok, api_key} <- find_api_key(token),
         :ok <- check_rate_limit(api_key) do
      site = find_site(conn.params["site_id"])

      conn
      |> assign(:current_user, api_key.user)
      |> assign(:current_api_key, api_key)
      |> assign(:site, site)
    else
      error -> send_error(conn, error)
    end
  end

  defp get_bearer_token(conn) do
    authorization_header =
      conn
      |> Plug.Conn.get_req_header("authorization")
      |> List.first()

    case authorization_header do
      "Bearer " <> token -> {:ok, String.trim(token)}
      _ -> {:error, :missing_api_key}
    end
  end

  defp find_api_key(token) do
    case Auth.find_api_key(token) do
      {:ok, %{api_key: api_key, team: _team}} ->
        {:ok, api_key}

      {:error, _} = error ->
        error
    end
  end

  defp find_site(nil), do: nil

  defp find_site(site_id) do
    domain_based_search =
      from s in Plausible.Site,
        where: s.domain == ^site_id or s.domain_changed_from == ^site_id

    Repo.one(domain_based_search)
  end

  defp check_rate_limit(api_key) do
    limit_key = Auth.ApiKey.legacy_limit_key(api_key.user)
    hourly_limit = Auth.ApiKey.legacy_hourly_request_limit()

    case RateLimit.check_rate(limit_key, to_timeout(hour: 1), hourly_limit) do
      {:allow, _} ->
        :ok

      {:deny, _} ->
        {:error, :rate_limit}
    end
  end

  defp send_error(conn, {:error, :missing_api_key}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: [%{message: "Missing API key. Please use a valid Plausible API key as a Bearer Token."}]})
    |> halt()
  end

  defp send_error(conn, {:error, :invalid_api_key}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: [%{message: "Invalid API key. Please make sure you're using a valid API key."}]})
    |> halt()
  end

  defp send_error(conn, {:error, :rate_limit}) do
    conn
    |> put_status(:too_many_requests)
    |> json(%{errors: [%{message: "Too many API requests. Please try again later."}]})
    |> halt()
  end
end
