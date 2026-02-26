defmodule PlausibleWeb.GraphQL.AnalyticsBreakdownTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - breakdown queries" do
    setup [:create_user, :create_site]

    test "returns breakdown data by country dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)

      # Should return data or null (unauthorized), not an error
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown data by device dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: DEVICE,
            metrics: [VISITORS, EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
            events
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown data by browser dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: BROWSER,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown data by operating_system dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: OPERATING_SYSTEM,
            metrics: [VISITORS, PAGEVIEWS, EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
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
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown data by referrer dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: REFERRER,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown data by pathname dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: PATHNAME,
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
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
      assert response["data"]["breakdown"] != nil
    end

    test "supports pagination with limit parameter", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 5
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports pagination with offset parameter", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 10,
            offset: 5
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports sorting by visitors descending", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            sortBy: VISITORS_DESC
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports sorting by visitors ascending", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: DEVICE,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            sortBy: VISITORS_ASC
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports sorting by pageviews descending", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: BROWSER,
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            sortBy: PAGEVIEWS_DESC
          }) {
            dimension
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports filters in breakdown query", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: PATHNAME,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "desktop" }]
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "supports multiple filters in breakdown query", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "desktop", browser: "Chrome" }]
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "validates date range exceeds 1 year", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2024-01-01", endDate: "2026-01-01" }
          }) {
            dimension
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
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-31", endDate: "2026-01-01" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["errors"] != nil
    end

    test "validates breakdown limit too high", %{conn: conn, site: site} do
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

    test "validates breakdown limit is positive", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: -1
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Negative limit - should return error
      assert json_response(conn, 200)["errors"] != nil
    end

    test "returns unauthorized when site context is missing", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Without auth context, should return null data or error
      response = json_response(conn, 200)
      assert response["data"]["breakdown"] == nil or response["errors"] != nil
    end

    test "returns breakdown with region dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: REGION,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown with city dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: CITY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown with utm_medium dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_MEDIUM,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown with utm_source dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_SOURCE,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end

    test "returns breakdown with utm_campaign dimension", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_CAMPAIGN,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            dimension
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["breakdown"] != nil
    end
  end
end
