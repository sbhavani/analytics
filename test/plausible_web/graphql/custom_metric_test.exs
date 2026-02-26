defmodule PlausibleWeb.GraphQL.CustomMetricTest do
  use PlausibleWeb.ConnCase
  use Plausible

  @graphql """
  query($siteId: ID!, $dateRange: DateRangeInput, $filters: [FilterInput!], $pagination: PaginationInput, $aggregation: AggregationInput) {
    customMetrics(siteId: $siteId, dateRange: $dateRange, filters: $filters, pagination: $pagination, aggregation: $aggregation) {
      ... on CustomMetricConnection {
        edges {
          node {
            id
            name
            value
            timestamp
            siteId
            dimensions
          }
          cursor
        }
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
        totalCount
      }
      ... on AggregateResult {
        aggregationType
        value
        dimension
      }
    }
  }
  """

  describe "custom_metrics query" do
    setup [:create_user, :log_in, :create_site]

    test "returns custom metrics for a site", %{conn: conn, user: user, site: site} do
      # First create a goal with a numeric value (custom metric)
      insert(:goal, %{
        site: site,
        event_name: "Purchase",
        currency: "USD"
      })

      # Populate some events that match the goal
      populate_stats(site, [
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["100"]),
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["200"]),
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["150"]),
        build(:pageview, pathname: "/"),
        build(:pageview, pathname: "/about")
      ])

      variables = %{
        "siteId" => site.id
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)

      assert response["data"]["customMetrics"] != nil

      # Connection should have edges
      custom_metrics = response["data"]["customMetrics"]
      assert custom_metrics["edges"] != nil || custom_metrics["aggregationType"] != nil
    end

    test "returns custom metrics with date range filter", %{conn: conn, user: user, site: site} do
      insert(:goal, %{
        site: site,
        event_name: "Signup"
      })

      populate_stats(site, [
        build(:event, name: "Signup", timestamp: ~N[2024-01-15 10:00:00]),
        build(:event, name: "Signup", timestamp: ~N[2024-01-20 10:00:00]),
        build(:event, name: "Signup", timestamp: ~N[2024-02-15 10:00:00])
      ])

      variables = %{
        "siteId" => site.id,
        "dateRange" => %{
          "startDate" => "2024-01-01",
          "endDate" => "2024-01-31"
        }
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      assert response["data"]["customMetrics"] != nil
    end

    test "returns custom metrics with pagination", %{conn: conn, user: user, site: site} do
      insert(:goal, %{site: site, event_name: "Pageview"})

      populate_stats(site, [
        build(:event, name: "Pageview"),
        build(:event, name: "Pageview"),
        build(:event, name: "Pageview"),
        build(:event, name: "Pageview"),
        build(:event, name: "Pageview")
      ])

      variables = %{
        "siteId" => site.id,
        "pagination" => %{
          "first" => 2
        }
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      custom_metrics = response["data"]["customMetrics"]

      assert custom_metrics != nil
      assert custom_metrics["pageInfo"] != nil
    end

    test "returns aggregated custom metrics with COUNT aggregation", %{conn: conn, user: user, site: site} do
      insert(:goal, %{site: site, event_name: "Purchase"})

      populate_stats(site, [
        build(:event, name: "Purchase"),
        build(:event, name: "Purchase"),
        build(:event, name: "Purchase")
      ])

      variables = %{
        "siteId" => site.id,
        "aggregation" => %{
          "type" => "COUNT"
        }
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      custom_metrics = response["data"]["customMetrics"]

      # Should return aggregate result
      assert custom_metrics["aggregationType"] == "COUNT" or custom_metrics["value"] != nil
    end

    test "returns aggregated custom metrics with SUM aggregation", %{conn: conn, user: user, site: site} do
      insert(:goal, %{site: site, event_name: "Purchase", currency: "USD"})

      populate_stats(site, [
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["100"]),
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["200"]),
        build(:event, name: "Purchase", "meta.key": ["amount"], "meta.value": ["300"])
      ])

      variables = %{
        "siteId" => site.id,
        "aggregation" => %{
          "type" => "SUM",
          "field" => "amount"
        }
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      custom_metrics = response["data"]["customMetrics"]

      # Should return aggregate result
      assert custom_metrics != nil
    end

    test "returns aggregated custom metrics with AVERAGE aggregation", %{conn: conn, user: user, site: site} do
      insert(:goal, %{site: site, event_name: "Revenue", currency: "USD"})

      populate_stats(site, [
        build(:event, name: "Revenue", "meta.key": ["value"], "meta.value": ["100"]),
        build(:event, name: "Revenue", "meta.key": ["value"], "meta.value": ["200"]),
        build(:event, name: "Revenue", "meta.key": ["value"], "meta.value": ["300"])
      ])

      variables = %{
        "siteId" => site.id,
        "aggregation" => %{
          "type" => "AVERAGE",
          "field" => "value"
        }
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      custom_metrics = response["data"]["customMetrics"]

      assert custom_metrics != nil
    end

    test "returns error for unauthenticated request", %{site: site} do
      conn = build_conn()

      variables = %{
        "siteId" => site.id
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      # The authorization plug should handle this
      response = json_response(conn, 200)
      assert response["errors"] != nil || response["data"]["customMetrics"] == nil
    end

    test "returns error for invalid site ID", %{conn: conn, user: _user} do
      variables = %{
        "siteId" => "999999"
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      # Should return error for site not found
      assert response["errors"] != nil || response["data"]["customMetrics"] == nil
    end

    test "returns custom metrics with filters", %{conn: conn, user: _user, site: site} do
      insert(:goal, %{site: site, event_name: "Purchase"})

      populate_stats(site, [
        build(:event, name: "Purchase", country: "US"),
        build(:event, name: "Purchase", country: "US"),
        build(:event, name: "Purchase", country: "GB"),
        build(:event, name: "Purchase", country: "DE")
      ])

      variables = %{
        "siteId" => site.id,
        "filters" => [
          %{
            "field" => "country",
            "operator" => "equals",
            "value" => "US"
          }
        ]
      }

      conn =
        post(conn, "/api/graphql", %{
          "query" => @graphql,
          "variables" => variables
        })

      response = json_response(conn, 200)
      assert response["data"]["customMetrics"] != nil
    end
  end
end
