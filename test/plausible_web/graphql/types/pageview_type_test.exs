defmodule PlausibleWeb.GraphQL.Types.PageviewTypeTest do
  use PlausibleWeb.ConnCase, async: true

  describe "pageviews GraphQL endpoint - PageviewType" do
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

    test "returns pageview data with url and counts", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
        ) {
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

    test "pageview_type includes timestamp field", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
        ) {
          url
          timestamp
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

    test "pageview_type includes referrer field", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
        ) {
          url
          referrer
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

    test "pageview_type includes country field", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            country: "US"
          }
        ) {
          url
          country
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

    test "pageview_type includes device field with enum values", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Test with desktop device filter
      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            device: DESKTOP
          }
        ) {
          url
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

    test "supports all device_type enum values", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      devices = ["DESKTOP", "MOBILE", "TABLET"]

      for device <- devices do
        query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            filter: {
              dateRange: {from: "2026-01-01", to: "2026-01-31"},
              device: #{device}
            }
          ) {
            url
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

    test "validates date range (max 1 year)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Date range exceeds 1 year
      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2024-01-01", to: "2026-01-01"}}
        ) {
          url
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

    test "supports pagination parameters", %{conn: conn, user: user, site: site} do
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

    test "supports aggregation parameter", %{conn: conn, user: user, site: site} do
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

    test "supports url filter parameter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            url: "/test-page"
          }
        ) {
          url
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

    test "supports referrer filter parameter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            referrer: "google.com"
          }
        ) {
          url
          referrer
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

    test "returns empty list when no data matches filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
        ) {
          url
          viewCount
          uniqueVisitors
          timestamp
          referrer
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

      assert %{"data" => %{"pageviews" => []}} = json_response(conn, 200)
    end
  end
end
