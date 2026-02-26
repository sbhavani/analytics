defmodule PlausibleWeb.GraphQL.AggregateTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  setup [:create_user, :create_site, :create_api_key, :use_api_key]

  describe "aggregate - pageviews" do
    test "returns total pageviews for a site", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:25:00]),
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" }
          }) {
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["pageviews"] == 3
    end

    test "returns zero pageviews when no data exists", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" }
          }) {
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["pageviews"] == 0
    end

    test "returns pageviews with date range spanning multiple days", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2026-01-02 00:00:00]),
        build(:pageview, timestamp: ~N[2026-01-03 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-03" }
          }) {
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["pageviews"] == 3
    end
  end

  describe "aggregate - visitors" do
    test "returns total unique visitors", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:25:00]),
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" }
          }) {
            visitors
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["visitors"] == 2
    end
  end

  describe "aggregate - events" do
    test "returns total events including custom events", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00]),
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 00:10:00]),
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 00:20:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" }
          }) {
            events
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["events"] == 4
    end
  end

  describe "aggregate - multiple metrics" do
    test "returns multiple metrics in a single query", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, user_id: 123, timestamp: ~N[2026-01-01 00:25:00]),
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, EVENTS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" }
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

      result = json_response(conn, 200)["data"]["aggregate"]
      assert result["visitors"] == 2
      assert result["pageviews"] == 3
      assert result["events"] == 3
    end
  end

  describe "aggregate - with filters" do
    test "returns filtered pageviews by pathname", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, pathname: "/blog", timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, pathname: "/blog", timestamp: ~N[2026-01-01 00:10:00]),
        build(:pageview, pathname: "/about", timestamp: ~N[2026-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" },
            filters: [{ pathname: "/blog" }]
          }) {
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["pageviews"] == 2
    end

    test "returns filtered pageviews by referrer", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, referrer: "https://google.com", timestamp: ~N[2026-01-01 00:00:00]),
        build(:pageview, referrer: "https://google.com", timestamp: ~N[2026-01-01 00:10:00]),
        build(:pageview, timestamp: ~N[2026-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [PAGEVIEWS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-01" },
            filters: [{ referrer: "https://google.com" }]
          }) {
            pageviews
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["pageviews"] == 2
    end
  end
end
