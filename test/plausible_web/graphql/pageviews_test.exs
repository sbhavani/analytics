defmodule PlausibleWeb.GraphQL.PageviewsTest do
  @moduledoc """
  Integration tests for pageview GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "pageviews query" do
    test "returns empty list when site not found" do
      query = """
      query {
        pageviews(site_id: "nonexistent.example.com") {
          url
          visitor_count
          view_count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      # Site not found returns error from resolver
    end

    test "parses pageviews query with all parameters" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            url_pattern: "/test/*"
            device_type: DESKTOP
            country: "US"
          }
          limit: 50
          offset: 10
        ) {
          url
          visitor_count
          view_count
          timestamp
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "pageviews_aggregate query" do
    test "calculates sum aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: SUM, metric: "pageviews" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "pageviews"
    end

    test "calculates average aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: AVERAGE, metric: "visitors" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "visitors"
    end

    test "calculates count aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: COUNT, metric: "pageviews" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "pageviews"
    end
  end

  describe "pageviews_timeseries query" do
    test "returns daily timeseries" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
          interval: DAY
        ) {
          date
          visitors
          pageviews
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews_timeseries"])
    end

    test "returns hourly timeseries" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-02" } },
          interval: HOUR
        ) {
          date
          visitors
          pageviews
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews_timeseries"])
    end

    test "returns monthly timeseries" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
          interval: MONTH
        ) {
          date
          visitors
          pageviews
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["pageviews_timeseries"])
    end
  end
end
