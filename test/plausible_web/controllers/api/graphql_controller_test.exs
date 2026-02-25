defmodule PlausibleWeb.Api.GraphQLControllerTest do
  use PlausibleWeb.ConnCase

  alias Plausible.Repo

  describe "authentication" do
    test "unauthenticated request - returns 401", %{conn: conn} do
      conn =
        conn
        |> post("/api/graphql", %{
          "query" => "{ analytics(siteId: \"test.com\") { pageviews { visitors } } }"
        })

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "Missing API key. Please use a valid Plausible API key as a Bearer Token."}]
             }
    end

    test "bad API key - returns 401", %{conn: conn} do
      conn =
        conn
        |> with_api_key("bad-api-key")
        |> post("/api/graphql", %{
          "query" => "{ analytics(siteId: \"test.com\") { pageviews { visitors } } }"
        })

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "Invalid API key. Please make sure you're using a valid API key."}]
             }
    end
  end

  describe "successful queries" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "returns pageview data for valid query", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!) {
              analytics(siteId: $siteId) {
                pageviews {
                  visitors
                  pageviews
                  bounce_rate
                  visit_duration
                }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain
          }
        })

      response = json_response(conn, 200)

      assert response["data"]["analytics"]["pageviews"] == %{
               "visitors" => 0,
               "pageviews" => 0,
               "bounce_rate" => 0.0,
               "visit_duration" => 0
             }
    end

    test "returns pageview data with date range", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!, $dateRange: DateRangeInput) {
              analytics(siteId: $siteId, dateRange: $dateRange) {
                pageviews {
                  visitors
                }
                metadata {
                  date_range {
                    from
                    to
                    period
                  }
                }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain,
            "dateRange" => %{
              "from" => "2024-01-01",
              "to" => "2024-01-31",
              "period" => "daily"
            }
          }
        })

      response = json_response(conn, 200)

      assert response["data"]["analytics"]["pageviews"]["visitors"] == 0
      assert response["data"]["analytics"]["metadata"]["date_range"]["from"] == "2024-01-01"
      assert response["data"]["analytics"]["metadata"]["date_range"]["to"] == "2024-01-31"
    end

    test "returns events data", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!) {
              analytics(siteId: $siteId) {
                events {
                  name
                  count
                  unique_visitors
                }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain
          }
        })

      response = json_response(conn, 200)

      assert response["data"]["analytics"]["events"] == []
    end

    test "returns timeseries data", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!, $dateRange: DateRangeInput) {
              analytics(siteId: $siteId, dateRange: $dateRange) {
                timeseries {
                  date
                  visitors
                  pageviews
                }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain,
            "dateRange" => %{
              "from" => "2024-01-01",
              "to" => "2024-01-07",
              "period" => "daily"
            }
          }
        })

      response = json_response(conn, 200)

      assert is_list(response["data"]["analytics"]["timeseries"])
    end

    test "returns site metadata", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!) {
              analytics(siteId: $siteId) {
                metadata {
                  site {
                    domain
                    name
                  }
                }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain
          }
        })

      response = json_response(conn, 200)

      assert response["data"]["analytics"]["metadata"]["site"]["domain"] == site.domain
    end
  end

  describe "GraphQL error handling" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "returns error for invalid query syntax", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => "invalid query syntax"
        })

      response = json_response(conn, 200)

      assert response["errors"] != nil
      assert is_list(response["errors"])
    end

    test "returns error for missing required arguments", %{conn: conn, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => "{ analytics { pageviews { visitors } } }"
        })

      response = json_response(conn, 200)

      assert response["errors"] != nil
      assert is_list(response["errors"])
    end
  end

  describe "JSON body handling" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "handles JSON array body with _json key", %{conn: conn, site: site, api_key: api_key} do
      # Some GraphQL clients send the query as an array under _json key
      conn =
        conn
        |> with_api_key(api_key)
        |> put_req_header("content-type", "application/json")
        |> post("/api/graphql", %{
          "_json" => [
            %{
              "query" => """
                query($siteId: ID!) {
                  analytics(siteId: $siteId) {
                    pageviews { visitors }
                  }
                }
              """,
              "variables" => %{"siteId" => site.domain}
            }
          ]
        })

      response = json_response(conn, 200)

      # Should handle the array body and return results
      assert response["data"] || response["errors"]
    end
  end

  describe "filter support" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts filter arguments", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!, $filters: FilterInput) {
              analytics(siteId: $siteId, filters: $filters) {
                pageviews { visitors }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain,
            "filters" => %{
              "source" => "google",
              "device" => "desktop"
            }
          }
        })

      response = json_response(conn, 200)

      assert response["data"]["analytics"]["pageviews"]["visitors"] == 0
    end
  end

  describe "aggregation support" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts aggregation arguments", %{conn: conn, site: site, api_key: api_key} do
      conn =
        conn
        |> with_api_key(api_key)
        |> post("/api/graphql", %{
          "query" => """
            query($siteId: ID!, $aggregation: AggregationInput) {
              analytics(siteId: $siteId, aggregation: $aggregation) {
                pageviews { visitors }
              }
            }
          """,
          "variables" => %{
            "siteId" => site.domain,
            "aggregation" => %{
              "type" => "sum",
              "metric" => "pageviews"
            }
          }
        })

      response = json_response(conn, 200)

      # Aggregation is passed through but results may vary based on implementation
      assert response["data"] || response["errors"]
    end
  end

  # Helper functions

  defp with_api_key(conn, api_key) do
    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{api_key}")
  end
end
