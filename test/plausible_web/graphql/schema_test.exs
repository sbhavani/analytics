defmodule PlausibleWeb.GraphQL.SchemaTest do
  @moduledoc """
  Tests for GraphQL schema and types.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "pageviews query" do
    test "parses pageviews query successfully" do
      query = """
      query {
        pageviews(site_id: "example.com") {
          url
          visitor_count
          view_count
        }
      }
      """

      {:ok, %{data: _data, errors: []}} = Absinthe.run(query, Schema)
    end

    test "parses pageviews query with filter" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
            url_pattern: "/page/*"
          }
          limit: 10
          offset: 0
        ) {
          url
          visitor_count
          view_count
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses pageviews_aggregate query" do
      query = """
      query {
        pageviews_aggregate(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } },
          aggregation: { type: SUM, metric: "pageviews" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses pageviews_timeseries query" do
      query = """
      query {
        pageviews_timeseries(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } },
          interval: DAY
        ) {
          date
          visitors
          pageviews
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "events query" do
    test "parses events query successfully" do
      query = """
      query {
        events(site_id: "example.com") {
          name
          count
          timestamp
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses events query with event_type filter" do
      query = """
      query {
        events(
          site_id: "example.com",
          event_type: "signup",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } }
        ) {
          name
          count
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses events_aggregate query" do
      query = """
      query {
        events_aggregate(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } },
          event_type: "signup",
          aggregation: { type: COUNT, metric: "events" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "custom_metrics query" do
    test "parses custom_metrics query successfully" do
      query = """
      query {
        custom_metrics(site_id: "example.com") {
          name
          value
          formula
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "analytics query" do
    test "parses combined analytics query" do
      query = """
      query {
        analytics(
          site_id: "example.com",
          filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } },
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

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "filter input types" do
    test "parses device_type filter" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { device_type: MOBILE }
        ) {
          url
          visitor_count
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses geography filters" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { country: "US", region: "CA", city: "123" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end

    test "parses referrer filter" do
      query = """
      query {
        pageviews(
          site_id: "example.com",
          filter: { referrer: "google.com" }
        ) {
          url
        }
      }
      """

      {:ok, %{data: _data}} = Absinthe.run(query, Schema)
    end
  end

  describe "aggregation input types" do
    test "parses all aggregation types" do
      for type <- [:COUNT, :SUM, :AVERAGE, :MIN, :MAX] do
        query = """
        query {
          pageviews_aggregate(
            site_id: "example.com",
            aggregation: { type: #{type}, metric: "visitors", group_by: "country" }
          ) {
            metric
            value
          }
        }
        """

        {:ok, %{data: _data}} = Absinthe.run(query, Schema)
      end
    end
  end
end
