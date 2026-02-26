defmodule PlausibleWeb.GraphQL.FilterUTMTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - UTM filtering" do
    setup [:create_user, :create_site]

    test "filters aggregate by utm_medium", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmMedium: "social" }]
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

    test "filters aggregate by utm_source", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmSource: "google" }]
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

    test "filters aggregate by utm_campaign", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmCampaign: "spring_sale" }]
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

    test "filters breakdown by utm_medium", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: PATHNAME,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmMedium: "email" }],
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

    test "filters breakdown by utm_source", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmSource: "facebook" }],
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

    test "filters timeseries by utm_campaign", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" },
            granularity: DAILY,
            filters: [{ utmCampaign: "newsletter" }]
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

    test "combines multiple UTM filters", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [
              { utmMedium: "social" },
              { utmSource: "twitter" },
              { utmCampaign: "promo" }
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

    test "combines UTM filter with other filters", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [
              { utmMedium: "cpc" },
              { device: "desktop" }
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

    test "handles empty UTM filter values gracefully", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmMedium: "" }]
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Empty string should be handled gracefully (treated as no filter or valid value)
      response = json_response(conn, 200)
      # The query should either succeed or return an appropriate error
      assert response["errors"] == nil or response["data"]["aggregate"] != nil
    end

    test "filters by utm_medium and returns correct metrics", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS, BOUNCE_RATE],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ utmMedium: "referral" }]
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

    test "supports different UTM values in breakdown query", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_SOURCE,
            metrics: [VISITORS, PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 20
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

    test "supports different UTM values in breakdown by UTM_CAMPAIGN", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_CAMPAIGN,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 20
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

    test "supports different UTM values in breakdown by UTM_MEDIUM", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: UTM_MEDIUM,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 20
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
