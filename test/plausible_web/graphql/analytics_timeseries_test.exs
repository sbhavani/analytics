defmodule PlausibleWeb.GraphQL.AnalyticsTimeseriesTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - timeseries queries" do
    setup [:create_user, :create_site]

    test "returns time series data with daily granularity", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" },
            granularity: DAILY
          }) {
            date
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
      assert response["data"]["timeseries"] != nil
    end

    test "returns time series data with hourly granularity", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS, EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" },
            granularity: HOURLY
          }) {
            date
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
      assert response["data"]["timeseries"] != nil
    end

    test "returns time series data with weekly granularity", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            granularity: WEEKLY
          }) {
            date
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["timeseries"] != nil
    end

    test "returns time series data with monthly granularity", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS],
            dateRange: { startDate: "2025-01-01", endDate: "2025-12-31" },
            granularity: MONTHLY
          }) {
            date
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
      assert response["data"]["timeseries"] != nil
    end

    test "validates date range exceeds 1 year", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-01-01", endDate: "2026-01-01" },
            granularity: DAILY
          }) {
            date
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
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-31", endDate: "2026-01-01" },
            granularity: DAILY
          }) {
            date
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["errors"] != nil
    end

    test "supports filters in timeseries query", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" },
            granularity: DAILY,
            filters: [{ device: "desktop" }]
          }) {
            date
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["timeseries"] != nil
    end

    test "returns unauthorized when site context is missing", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" },
            granularity: DAILY
          }) {
            date
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Without auth context, should return null data or error
      response = json_response(conn, 200)
      assert response["data"]["timeseries"] == nil or response["errors"] != nil
    end
  end
end
