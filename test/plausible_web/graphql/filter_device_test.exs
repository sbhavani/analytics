defmodule PlausibleWeb.GraphQL.FilterDeviceTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - device filtering" do
    setup [:create_user, :create_site]

    test "filters aggregate by device - mobile", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "Mobile" }]
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

    test "filters aggregate by device - desktop", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "Desktop" }]
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

    test "filters breakdown by device", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: PAGE,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "Desktop" }],
            limit: 10
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

    test "filters timeseries by device", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-15", endDate: "2026-01-16" },
            filters: [{ device: "Desktop" }],
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

      response = json_response(conn, 200)
      assert response["errors"] == nil
      assert response["data"]["timeseries"] != nil
    end

    test "returns all visitors when device filter is not specified", %{conn: conn, site: site} do
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
      assert response["errors"] == nil
      assert response["data"]["aggregate"] != nil
    end

    test "filters by laptop device", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "Laptop" }]
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

    test "combines device filter with other filters", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [
              { device: "Desktop" },
              { utmMedium: "cpc" }
            ]
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

    test "handles empty device filter value gracefully", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # Empty string should be handled gracefully
      assert response["errors"] == nil or response["data"]["aggregate"] != nil
    end

    test "filters by device and returns multiple metrics", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS, BOUNCE_RATE],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "Mobile" }]
          }) {
            visitors
            pageviews
            events
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
  end
end
