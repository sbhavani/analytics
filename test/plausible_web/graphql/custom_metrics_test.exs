defmodule PlausibleWeb.GraphQL.CustomMetricsTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "POST /api/graphql - custom_metrics queries" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "returns custom metrics for authenticated request", %{conn: conn, site: site} do
      query = """
        query {
          customMetrics(siteId: "#{site.id}") {
            name
            value
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)

      # Should not have errors
      assert response["errors"] == nil

      # Should have customMetrics key in response
      assert response["data"]["customMetrics"] != nil
    end

    test "returns custom metrics with correct structure", %{conn: conn, site: site} do
      query = """
        query {
          customMetrics(siteId: "#{site.id}") {
            name
            value
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil

      metrics = response["data"]["customMetrics"]

      # Check that we get a list (possibly empty if no custom metrics defined)
      assert is_list(metrics)

      # If there are metrics, verify structure
      if length(metrics) > 0 do
        metric = hd(metrics)
        assert Map.has_key?(metric, "name")
        assert Map.has_key?(metric, "value")
      end
    end

    test "returns empty list when no custom metrics are defined", %{conn: conn, site: site} do
      query = """
        query {
          customMetrics(siteId: "#{site.id}") {
            name
            value
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] == nil

      # Should return an empty list when no metrics exist
      assert response["data"]["customMetrics"] == []
    end

    test "returns unauthorized when no API key is provided", %{conn: conn, site: site} do
      # Create a new conn without auth header
      unauth_conn =
        build_conn()
        |> post("/api/graphql", %{"query" => """
          query {
            customMetrics(siteId: "#{site.id}") {
              name
              value
            }
          }
        """})

      response = json_response(unauth_conn, 200)

      # Without authentication context, should return unauthorized
      # Either errors or null data is acceptable
      assert response["errors"] != nil or response["data"]["customMetrics"] == nil
    end

    test "validates site_id is provided", %{conn: conn} do
      query = """
        query {
          customMetrics {
            name
            value
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{"query" => query})

      response = json_response(conn, 200)

      # Should return error for missing required argument
      assert response["errors"] != nil
    end
  end
end
