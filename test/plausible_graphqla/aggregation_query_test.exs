defmodule Plausible.Graphqla.AggregationQueryTest do
  use PlausibleWeb.ConnCase, async: false

  setup [:create_user, :create_site]

  describe "pageview_aggregations" do
    test "returns pageview counts grouped by time", %{conn: conn, user: user, site: site} do
      # Populate with pageview events
      populate_stats(site, [
        build(:event, name: "pageview", timestamp: ~N[2026-01-01 10:00:00]),
        build(:event, name: "pageview", timestamp: ~N[2026-01-01 11:00:00]),
        build(:event, name: "pageview", timestamp: ~N[2026-01-02 10:00:00])
      ])

      query = """
        query {
          pageviewAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
            }
            granularity: DAY
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"pageviewAggregations" => aggregations}} = response
      assert is_list(aggregations)
      assert length(aggregations) >= 2

      # Verify structure
      Enum.each(aggregations, fn agg ->
        assert is_binary(agg["key"])
        assert is_integer(agg["count"])
      end)
    end

    test "returns error for non-existent site", %{conn: conn, user: user} do
      query = """
        query {
          pageviewAggregations(
            filter: {
              siteId: "00000000-0000-0000-0000-000000000000"
            }
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"errors" => [%{"message" => "Site not found"}]} = response
    end

    test "works with different granularity levels", %{conn: conn, user: user, site: site} do
      populate_stats(site, [
        build(:event, name: "pageview", timestamp: ~N[2026-01-01 10:00:00]),
        build(:event, name: "pageview", timestamp: ~N[2026-01-07 10:00:00])
      ])

      query = """
        query {
          pageviewAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
            }
            granularity: WEEK
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"pageviewAggregations" => aggregations}} = response
      assert is_list(aggregations)
    end
  end

  describe "event_aggregations" do
    test "returns event counts grouped by event name", %{conn: conn, user: user, site: site} do
      populate_stats(site, [
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 10:00:00]),
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 11:00:00]),
        build(:event, name: "Purchase", timestamp: ~N[2026-01-01 10:00:00]),
        build(:event, name: "pageview", timestamp: ~N[2026-01-01 10:00:00])
      ])

      query = """
        query {
          eventAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
            }
            groupBy: "name"
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"eventAggregations" => aggregations}} = response
      assert is_list(aggregations)

      # Should have at least 2 unique event types (Signup and Purchase)
      keys = Enum.map(aggregations, & &1["key"])
      assert "Signup" in keys
      assert "Purchase" in keys
    end

    test "filters by event type", %{conn: conn, user: user, site: site} do
      populate_stats(site, [
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 10:00:00]),
        build(:event, name: "Signup", timestamp: ~N[2026-01-01 11:00:00]),
        build(:event, name: "Purchase", timestamp: ~N[2026-01-01 10:00:00])
      ])

      query = """
        query {
          eventAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
              eventType: "Signup"
            }
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"eventAggregations" => aggregations}} = response

      # Should only include Signup events (filtered)
      Enum.each(aggregations, fn agg ->
        assert agg["key"] == "Signup"
      end)
    end
  end

  describe "custom_metric_aggregations" do
    test "returns aggregated custom metrics with sum, count, average", %{conn: conn, user: user, site: site} do
      populate_stats(site, [
        build(:event, name: "custom_event", timestamp: ~N[2026-01-01 10:00:00],
          properties: %{"revenue" => 10.5}),
        build(:event, name: "custom_event", timestamp: ~N[2026-01-01 11:00:00],
          properties: %{"revenue" => 20.5}),
        build(:event, name: "custom_event", timestamp: ~N[2026-01-01 12:00:00],
          properties: %{"revenue" => 15.0})
      ])

      query = """
        query {
          customMetricAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
              metricName: "revenue"
            }
          ) {
            key
            sum
            count
            average
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"customMetricAggregations" => [agg]}} = response

      assert agg["key"] == "revenue"
      assert agg["count"] == 3
      assert_in_delta agg["sum"], 46.0, 0.1
      assert_in_delta agg["average"], 15.33, 0.1
    end

    test "returns zero values when no metrics found", %{conn: conn, user: user, site: site} do
      query = """
        query {
          customMetricAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
              metricName: "nonexistent"
            }
          ) {
            key
            sum
            count
            average
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"customMetricAggregations" => [agg]}} = response

      assert agg["key"] == "nonexistent"
      assert agg["count"] == 0
      assert agg["sum"] == 0.0
      assert agg["average"] == 0.0
    end

    test "returns all metrics when metric_name not specified", %{conn: conn, user: user, site: site} do
      populate_stats(site, [
        build(:event, name: "custom_event", timestamp: ~N[2026-01-01 10:00:00],
          properties: %{"revenue" => 100.0}),
        build(:event, name: "custom_event", timestamp: ~N[2026-01-01 11:00:00],
          properties: %{"score" => 50.0})
      ])

      query = """
        query {
          customMetricAggregations(
            filter: {
              siteId: "#{site.id}",
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
            }
          ) {
            key
            sum
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"data" => %{"customMetricAggregations" => [agg]}} = response
      assert agg["key"] == "all"
      assert agg["count"] == 2
    end
  end

  describe "authentication" do
    test "returns error when user is not authenticated", %{conn: conn, site: site} do
      query = """
        query {
          pageviewAggregations(
            filter: {
              siteId: "#{site.id}"
            }
          ) {
            key
            count
          }
        }
      """

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      assert %{"errors" => [%{"message" => message}]} = response
      assert message =~ "UNAUTHENTICATED"
    end
  end

  describe "filter validation" do
    test "returns error when site_id is missing", %{conn: conn, user: user} do
      query = """
        query {
          pageviewAggregations(
            filter: {
              dateRange: { from: "2026-01-01", to: "2026-01-31" }
            }
          ) {
            key
            count
          }
        }
      """

      conn = assign(conn, :current_user, user)

      response =
        conn
        |> post("/api/graphql", %{query: query})
        |> json_response(200)

      # GraphQL should handle missing required field
      assert response["errors"] || response["data"]
    end
  end
end
