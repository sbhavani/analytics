defmodule PlausibleWeb.GraphQL.MetricsTest do
  use PlausibleWeb.ConnCase, async: true

  setup [:create_user, :create_site]

  describe "metrics query" do
    test "returns authentication error without session", %{conn: conn, site: site} do
      query = """
        query {
          metrics(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            aggregationType: sum,
            timeGrouping: day
          ) {
            edges {
              node {
                name
                value
              }
            }
          }
        }
      """

      conn =
        post(conn, "/api/graphql", %{
          "query" => query
        })

      assert %{"errors" => [%{"message" => "Authentication required"}]} = json_response(conn, 200)
    end

    test "returns empty results for authenticated user", %{conn: conn, user: user, site: site} do
      query = """
        query {
          metrics(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            aggregationType: sum,
            timeGrouping: day
          ) {
            edges {
              node {
                name
                value
                period
              }
            }
            pageInfo {
              totalCount
              hasNextPage
            }
          }
        }
      """

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => %{"edges" => [], "pageInfo" => %{"totalCount" => 0}}}} = json_response(conn, 200)
    end

    test "accepts aggregation type parameter", %{conn: conn, user: user, site: site} do
      query = """
        query {
          metrics(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            aggregationType: average,
            timeGrouping: day
          ) {
            edges {
              node {
                aggregationType
                value
              }
            }
          }
        }
      """

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => %{"edges" => []}}} = json_response(conn, 200)
    end

    test "accepts time grouping parameter", %{conn: conn, user: user, site: site} do
      query = """
        query {
          metrics(
            filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
            aggregationType: count,
            timeGrouping: week
          ) {
            edges {
              node {
                period
              }
            }
          }
        }
      """

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:site, site)
        |> post("/api/graphql", %{
          "query" => query
        })

      assert %{"data" => %{"metrics" => %{"edges" => []}}} = json_response(conn, 200)
    end

    test "accepts all aggregation types", %{conn: conn, user: user, site: site} do
      aggregation_types = ~w(count sum average min max)

      for agg_type <- aggregation_types do
        query = """
          query {
            metrics(
              filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
              aggregationType: #{agg_type},
              timeGrouping: day
            ) {
              edges {
                node {
                  aggregationType
                }
              }
            }
          }
        """

        conn =
          conn
          |> assign(:current_user, user)
          |> assign(:site, site)
          |> post("/api/graphql", %{
            "query" => query
          })

        assert %{"data" => %{"metrics" => %{"edges" => []}}} = json_response(conn, 200)
      end
    end

    test "accepts all time grouping options", %{conn: conn, user: user, site: site} do
      time_groupings = ~w(hour day week month)

      for tg <- time_groupings do
        query = """
          query {
            metrics(
              filter: { dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" } },
              aggregationType: sum,
              timeGrouping: #{tg}
            ) {
              edges {
                node {
                  period
                }
              }
            }
          }
        """

        conn =
          conn
          |> assign(:current_user, user)
          |> assign(:site, site)
          |> post("/api/graphql", %{
            "query" => query
          })

        assert %{"data" => %{"metrics" => %{"edges" => []}}} = json_response(conn, 200)
      end
    end
  end
end
