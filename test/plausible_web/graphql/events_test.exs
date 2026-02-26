defmodule PlausibleWeb.GraphQL.EventsTest do
  use PlausibleWeb.ConnCase, async: true

  setup [:create_user, :create_site]

  describe "events query" do
    test "returns authentication error without session", %{conn: conn, site: site} do
      query = """
        query {
          events(filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } }) {
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

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(conn, 200)
    end

    test "returns empty results for authenticated user", %{conn: conn, user: user, site: site} do
      query = """
        query {
          events(filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } }) {
            edges {
              node {
                name
                timestamp
              }
            }
            pageInfo {
              totalCount
              hasNextPage
            }
          }
        }
      """

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => %{"edges" => [], "pageInfo" => %{"totalCount" => 0}}}} = json_response(conn, 200)
    end

    test "accepts event name filter", %{conn: conn, user: user, site: site} do
      query = """
        query {
          events(
            filter: {
              dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
              eventName: "button_click"
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
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => %{"edges" => []}}} = json_response(conn, 200)
    end

    test "accepts property filters", %{conn: conn, user: user, site: site} do
      query = """
        query {
          events(
            filter: {
              dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
              propertyName: "category",
              propertyValue: "pricing"
            }
          ) {
            edges {
              node {
                name
                properties
              }
            }
          }
        }
      """

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => %{"edges" => []}}} = json_response(conn, 200)
    end
  end
end
