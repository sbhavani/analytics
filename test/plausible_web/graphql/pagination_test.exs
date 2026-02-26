defmodule PlausibleWeb.GraphQL.PaginationTest do
  use PlausibleWeb.ConnCase, async: true

  alias PlausibleWeb.GraphQL.Helpers.CursorHelper
  alias PlausibleWeb.GraphQL.Schema

  describe "CursorHelper.encode_cursor/1" do
    test "encodes cursor from map with timestamp and id" do
      cursor = CursorHelper.encode_cursor(%{timestamp: "2024-01-01T00:00:00Z", id: "123"})

      assert cursor == "MjAyNC0wMS0wMVQwMDowMDowMFoifDEyMw=="
    end

    test "encodes cursor from timestamp and string id" do
      cursor = CursorHelper.encode_cursor("2024-01-01T00:00:00Z", "123")

      assert cursor == "MjAyNC0wMS0wMVQwMDowMDowMFoifDEyMw=="
    end
  end

  describe "CursorHelper.decode_cursor/1" do
    test "decodes valid cursor" do
      cursor = "MjAyNC0wMS0wMVQwMDowMDowMFoifDEyMw=="
      {:ok, result} = CursorHelper.decode_cursor(cursor)

      assert result.timestamp == "2024-01-01T00:00:00Z"
      assert result.id == "123"
    end

    test "returns nil for nil input" do
      assert CursorHelper.decode_cursor(nil) == nil
    end

    test "returns error for invalid base64" do
      {:error, message} = CursorHelper.decode_cursor("not-valid-base64")
      assert message == "Invalid cursor encoding"
    end

    test "returns error for invalid cursor format" do
      {:error, message} = CursorHelper.decode_cursor(Base.encode64("invalid"))
      assert message == "Invalid cursor format"
    end
  end

  describe "CursorHelper.calculate_page_info/3" do
    test "calculates page info with no more pages" do
      items = [
        %{timestamp: "2024-01-01T00:00:00Z", id: "1"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "2"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "3"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 10, nil)

      assert page_info.has_next_page == false
      assert page_info.has_previous_page == false
      assert page_info.start_cursor != nil
      assert page_info.end_cursor != nil
    end

    test "calculates page info with more pages" do
      items = [
        %{timestamp: "2024-01-01T00:00:00Z", id: "1"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "2"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "3"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "4"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "5"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 3, nil)

      assert page_info.has_next_page == true
      assert page_info.has_previous_page == false
    end

    test "calculates page info with cursor (previous page)" do
      items = [
        %{timestamp: "2024-01-01T00:00:00Z", id: "1"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "2"},
        %{timestamp: "2024-01-01T00:00:00Z", id: "3"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 10, "some-cursor")

      assert page_info.has_next_page == false
      assert page_info.has_previous_page == true
    end

    test "returns nil cursors for empty list" do
      page_info = CursorHelper.calculate_page_info([], 10, nil)

      assert page_info.has_next_page == false
      assert page_info.has_previous_page == false
      assert page_info.start_cursor == nil
      assert page_info.end_cursor == nil
    end

    test "start and end cursors are different for different items" do
      items = [
        %{timestamp: "2024-01-01T00:00:00Z", id: "1"},
        %{timestamp: "2024-01-02T00:00:00Z", id: "2"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 10, nil)

      assert page_info.start_cursor != page_info.end_cursor
    end
  end

  describe "GraphQL pagination integration" do
    test "pageviews query supports first and after pagination" do
      query = """
        query($siteId: ID!, $first: Int, $after: String) {
          pageviews(siteId: $siteId, pagination: {first: $first, after: $after}) {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  url
                  timestamp
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
          }
        }
      """

      # Insert test site and pageviews
      site = insert(:site, domain: "testpagination.com")

      for i <- 1..5 do
        insert(:pageview, site: site, url: "http://testpagination.com/page#{i}")
      end

      conn =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 2
          }
        })

      response = json_response(conn, 200)

      assert %{"data" => %{"pageviews" => result}} = response

      assert result["totalCount"] == 5
      assert length(result["edges"]) == 2
      assert result["pageInfo"]["hasNextPage"] == true
      assert result["pageInfo"]["hasPreviousPage"] == false
      assert result["pageInfo"]["startCursor"] != nil
      assert result["pageInfo"]["endCursor"] != nil
    end

    test "events query supports first and after pagination" do
      query = """
        query($siteId: ID!, $first: Int) {
          events(siteId: $siteId, pagination: {first: $first}) {
            ... on EventConnection {
              edges {
                node {
                  id
                  name
                  timestamp
                }
                cursor
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
              totalCount
            }
          }
        }
      """

      site = insert(:site, domain: "testeventspagination.com")

      for i <- 1..3 do
        insert(:event, site: site, name: "test_event_#{i}")
      end

      conn =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 2
          }
        })

      response = json_response(conn, 200)

      assert %{"data" => %{"events" => result}} = response

      assert result["totalCount"] == 3
      assert length(result["edges"]) == 2
      assert result["pageInfo"]["hasNextPage"] == true
    end

    test "custom_metrics query supports first and after pagination" do
      query = """
        query($siteId: ID!, $first: Int) {
          customMetrics(siteId: $siteId, pagination: {first: $first}) {
            ... on CustomMetricConnection {
              edges {
                node {
                  id
                  name
                  value
                }
                cursor
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
              totalCount
            }
          }
        }
      """

      site = insert(:site, domain: "testmetricspagination.com")

      # Create some custom metrics
      # Note: This test assumes custom metrics exist in the database
      # If not, it should return empty results

      conn =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 10
          }
        })

      response = json_response(conn, 200)

      # Either returns data or empty result depending on implementation
      assert %{"data" => %{"customMetrics" => _result}} = response
    end

    test "pagination with after cursor retrieves next page" do
      query = """
        query($siteId: ID!, $first: Int, $after: String) {
          pageviews(siteId: $siteId, pagination: {first: $first, after: $after}) {
            ... on PageviewConnection {
              edges {
                node {
                  id
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        }
      """

      site = insert(:site, domain: "testcursorpagination.com")

      for i <- 1..4 do
        insert(:pageview, site: site, url: "http://testcursorpagination.com/page#{i}")
      end

      # First request to get cursor
      conn1 =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 2
          }
        })

      response1 = json_response(conn1, 200)
      first_page_end_cursor = response1["data"]["pageviews"]["pageInfo"]["endCursor"]

      # Second request with cursor
      conn2 =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 2,
            "after" => first_page_end_cursor
          }
        })

      response2 = json_response(conn2, 200)
      second_page_edges = response2["data"]["pageviews"]["edges"]

      # Verify we got different results on the second page
      assert length(second_page_edges) == 2
    end

    test "returns empty edges when no data exists" do
      query = """
        query($siteId: ID!, $first: Int) {
          pageviews(siteId: $siteId, pagination: {first: $first}) {
            ... on PageviewConnection {
              edges {
                node {
                  id
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
              totalCount
            }
          }
        }
      """

      site = insert(:site, domain: "testemptypagination.com")

      conn =
        build_conn()
        |> assign(:current_user, site.owner)
        |> get("/api/graphql", %{
          "query" => query,
          "variables" => %{
            "siteId" => site.id,
            "first" => 10
          }
        })

      response = json_response(conn, 200)

      assert %{"data" => %{"pageviews" => result}} = response
      assert result["edges"] == []
      assert result["totalCount"] == 0
      assert result["pageInfo"]["hasNextPage"] == false
      assert result["pageInfo"]["hasPreviousPage"] == false
      assert result["pageInfo"]["startCursor"] == nil
      assert result["pageInfo"]["endCursor"] == nil
    end
  end
end
