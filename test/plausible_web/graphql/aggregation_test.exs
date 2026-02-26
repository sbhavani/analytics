defmodule PlausibleWeb.GraphQL.AggregationTest do
  @moduledoc """
  Integration tests for aggregation in GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "aggregation types" do
    test "calculates COUNT aggregation" do
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
      assert is_number(data["pageviews_aggregate"]["value"])
    end

    test "calculates SUM aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: SUM, metric: "visitors" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "visitors"
    end

    test "calculates AVERAGE aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: AVERAGE, metric: "pageviews" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "pageviews"
    end

    test "calculates MIN aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: MIN, metric: "visitors" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "visitors"
    end

    test "calculates MAX aggregation" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: MAX, metric: "pageviews" }
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

  describe "group_by aggregation" do
    test "aggregates with group_by dimension" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          aggregation: { type: COUNT, metric: "pageviews", group_by: "country" }
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

  describe "time grouping" do
    test "groups by hour" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
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

    test "groups by day" do
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

    test "groups by week" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
          interval: WEEK
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

    test "groups by month" do
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

  describe "combined analytics query" do
    test "returns multiple metrics in one query" do
      query = """
      query {
        analytics(
          site_id: "example.com",
          metrics: ["visitors", "pageviews", "events"],
          interval: DAY
        ) {
          date
          visitors
          pageviews
          events
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["analytics"])
    end

    test "returns analytics with filters" do
      query = """
      query {
        analytics(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            device_type: DESKTOP
          },
          metrics: ["visitors", "pageviews"],
          interval: DAY
        ) {
          date
          visitors
          pageviews
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["analytics"])
    end

    test "supports different time intervals" do
      for interval <- [:HOUR, :DAY, :WEEK, :MONTH] do
        query = """
        query {
          analytics(
            site_id: "example.com",
            metrics: ["visitors"],
            interval: #{interval}
          ) {
            date
            visitors
          }
        }
        """

        {:ok, %{data: data}} = Absinthe.run(query, Schema)
        assert is_list(data["analytics"])
      end
    end
  end

  describe "aggregation with filters" do
    test "aggregates filtered data" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            device_type: MOBILE
          },
          aggregation: { type: SUM, metric: "visitors" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["pageviews_aggregate"]["metric"] == "visitors"
    end
  end
end
