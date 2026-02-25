defmodule PlausibleWeb.GraphQL.FilterTest do
  use PlausibleWeb.ConnCase, async: true

  describe "pageview filtering" do
    setup [:create_user, :create_site]

    test "filters by URL", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            url: "/blog"
          }
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

    test "filters by country", %{conn: conn, user: user, site: site} do
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

    test "filters by device type", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

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

    test "filters by mobile device", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            device: MOBILE
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

    test "filters by tablet device", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            device: TABLET
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

    test "filters by referrer", %{conn: conn, user: user, site: site} do
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

    test "combines multiple pageview filters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            country: "US",
            device: DESKTOP,
            url: "/pricing"
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

    test "works without filters (returns all pageviews)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
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
  end

  describe "event filtering" do
    setup [:create_user, :create_site]

    test "filters by event name", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            eventName: "pageview"
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

    test "filters by custom event name", %{conn: conn, user: user, site: site} do
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

    test "filters by property with eq operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "page",
              operator: EQ,
              value: "/pricing"
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

    test "filters by property with neq operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "page",
              operator: NEQ,
              value: "/home"
            }
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

    test "filters by property with contains operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "url",
              operator: CONTAINS,
              value: "blog"
            }
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

    test "filters by property with gt operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: GT,
              value: "100"
            }
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

    test "filters by property with gte operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: GTE,
              value: "50"
            }
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

    test "filters by property with lt operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: LT,
              value: "50"
            }
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

    test "filters by property with lte operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: LTE,
              value: "100"
            }
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

    test "combines event name with property filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            eventName: "purchase",
            property: {
              field: "amount",
              operator: GT,
              value: "50"
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

    test "works without filters (returns all events)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
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
  end

  describe "date range validation" do
    setup [:create_user, :create_site]

    test "rejects date range exceeding 1 year for pageviews", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

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

    test "rejects date range exceeding 1 year for events", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2024-01-01", to: "2026-01-01"}}
        ) {
          name
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

    test "accepts date range of exactly 1 year", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2025-02-01", to: "2026-02-01"}}
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

      # Should succeed - exactly 1 year is allowed
      assert %{"data" => %{"pageviews" => _}} = json_response(conn, 200)
    end

    test "accepts date range less than 1 year", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        pageviews(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
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
  end
end
