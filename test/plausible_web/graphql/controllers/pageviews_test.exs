defmodule PlausibleWeb.GraphQL.Controllers.PageviewsTest do
  @moduledoc """
  Integration tests for the pageviews GraphQL endpoint.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory

  describe "pageviews GraphQL query" do
    test "returns pageview data for authenticated user", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      # Build GraphQL query
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
            visitors
          }
        }
      """

      # Authenticate and make request
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      # Assert response
      assert %{
        "data" => %{
          "pageviews" => [%{"count" => _, "visitors" => _}]
        }
      } = json_response(conn, 200)
    end

    test "returns aggregated pageviews grouped by path", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, groupBy: PATH }
          ) {
            count
            visitors
            group
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "data" => %{
          "pageviews" => pageviews
        }
      } = json_response(conn, 200)

      assert is_list(pageviews)
    end

    test "filters pageviews by path", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            filters: { path: "/blog/*" }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "returns unauthorized for unauthenticated user", %{conn: conn} do
      site = Factory.insert(:site)

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "errors" => [%{"message" => "Authentication required"}]
      } = json_response(conn, 200)
    end

    test "returns error for invalid date range", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-31", to: "2026-01-01" }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "errors" => [%{"message" => message}]
      } = json_response(conn, 200)

      assert String.contains?(message, "date range")
    end
  end
end
