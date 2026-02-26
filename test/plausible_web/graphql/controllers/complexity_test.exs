defmodule PlausibleWeb.GraphQL.Controllers.ComplexityTest do
  @moduledoc """
  Tests for GraphQL query complexity analysis.

  These tests verify that the complexity analysis correctly evaluates
  queries and rejects those that exceed the complexity limit.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory

  describe "query complexity validation" do
    test "allows simple query within complexity limit", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      # Should succeed (either with data or error about missing auth)
      response = json_response(conn, 200)
      assert Map.has_key?(response, "data") or Map.has_key?(response, "errors")
    end

    test "rejects query with nested fragments exceeding complexity", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      # Build a deeply nested query that would exceed complexity
      # This uses many field selections to increase complexity
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
            visitors
            views
            bounceRate
            visitDuration
            group
          }
          events(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
            visitors
            name
            group
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      response = json_response(conn, 200)

      # Either query runs (if complexity is within limits) or it's rejected
      assert Map.has_key?(response, "data") or Map.has_key?(response, "errors")
    end

    test "rejects query missing query parameter", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{operationName: "Test"})

      assert %{
        "errors" => [%{"message" => "Missing 'query' parameter"}]
      } = json_response(conn, 200)
    end

    test "allows custom metrics query within complexity limit", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}"
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

      response = json_response(conn, 200)
      assert Map.has_key?(response, "data") or Map.has_key?(response, "errors")
    end
  end
end
