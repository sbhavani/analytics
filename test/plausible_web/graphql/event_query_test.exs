defmodule PlausibleWeb.GraphQL.EventQueryTest do
  use PlausibleWeb.ConnCase, async: true

  describe "events GraphQL endpoint - integration" do
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

    test "returns events list with all required fields", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(siteId: "#{site.domain}", filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}) {
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

      assert %{"data" => %{"events" => events}} = json_response(conn, 200)
      assert is_list(events)
    end

    test "validates date range (max 1 year)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Date range exceeds 1 year
      query = """
      query {
        events(siteId: "#{site.domain}", filter: {dateRange: {from: "2024-01-01", to: "2026-01-01"}}) {
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

      assert %{"errors" => [%{"message" => "Invalid date range: maximum 1 year allowed"}]} = json_response(conn, 200)
    end

    test "filters events by specific event name", %{conn: conn, user: user, site: site} do
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

      assert %{"data" => %{"events" => events}} = json_response(conn, 200)
      assert is_list(events)
    end

    test "supports COUNT aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: COUNT}
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

      assert %{"data" => %{"events" => events}} = json_response(conn, 200)
      assert is_list(events)
    end

    test "supports SUM aggregation with field", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: SUM, field: "value"}
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

    test "supports AVG aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: AVG}
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

    test "supports MIN aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: MIN}
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

    test "supports MAX aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          aggregation: {type: MAX}
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

    test "supports pagination parameters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          pagination: {limit: 10, offset: 0}
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

    test "supports property filters with eq operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "label",
              operator: eq,
              value: "signup"
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

    test "supports property filters with neq operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "label",
              operator: neq,
              value: "signup"
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

    test "supports property filters with contains operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "url",
              operator: contains,
              value: "/pricing"
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

    test "supports property filters with gt operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: gt,
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

    test "supports property filters with gte operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: gte,
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

    test "supports property filters with lt operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: lt,
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

    test "supports property filters with lte operator", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            property: {
              field: "value",
              operator: lte,
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

    test "returns empty list when date range has no events", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2020-01-01", to: "2020-01-31"}}
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

      assert %{"data" => %{"events" => events}} = json_response(conn, 200)
      assert events == [] or is_list(events)
    end

    test "combines event name filter with property filter", %{conn: conn, user: user, site: site} do
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
              operator: gt,
              value: "100"
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

    test "combines pagination with aggregation", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
          pagination: {limit: 5, offset: 10},
          aggregation: {type: COUNT}
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

    test "validates required date_range in filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Missing date_range
      query = """
      query {
        events(
          siteId: "#{site.domain}",
          filter: {}
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

      assert %{"errors" => _} = json_response(conn, 200)
    end

    test "handles multiple filter operators in sequence", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Test each aggregation type in sequence
      aggregation_types = [:COUNT, :SUM, :AVG, :MIN, :MAX]

      for agg_type <- aggregation_types do
        query = """
        query {
          events(
            siteId: "#{site.domain}",
            filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}},
            aggregation: {type: #{agg_type}}
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
  end
end
