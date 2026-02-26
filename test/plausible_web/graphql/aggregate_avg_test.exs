defmodule PlausibleWeb.GraphQL.AggregateAvgTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "aggregate query - average calculations" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    @user_id Enum.random(1000..9999)

    test "returns visit_duration as average time per visit", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:25:00]
        ),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISIT_DURATION],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["visitDuration"] == 750
    end

    test "returns bounce_rate as percentage", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:25:00]
        ),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [BOUNCE_RATE],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            bounceRate
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["bounceRate"] == 50.0
    end

    test "calculates visit_duration correctly across multiple visitors", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        # User 1: 30 min session = 1800 seconds
        build(:pageview,
          user_id: 1001,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 1001,
          timestamp: ~N[2021-01-01 00:30:00]
        ),
        # User 2: 10 min session = 600 seconds
        build(:pageview,
          user_id: 1002,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 1002,
          timestamp: ~N[2021-01-01 00:10:00]
        ),
        # User 3: bounces immediately (0 seconds)
        build(:pageview,
          user_id: 1003,
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISIT_DURATION],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Average = (1800 + 600 + 0) / 3 = 800 seconds
      assert json_response(conn, 200)["data"]["aggregate"]["visitDuration"] == 800
    end

    test "calculates bounce_rate correctly with multiple visitors", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        # User 1: bounces (single pageview)
        build(:pageview,
          user_id: 1001,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        # User 2: bounces (single pageview)
        build(:pageview,
          user_id: 1002,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        # User 3: engaged (multiple pageviews)
        build(:pageview,
          user_id: 1003,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 1003,
          timestamp: ~N[2021-01-01 00:10:00]
        )
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [BOUNCE_RATE],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            bounceRate
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # 2 out of 3 visitors bounced = 66.67%
      assert_in_delta json_response(conn, 200)["data"]["aggregate"]["bounceRate"], 66.67, 0.01
    end

    test "returns multiple average metrics together", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: @user_id,
          timestamp: ~N[2021-01-01 00:25:00]
        ),
        build(:pageview, timestamp: ~N[2021-01-01 00:00:00])
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS, PAGEVIEWS, BOUNCE_RATE, VISIT_DURATION],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            visitors
            pageviews
            bounceRate
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)["data"]["aggregate"]

      assert response["visitors"] == 2
      assert response["pageviews"] == 3
      assert response["bounceRate"] == 50.0
      assert response["visitDuration"] == 750
    end

    test "returns null for visit_duration when no data available", %{
      conn: conn,
      site: site
    } do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISIT_DURATION],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["visitDuration"] == nil
    end

    test "returns null for bounce_rate when no data available", %{
      conn: conn,
      site: site
    } do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [BOUNCE_RATE],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" }
          }) {
            bounceRate
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      assert json_response(conn, 200)["data"]["aggregate"]["bounceRate"] == nil
    end

    test "calculates average with filters applied", %{
      conn: conn,
      site: site
    } do
      populate_stats(site, [
        build(:pageview,
          user_id: 1001,
          pathname: "/blog",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 1001,
          pathname: "/blog",
          timestamp: ~N[2021-01-01 00:25:00]
        ),
        build(:pageview,
          user_id: 1002,
          pathname: "/blog",
          timestamp: ~N[2021-01-01 00:00:00]
        ),
        build(:pageview,
          user_id: 1003,
          pathname: "/other",
          timestamp: ~N[2021-01-01 00:00:00]
        )
      ])

      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISIT_DURATION],
            dateRange: { startDate: "2021-01-01", endDate: "2021-01-01" },
            filters: [{ pathname: "/blog" }]
          }) {
            visitDuration
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      # Average for /blog filtered: (1500 + 0) / 2 = 750
      assert json_response(conn, 200)["data"]["aggregate"]["visitDuration"] == 750
    end
  end
end
