defmodule PlausibleWeb.GraphQL.MetricQueryTest do
  use PlausibleWeb.ConnCase, async: true

  describe "metrics GraphQL endpoint" do
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

    test "returns metrics data with valid filter", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(siteId: "#{site.domain}", filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}, metricNames: ["visitors"]}) {
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

    test "validates date range (max 1 year)", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      # Date range exceeds 1 year
      query = """
      query {
        metrics(siteId: "#{site.domain}", filter: {dateRange: {from: "2024-01-01", to: "2026-01-01"}}) {
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

    test "supports time_series with interval", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}, metricNames: ["visitors"]},
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

    test "supports multiple metric names", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}, metricNames: ["visitors", "revenue", "events"]}
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
      assert is_list(metrics)
    end

    test "returns empty list when no metric names specified", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      query = """
      query {
        metrics(
          siteId: "#{site.domain}",
          filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}}
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

    test "supports different time intervals", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-key-123", scopes: ["stats:read:*"])

      intervals = [:minute, :hour, :day, :week, :month]

      for interval <- intervals do
        query = """
        query {
          metrics(
            siteId: "#{site.domain}",
            filter: {dateRange: {from: "2026-01-01", to: "2026-01-31"}, metricNames: ["visitors"]},
            timeSeries: true,
            interval: #{String.upcase(to_string(interval))}
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
    end
  end
end
