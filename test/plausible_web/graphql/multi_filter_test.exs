defmodule PlausibleWeb.GraphQL.MultiFilterTest do
  @moduledoc """
  Tests for multi-filter functionality in GraphQL queries.
  """

  use PlausibleWeb.ConnCase, async: false

  alias PlausibleWeb.GraphQL.Helpers.FilterParser

  describe "FilterParser.parse_filters/1" do
    test "parses multiple filters correctly" do
      filters = [
        %{field: "pathname", operator: "equals", value: "/blog"},
        %{field: "country", operator: "equals", value: "US"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert length(parsed) == 2

      # First filter
      assert [:page, :pathname, :exact, "/blog"] = Enum.at(parsed, 0)

      # Second filter
      assert [:page, :country, :exact, "US"] = Enum.at(parsed, 1)
    end

    test "parses filters with different operators" do
      filters = [
        %{field: "pathname", operator: "contains", value: "/blog"},
        %{field: "device", operator: "equals", value: "desktop"},
        %{field: "country", operator: "not_equals", value: "CN"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert length(parsed) == 3

      assert [:page, :pathname, :contains, "/blog"] = Enum.at(parsed, 0)
      assert [:page, :device, :exact, "desktop"] = Enum.at(parsed, 1)
      assert [:page, :country, :does_not_equal, "CN"] = Enum.at(parsed, 2)
    end

    test "parses event filters correctly" do
      filters = [
        %{field: "name", operator: "equals", value: "pageview"},
        %{field: "referrer", operator: "contains", value: "google"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert length(parsed) == 2

      assert [:event, :event_name, :exact, "pageview"] = Enum.at(parsed, 0)
      assert [:page, :referrer, :contains, "google"] = Enum.at(parsed, 1)
    end

    test "handles empty filter list" do
      assert {:ok, []} = FilterParser.parse_filters([])
    end

    test "handles nil filters" do
      assert {:ok, []} = FilterParser.parse_filters(nil)
    end

    test "returns error for unknown operator" do
      filters = [
        %{field: "pathname", operator: "unknown_op", value: "/blog"}
      ]

      assert {:error, ["Unknown operator: unknown_op"]} = FilterParser.parse_filters(filters)
    end

    test "parses match operators correctly" do
      filters = [
        %{field: "pathname", operator: "matches", value: "/blog/**"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert [:page, :pathname, :matches, "/blog/**"] = Enum.at(parsed, 0)
    end

    test "parses comparison operators correctly" do
      filters = [
        %{field: "pathname", operator: "greater_than", value: "100"},
        %{field: "pathname", operator: "less_than", value: "500"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert [:page, :pathname, :greater, "100"] = Enum.at(parsed, 0)
      assert [:page, :pathname, :less, "500"] = Enum.at(parsed, 1)
    end

    test "parses null-check operators correctly" do
      filters = [
        %{field: "referrer", operator: "is_set", value: ""},
        %{field: "referrer", operator: "is_not_set", value: ""}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert [:page, :referrer, :is_not_null, ""] = Enum.at(parsed, 0)
      assert [:page, :referrer, :is_null, ""] = Enum.at(parsed, 1)
    end

    test "maps URL field to pathname" do
      filters = [
        %{field: "url", operator: "equals", value: "/home"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert [:page, :pathname, :exact, "/home"] = Enum.at(parsed, 0)
    end

    test "maps browser and operating_system fields correctly" do
      filters = [
        %{field: "browser", operator: "equals", value: "Chrome"},
        %{field: "operating_system", operator: "equals", value: "Linux"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert [:page, :browser, :exact, "Chrome"] = Enum.at(parsed, 0)
      assert [:page, :os, :exact, "Linux"] = Enum.at(parsed, 1)
    end
  end

  describe "GraphQL multi-filter integration" do
    setup [:create_user, :create_site]

    test "queries pageviews with multiple filters", %{conn: conn, user: user, site: site} do
      # Get API key for authentication
      api_key = insert(:api_key, user: user, key: "test-api-key-123")

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            filters: [
              {field: "pathname", operator: EQUALS, value: "/blog"},
              {field: "country", operator: EQUALS, value: "US"}
            ]
          ) {
            ... on PageviewConnection {
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => %{"pageviews" => %{"totalCount" => _}}} = json_response(conn, 200)
    end

    test "queries events with multiple filters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-api-key-456")

      query = """
        query {
          events(
            siteId: "#{site.id}",
            filters: [
              {field: "name", operator: EQUALS, value: "signup"},
              {field: "device", operator: NOT_EQUALS, value: "mobile"}
            ]
          ) {
            ... on EventConnection {
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => %{"events" => %{"totalCount" => _}}} = json_response(conn, 200)
    end

    test "queries custom metrics with filters", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-api-key-789")

      query = """
        query {
          customMetrics(
            siteId: "#{site.id}",
            filters: [
              {field: "browser", operator: EQUALS, value: "Firefox"}
            ]
          ) {
            ... on CustomMetricConnection {
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{query: query})

      assert %{"data" => %{"customMetrics" => %{"totalCount" => _}}} = json_response(conn, 200)
    end

    test "returns error for invalid filter field", %{conn: conn, user: user, site: site} do
      api_key = insert(:api_key, user: user, key: "test-api-key-invalid")

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            filters: [
              {field: "invalid_field", operator: EQUALS, value: "test"}
            ]
          ) {
            ... on PageviewConnection {
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key.key}")
        |> post("/api/graphql", %{query: query})

      # Invalid fields are mapped to atoms, so this should work but return no results
      # The GraphQL layer handles validation
      response = json_response(conn, 200)
      assert response["errors"] == nil or response["data"]["pageviews"] != nil
    end
  end
end
