defmodule PlausibleWeb.GraphQL.Types.MetricTypeTest do
  use PlausibleWeb.ConnCase, async: true

  describe "metrics GraphQL endpoint - CustomMetricType" do
    setup [:create_user, :create_site]

    test "requires authentication", %{conn: conn} do
      query = """
      query {
        metrics(siteId: "test-site") {
          name
          value
        }
      }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(conn, 200)
    end

    test "returns custom metrics with name and value", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            metricNames: ["visitors", "revenue"]
          }
        ) {
          name
          value
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => _}} = json_response(conn, 200)
    end

    test "supports time_series parameter for historical data", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            metricNames: ["visitors"]
          },
          timeSeries: true,
          interval: DAY
        ) {
          name
          value
          historical {
            timestamp
            value
          }
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => _}} = json_response(conn, 200)
    end

    test "validates date range (max 1 year)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Date range exceeds 1 year
      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2024-01-01", to: "2026-01-01"},
            metricNames: ["visitors"]
          }
        ) {
          name
          value
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

    test "returns empty list when no metric_names provided", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"}
          }
        ) {
          name
          value
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => []}} = json_response(conn, 200)
    end

    test "supports all time interval options", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      intervals = ["MINUTE", "HOUR", "DAY", "WEEK", "MONTH"]

      for interval <- intervals do
        query = """
        query {
          metrics(
            siteId: "#{site.domain}",
            filter: {
              dateRange: {from: "2026-01-01", to: "2026-01-31"},
              metricNames: ["visitors"]
            },
            timeSeries: true,
            interval: #{interval}
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

        assert %{"data" => %{"metrics" => _}} = json_response(conn, 200)
      end
    end

    test "metric_data_point contains timestamp and value fields", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            metricNames: ["revenue"]
          },
          timeSeries: true,
          interval: DAY
        ) {
          name
          value
          historical {
            timestamp
            value
          }
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => [%{"historical" => historical}]}} = json_response(conn, 200)
      # Historical should be a list
      assert is_list(historical)
    end

    test "custom_metric returns float value for numeric metrics", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {
            dateRange: {from: "2026-01-01", to: "2026-01-31"},
            metricNames: ["revenue"]
          }
        ) {
          name
          value
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => metrics}} = json_response(conn, 200)
      # Value should be a number (float)
      assert is_number(hd(metrics)["value"])
    end
  end
end
