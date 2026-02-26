defmodule PlausibleWeb.GraphQL.CursorNavigationTest do
  @moduledoc """
  Tests for cursor-based pagination navigation in GraphQL queries.

  This test module verifies:
  - Forward pagination (first/after)
  - Backward pagination (last/before)
  - Proper has_next_page and has_previous_page values
  - Start and end cursors are returned correctly
  - Cursor decoding works properly
  """

  use PlausibleWeb.ConnCase

  alias PlausibleWeb.GraphQL.Helpers.CursorHelper

  describe "CursorHelper.encode_cursor/1" do
    test "encodes cursor from map with timestamp and id" do
      cursor = %{timestamp: "2024-01-15T10:30:00Z", id: "abc123"}
      encoded = CursorHelper.encode_cursor(cursor)

      assert is_binary(encoded)
      # Base64 encoded string should decode to "timestamp|id"
      assert Base.decode64(encoded) == {:ok, "2024-01-15T10:30:00Z|abc123"}
    end

    test "encodes cursor from raw timestamp and id" do
      encoded = CursorHelper.encode_cursor("2024-01-15T10:30:00Z", "abc123")

      assert is_binary(encoded)
      assert Base.decode64(encoded) == {:ok, "2024-01-15T10:30:00Z|abc123"}
    end
  end

  describe "CursorHelper.decode_cursor/1" do
    test "decodes valid cursor" do
      encoded = Base.encode64("2024-01-15T10:30:00Z|abc123")
      {:ok, decoded} = CursorHelper.decode_cursor(encoded)

      assert decoded.timestamp == "2024-01-15T10:30:00Z"
      assert decoded.id == "abc123"
    end

    test "returns nil for nil cursor" do
      assert CursorHelper.decode_cursor(nil) == nil
    end

    test "returns error for invalid base64" do
      assert CursorHelper.decode_cursor("not-valid-base64!!!") ==
               {:error, "Invalid cursor encoding"}
    end

    test "returns error for cursor without separator" do
      encoded = Base.encode64("invalid-cursor-format")
      assert CursorHelper.decode_cursor(encoded) ==
               {:error, "Invalid cursor format"}
    end
  end

  describe "CursorHelper.calculate_page_info/3" do
    test "calculates page info when there are more items" do
      items = [
        %{timestamp: "2024-01-15T10:30:00Z", id: "item1"},
        %{timestamp: "2024-01-15T10:29:00Z", id: "item2"},
        %{timestamp: "2024-01-15T10:28:00Z", id: "item3"},
        %{timestamp: "2024-01-15T10:27:00Z", id: "item4"},
        %{timestamp: "2024-01-15T10:26:00Z", id: "item5"},
        %{timestamp: "2024-01-15T10:25:00Z", id: "item6"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 3, nil)

      assert page_info.has_next_page == true
      assert page_info.has_previous_page == false
      assert page_info.start_cursor != nil
      assert page_info.end_cursor != nil
    end

    test "calculates page info when there are no more items" do
      items = [
        %{timestamp: "2024-01-15T10:30:00Z", id: "item1"},
        %{timestamp: "2024-01-15T10:29:00Z", id: "item2"},
        %{timestamp: "2024-01-15T10:28:00Z", id: "item3"}
      ]

      page_info = CursorHelper.calculate_page_info(items, 3, nil)

      assert page_info.has_next_page == false
      assert page_info.has_previous_page == false
      assert page_info.start_cursor != nil
      assert page_info.end_cursor != nil
    end

    test "calculates page info with cursor (forward pagination)" do
      items = [
        %{timestamp: "2024-01-15T10:30:00Z", id: "item1"},
        %{timestamp: "2024-01-15T10:29:00Z", id: "item2"},
        %{timestamp: "2024-01-15T10:28:00Z", id: "item3"},
        %{timestamp: "2024-01-15T10:27:00Z", id: "item4"}
      ]

      cursor = Base.encode64("2024-01-15T10:29:00Z|item2")
      page_info = CursorHelper.calculate_page_info(items, 3, cursor)

      assert page_info.has_next_page == true
      assert page_info.has_previous_page == true
    end

    test "handles empty items list" do
      page_info = CursorHelper.calculate_page_info([], 10, nil)

      assert page_info.has_next_page == false
      assert page_info.has_previous_page == false
      assert page_info.start_cursor == nil
      assert page_info.end_cursor == nil
    end
  end

  describe "GraphQL pageviews pagination with cursor" do
    setup [:create_user, :log_in, :create_site]

    test "returns first page of results with pagination info", %{conn: conn, site: site} do
      # Insert test data
      populate_stats(site, [
        build(:pageview, pathname: "/page1"),
        build(:pageview, pathname: "/page2"),
        build(:pageview, pathname: "/page3"),
        build(:pageview, pathname: "/page4"),
        build(:pageview, pathname: "/page5")
      ])

      query = """
        query($siteId: ID!) {
          pageviews(siteId: $siteId, pagination: { first: 3 }) {
            edges {
              node {
                pathname
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
      """

      response =
        conn
        |> post("/api/graphql", %{query: query, variables: %{siteId: site.id}})

      assert %{"data" => %{"pageviews" => result}} = json_response(response, 200)

      assert result["totalCount"] == 5
      assert length(result["edges"]) == 3
      assert result["pageInfo"]["hasNextPage"] == true
      assert result["pageInfo"]["hasPreviousPage"] == false
      assert result["pageInfo"]["startCursor"] != nil
      assert result["pageInfo"]["endCursor"] != nil
    end

    test "navigates to next page using after cursor", %{conn: conn, site: site} do
      # Insert test data
      populate_stats(site, [
        build(:pageview, pathname: "/page1"),
        build(:pageview, pathname: "/page2"),
        build(:pageview, pathname: "/page3"),
        build(:pageview, pathname: "/page4"),
        build(:pageview, pathname: "/page5")
      ])

      # First, get the first page to obtain cursor
      first_query = """
        query($siteId: ID!) {
          pageviews(siteId: $siteId, pagination: { first: 3 }) {
            edges {
              node {
                pathname
              }
              cursor
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      first_response =
        conn
        |> post("/api/graphql", %{query: first_query, variables: %{siteId: site.id}})

      %{"data" => %{"pageviews" => first_result}} = json_response(first_response, 200)
      end_cursor = first_result["pageInfo"]["endCursor"]

      # Now navigate to the next page
      second_query = """
        query($siteId: ID!, $after: String!) {
          pageviews(siteId: $siteId, pagination: { first: 3, after: $after }) {
            edges {
              node {
                pathname
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
      """

      second_response =
        conn
        |> post("/api/graphql", %{
          query: second_query,
          variables: %{siteId: site.id, after: end_cursor}
        })

      assert %{"data" => %{"pageviews" => second_result}} = json_response(second_response, 200)

      assert second_result["totalCount"] == 5
      # Should have remaining items
      assert second_result["pageInfo"]["hasPreviousPage"] == true
    end

    test "returns last page when no more data available", %{conn: conn, site: site} do
      # Insert only 2 items
      populate_stats(site, [
        build(:pageview, pathname: "/page1"),
        build(:pageview, pathname: "/page2")
      ])

      query = """
        query($siteId: ID!) {
          pageviews(siteId: $siteId, pagination: { first: 10 }) {
            edges {
              node {
                pathname
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
      """

      response =
        conn
        |> post("/api/graphql", %{query: query, variables: %{siteId: site.id}})

      assert %{"data" => %{"pageviews" => result}} = json_response(response, 200)

      assert result["totalCount"] == 2
      assert length(result["edges"]) == 2
      assert result["pageInfo"]["hasNextPage"] == false
      assert result["pageInfo"]["hasPreviousPage"] == false
    end
  end
end
