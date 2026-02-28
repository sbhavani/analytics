defmodule PlausibleWeb.Endpoint.GraphQL do
  @moduledoc """
  GraphQL endpoint plug.

  This module sets up the GraphQL endpoint with Absinthe
  and integrates with the existing authentication system.
  """

  use PlausibleWeb, :controller

  alias PlausibleWeb.Api.Helpers

  def init(opts), do: opts

  def call(conn, _opts) do
    # Get API key from headers
    api_key = get_req_header(conn, "authorization")
              |> List.first()
              |> Helpers.get_api_key()

    # Build context with authentication
    context = build_context(api_key)

    # Execute GraphQL query
    conn
    |> put_resp_content_type("application/json")
    |> Absinthe.Plug.run(schema: Plausible.GraphQL.Schema, context: context)
  end

  defp build_context(nil) do
    %{auth: %{}}
  end

  defp build_context(api_key) do
    case Plausible.Auth.lookup_api_key(api_key) do
      {:ok, key} ->
        # Get sites the API key has access to
        site_ids = Plausible.Site.list_for_key(key)
                   |> Enum.map(&(&1.id))

        %{
          auth: %{
            api_key: api_key,
            key: key
          },
          site_ids: site_ids
        }

      {:error, _} ->
        %{auth: %{}}
    end
  end
end
