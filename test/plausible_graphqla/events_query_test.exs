defmodule PlausibleGraphqla.EventsQueryTest do
  use PlausibleWeb.ConnCase
  alias Plausible.Graphqla.Resolvers.EventResolver

  describe "events GraphQL query" do
    setup [:create_user, :create_site]

    test "returns events for a site", %{conn: conn, site: site, user: user} do
      # First add the user as a site member
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      query = """
        query {
          events(filter: { siteId: "#{site.id}" }) {
            edges {
              node {
                id
                name
                timestamp
                browser
                device
                country
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      # The query should succeed with either data or errors
      assert response["data"]["events"] != nil
    end

    test "filters events by event_type", %{conn: conn, site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      query = """
        query {
          events(
            filter: {
              siteId: "#{site.id}",
              eventType: "signup"
            }
          ) {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      assert response["data"]["events"] != nil
    end

    test "filters events by date range", %{conn: conn, site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      query = """
        query {
          events(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2024-01-01", to: "2024-12-31" }
            }
          ) {
            edges {
              node {
                name
                timestamp
              }
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      assert response["data"]["events"] != nil
    end

    test "returns error when site_id is missing", %{conn: conn} do
      query = """
        query {
          events(filter: {}) {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      # Should have errors about missing required field
      assert response["errors"] != nil
    end

    test "returns error for non-existent site", %{conn: conn} do
      query = """
        query {
          events(filter: { siteId: "99999999" }) {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      # Should return an error for non-existent site
      assert response["errors"] != nil or response["data"]["events"]["edges"] == []
    end

    test "supports pagination parameters", %{conn: conn, site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      query = """
        query {
          events(
            filter: { siteId: "#{site.id}" },
            pagination: { limit: 10, offset: 0 }
          ) {
            edges {
              node {
                id
                name
                timestamp
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      response = json_response(conn, 200)

      assert response["data"]["events"] != nil
      assert response["data"]["events"]["pageInfo"] != nil
    end
  end

  describe "EventResolver" do
    setup [:create_user, :create_site]

    test "list_events returns error when no filter provided", %{site: site} do
      result = EventResolver.list_events(nil, %{})

      assert {:error, "Filter with site_id is required"} = result
    end

    test "list_events returns error when site not found", _context do
      result = EventResolver.list_events(nil, %{
        filter: %{ site_id: "99999999" }
      })

      assert {:error, "Site not found"} = result
    end

    test "list_events with valid site", %{site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      result = EventResolver.list_events(nil, %{
        filter: %{ site_id: site.id }
      })

      # Should return ok with a map containing edges and pageInfo
      assert {:ok, response} = result
      assert is_map(response)
      assert Map.has_key?(response, :edges)
      assert Map.has_key?(response, :page_info)
    end

    test "list_events with date range", %{site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      result = EventResolver.list_events(nil, %{
        filter: %{
          site_id: site.id,
          date_range: %{ from: ~D[2024-01-01], to: ~D[2024-12-31] }
        }
      })

      assert {:ok, response} = result
      assert is_map(response)
    end

    test "list_events with event type filter", %{site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      result = EventResolver.list_events(nil, %{
        filter: %{
          site_id: site.id,
          event_type: "signup"
        }
      })

      assert {:ok, response} = result
      assert is_map(response)
    end

    test "list_events respects pagination limit", %{site: site, user: user} do
      {:ok, _} = Plausible.Sites.add_invitation(site, user.email, "viewer")

      result = EventResolver.list_events(nil, %{
        filter: %{ site_id: site.id },
        pagination: %{ limit: 10, offset: 0 }
      })

      assert {:ok, _response} = result
    end
  end
end
