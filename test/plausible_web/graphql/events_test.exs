defmodule PlausibleWeb.GraphQL.EventsTest do
  @moduledoc """
  Integration tests for event GraphQL queries.
  """

  use Plausible.DataCase, async: true
  use PlausibleWEB.ConnCase

  alias PlausibleWeb.GraphQL.Schema

  describe "events query" do
    test "returns events for a site" do
      query = """
      query {
        events(site_id: "example.com") {
          name
          count
          timestamp
          properties
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["events"])
    end

    test "filters events by event_type" do
      query = """
      query {
        events(
          site_id: "example.com",
          event_type: "signup"
        ) {
          name
          count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["events"])
    end

    test "filters events with date range" do
      query = """
      query {
        events(
          site_id: "example.com",
          filter: {
            date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
          }
        ) {
          name
          count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["events"])
    end

    test "supports pagination" do
      query = """
      query {
        events(
          site_id: "example.com",
          limit: 10
          offset: 5
        ) {
          name
          count
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert is_list(data["events"])
    end
  end

  describe "events_aggregate query" do
    test "calculates event count aggregation" do
      query = """
      query {
        events_aggregate(
          site_id: "example.com",
          aggregation: { type: COUNT, metric: "events" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["events_aggregate"]["metric"] == "events"
    }

    test "calculates event sum aggregation" do
      query = """
      query {
        events_aggregate(
          site_id: "example.com",
          event_type: "pageview",
          aggregation: { type: SUM, metric: "events" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["events_aggregate"]["metric"] == "events"
    end

    test "calculates visitor aggregation for events" do
      query = """
      query {
        events_aggregate(
          site_id: "example.com",
          event_type: "signup",
          aggregation: { type: SUM, metric: "visitors" }
        ) {
          metric
          value
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(query, Schema)
      assert data["events_aggregate"]["metric"] == "visitors"
    end
  end
end
