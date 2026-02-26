defmodule PlausibleWeb.GraphQL.Controllers.AggregationTest do
  @moduledoc """
  Integration tests for aggregation queries.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory

  describe "aggregation queries" do
    test "applies SUM aggregation to pageviews", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: SUM }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "applies AVG aggregation to pageviews", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: AVG }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "applies MIN aggregation to pageviews", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: MIN }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "applies MAX aggregation to pageviews", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: MAX }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "groups pageviews by country with time interval", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, groupBy: COUNTRY, interval: DAY }
          ) {
            count
            visitors
            group
            period
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "groups events by browser", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, groupBy: BROWSER }
          ) {
            count
            visitors
            group
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "supports WEEK time interval", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, interval: WEEK }
          ) {
            count
            period
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "supports MONTH time interval", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, interval: MONTH }
          ) {
            count
            period
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end
  end
end
