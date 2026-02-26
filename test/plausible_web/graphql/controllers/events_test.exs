defmodule PlausibleWeb.GraphQL.Controllers.EventsTest do
  @moduledoc """
  Integration tests for the events GraphQL endpoint.
  """

  use PlausibleWeb.ConnCase, async: true
  alias Plausible.Factory

  describe "events GraphQL query" do
    test "returns event data for authenticated user", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "signup")

      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" }
          ) {
            count
            visitors
            eventName
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{
        "data" => %{
          "events" => events
        }
      } = json_response(conn, 200)

      assert is_list(events)
    end

    test "filters events by event name", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])
      _goal = Factory.insert(:goal, site: site, event_name: "signup")

      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            filters: { eventName: "signup" }
          ) {
            count
            eventName
          }
        }
      """

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => _} = json_response(conn, 200)
    end

    test "returns aggregated events grouped by event name", %{conn: conn} do
      user = Factory.insert(:user)
      site = Factory.insert(:site, members: [user])

      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: { from: "2026-01-01", to: "2026-01-31" },
            aggregation: { type: COUNT, groupBy: EVENT_NAME }
          ) {
            count
            visitors
            eventName
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
          events(
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

      assert %{
        "errors" => [%{"message" => "Authentication required"}]
      } = json_response(conn, 200)
    end
  end
end
