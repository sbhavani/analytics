defmodule PlausibleWeb.GraphQL.Controllers.CustomMetricsTest do
  @moduledoc """
  Integration tests for the custom metrics GraphQL endpoint.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory

  describe "custom_metrics GraphQL query" do
    test "returns custom metrics for authenticated user", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "purchase")

      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}"
          ) {
            id
            name
            displayName
            value
            unit
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "data" => %{
          "customMetrics" => metrics
        }
      } = json_response(conn, 200)

      assert is_list(metrics)
    end

    test "filters custom metrics by name", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "purchase", name: "Total Purchases")

      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}",
            name: "purchase"
          ) {
            name
            value
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "filters custom metrics by category", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "signup")

      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}",
            category: "signup"
          ) {
            name
            category
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "returns custom metrics time series", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "signup", name: "Signups")

      query = """
        query {
          customMetricsTimeSeries(
            siteId: "#{site.domain}",
            metricName: "Signups",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            interval: DAY
          ) {
            timestamp
            value
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "returns unauthorized for unauthenticated user", %{conn: conn} do
      site = Factory.insert(:site)

      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}"
          ) {
            name
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "errors" => [%{"message" => "Authentication required"}]
      } = json_response(conn, 200)
    end
  end
end
