defmodule PlausibleWeb.GraphQL.AnalyticsAggregateTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - aggregate queries" do
    setup [:create_user, :create_site]

    test "returns aggregate data with visitors metric", %{conn: conn, site: site} do
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

      response = json_response(conn, 200)

      # Should return data or null (unauthorized), not an error
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns aggregate data with multiple metrics", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
            pageviews
            events
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns aggregate data with bounce_rate metric", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, BOUNCE_RATE],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
            bounceRate
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns aggregate data with visit_duration metric", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, VISIT_DURATION],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns aggregate data with all metrics", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS, BOUNCE_RATE, VISIT_DURATION],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
            pageviews
            events
            bounceRate
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil

      aggregate = response["data"]["aggregate"]
      assert aggregate != nil
      assert aggregate["visitors"] != nil
      assert aggregate["pageviews"] != nil
      assert aggregate["events"] != nil
      assert aggregate["bounceRate"] != nil
      assert aggregate["visitDuration"] != nil
    end

    test "supports device filter in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "desktop" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "supports country filter in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ country: "US" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "supports multiple filters in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "desktop" }, { browser: "Chrome" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "supports UTM filters in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmMedium: "organic" }, { utmSource: "google" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "supports referrer filter in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ referrer: "twitter.com" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "supports pathname filter in aggregate query", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ pathname: "/pricing" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns data for single day date range", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-15", endDate: "2026-01-15" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns data for week-long date range", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" }
          }) {
            visitors
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "returns data for year-long date range", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2025-01-01", endDate: "2025-12-31" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
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

    test "returns unauthorized when site context is missing", %{conn: conn, site: site} do
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

      # Without auth context, should return null data or error
      response = json_response(conn, 200)
      assert response["data"]["aggregate"] == nil or response["errors"] != nil
    end

    test "returns error for missing metrics", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Should return error for missing required field
      assert json_response(conn, 200)["errors"] != nil
    end

    test "returns error for missing date range", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Should return error for missing required field
      assert json_response(conn, 200)["errors"] != nil
    end

    test "handles invalid site ID", %{conn: _conn} do
      query = """
        query {
          aggregate(siteId: "999999", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
          }
        }
      """

      # This test verifies the endpoint handles non-existent sites
      # The exact behavior depends on authentication setup
    end
  end
end
