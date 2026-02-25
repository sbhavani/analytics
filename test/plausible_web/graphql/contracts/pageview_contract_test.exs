defmodule PlausibleWeb.GraphQL.Contract.PageviewTest do
  use PlausibleWeb.ConnCase, async: true

  describe "pageviews GraphQL endpoint" do
    setup [:create_user, :create_site]

    test "requires authentication", %{conn: conn} do
      query = """
      query {
        pageviews(siteId: "test-site") {
          url
          viewCount
          uniqueVisitors
        }
      }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(conn, 200)
    end

    test "returns pageview data with valid filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(siteId: "#{site.domain}", filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}) {
          url
          viewCount
          uniqueVisitors
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"pageviews" => _}} = json_response(conn, 200)
    end

    test "validates date range (max 1 year)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Date range exceeds 1 year
      query = """
      query {
        pageviews(siteId: "#{site.domain}", filter: {dateRange: {from: "2024-01-01", to: "2026-01-01"}}) {
          url
          viewCount
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"errors" => [%{"message" => "Invalid date range: maximum 1 year allowed"}]} = json_response(conn, 200)
    end

    test "supports aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: COUNT}
        ) {
          viewCount
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"pageviews" => _}} = json_response(conn, 200)
    end

    test "supports pagination", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          pagination: {limit: 10, offset: 0}
        ) {
          url
          viewCount
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"pageviews" => _}} = json_response(conn, 200)
    end

    test "supports property filters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            country: "US",
            device: MOBILE
          }
        ) {
          url
          country
          device
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"pageviews" => _}} = json_response(conn, 200)
    end
  end
end
