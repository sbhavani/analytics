defmodule PlausibleWeb.GraphQL.Contract.EventTest do
  use PlausibleWeb.ConnCase, async: true

  describe "events GraphQL endpoint" do
    setup [:create_user, :create_site]

    test "requires authentication", %{conn: conn} do
      query = """
      query {
        events(siteId: "test-site") {
          name
          count
        }
      }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(conn, 200)
    end

    test "returns event data with valid filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(siteId: "#{site.domain}", filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}) {
          name
          count
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)
    end

    test "filters by event name", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            eventName: "button_click"
          }
        ) {
          name
          count
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)
    end

    test "supports aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: COUNT}
        ) {
          count
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)
    end

    test "supports different aggregation types", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Test SUM aggregation
      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: SUM, field: "value"}
        ) {
          count
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)

      # Test AVG aggregation
      avg_query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: AVG}
        ) {
          count
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => avg_query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)
    end

    test "supports property filters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "label",
              operator: CONTAINS,
              value: "pricing"
            }
          }
        ) {
          name
          count
          properties
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"events" => _}} = json_response(conn, 200)
    end
  end
end
