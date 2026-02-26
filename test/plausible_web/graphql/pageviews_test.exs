defmodule PlausibleWeb.GraphQL.PageviewsTest do
  use PlausibleWeb.ConnCase, async: true
  alias Plausible.ClickhouseEventV2

  setup [:create_user, :create_site]

  describe "pageviews query" do
    test "returns authentication error without session", %{conn: conn, site: site} do
      query = """
        query {
          pageviews(filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } }) {
            edges {
              node {
                url
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
          pageviews(filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } }) {
            edges {
              node {
                url
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

      assert %{"data" => %{"pageviews" => %{"edges" => [], "pageInfo" => %{"totalCount" => 0}}}} = json_response(conn, 200)
    end

    test "accepts pagination parameters", %{conn: conn, user: user, site: site} do
      query = """
        query {
          pageviews(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            pagination: { limit: 10, offset: 0 }
          ) {
            edges {
              node {
                url
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

      assert %{"data" => %{"pageviews" => %{"edges" => []}}} = json_response(conn, 200)
    end

    test "accepts sort parameters", %{conn: conn, user: user, site: site} do
      query = """
        query {
          pageviews(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            sort: { field: "timestamp", order: DESC }
          ) {
            edges {
              node {
                url
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

      assert %{"data" => %{"pageviews" => %{"edges" => []}}} = json_response(conn, 200)
    end

    test "accepts date range filter", %{conn: conn, user: user, site: site} do
      query = """
        query {
          pageviews(
            filter: {
              dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
              browser: "Chrome"
            }
          ) {
            edges {
              node {
                browser
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

      assert %{"data" => %{"pageviews" => %{"edges" => []}}} = json_response(conn, 200)
    end
  end
end
