defmodule PlausibleWeb.Api.GraphQLControllerTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql" do
    setup [:create_user, :create_site]

    test "returns error for missing query", %{conn: conn, site: site} do
      conn =
        conn
        |> post("/api/graphql", %{})

      assert %{"errors" => [%{"message" => "Missing query parameter"}]} = json_response(conn, :bad_request)
    end

    test "returns error for unauthorized request", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Without auth, should either return unauthorized or empty data
      response = json_response(conn, 200)
      assert response["data"]["aggregate"] == nil or response["errors"] != nil
    end

    test "validates date range exceeds 1 year", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-01-01", endDate: "2026-01-01" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Date range too large - should return error
      assert json_response(conn, 200)["errors"] != nil
    end

    test "validates invalid date range (start > end)", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-31", endDate: "2026-01-01" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["errors"] != nil
    end

    test "validates breakdown limit", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 5000
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Limit too high - should return error
      assert json_response(conn, 200)["errors"] != nil
    end
  end
end
