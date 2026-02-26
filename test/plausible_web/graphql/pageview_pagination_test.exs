defmodule PlausibleWeb.GraphQL.PageviewPaginationTest do
  use PlausibleWeb.ConnCase
  import Plausible.Factory

  describe "pageview pagination" do
    setup [:create_user, :log_in, :create_site]

    test "returns paginated pageviews with first parameter", %{conn: conn, site: site, user: user} do
      # Create more pageviews than the default limit
      populate_stats(site, [
        build(:pageview, pathname: "/page-1"),
        build(:pageview, pathname: "/page-2"),
        build(:pageview, pathname: "/page-3")
      ])

      query = """
        query {
          pageviews(siteId: #{site.id}, pagination: { first: 2 }) {
            ... on PageviewConnection {
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
        }
      """

      conn = post(conn, "/api/graphql", %{query: query})

      assert %{"data" => %{"pageviews" => result}} = json_response(conn, 200)

      assert result["totalCount"] == 3
      assert length(result["edges"]) == 2
      assert result["pageInfo"]["hasNextPage"] == true
      assert result["pageInfo"]["hasPreviousPage"] == false
      assert result["pageInfo"]["startCursor"] != nil
      assert result["pageInfo"]["endCursor"] != nil
    end

    test "returns all pageviews when under limit", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, pathname: "/page-1"),
        build(:pageview, pathname: "/page-2")
      ])

      query = """
        query {
          pageviews(siteId: #{site.id}, pagination: { first: 10 }) {
            ... on PageviewConnection {
              edges {
                node {
                  pathname
                }
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

      conn = post(conn, "/api/graphql", %{query: query})

      assert %{"data" => %{"pageviews" => result}} = json_response(conn, 200)

      assert result["totalCount"] == 2
      assert length(result["edges"]) == 2
      assert result["pageInfo"]["hasNextPage"] == false
      assert result["pageInfo"]["hasPreviousPage"] == false
    end

    test "navigates to next page using after cursor", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, pathname: "/page-1"),
        build(:pageview, pathname: "/page-2"),
        build(:pageview, pathname: "/page-3")
      ])

      # First request to get first page and cursor
      first_page_query = """
        query {
          pageviews(siteId: #{site.id}, pagination: { first: 2 }) {
            ... on PageviewConnection {
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
        }
      """

      conn = post(conn, "/api/graphql", %{query: first_page_query})
      assert %{"data" => %{"pageviews" => first_result}} = json_response(conn, 200)

      end_cursor = first_result["pageInfo"]["endCursor"]
      assert first_result["pageInfo"]["hasNextPage"] == true

      # Second request to get second page using cursor
      second_page_query = """
        query {
          pageviews(siteId: #{site.id}, pagination: { first: 2, after: "#{end_cursor}" }) {
            ... on PageviewConnection {
              edges {
                node {
                  pathname
                }
              }
              pageInfo {
                hasNextPage
                hasPreviousPage
              }
            }
          }
        }
      """

      conn = post(conn, "/api/graphql", %{query: second_page_query})
      assert %{"data" => %{"pageviews" => second_result}} = json_response(conn, 200)

      # Second page should have one item (the third pageview)
      assert length(second_result["edges"]) == 1
      assert second_result["pageInfo"]["hasNextPage"] == false
      assert second_result["pageInfo"]["hasPreviousPage"] == true
    end

    test "handles empty result", %{conn: conn, site: site} do
      # No pageviews created

      query = """
        query {
          pageviews(siteId: #{site.id}, pagination: { first: 10 }) {
            ... on PageviewConnection {
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
        }
      """

      conn = post(conn, "/api/graphql", %{query: query})

      assert %{"data" => %{"pageviews" => result}} = json_response(conn, 200)

      assert result["totalCount"] == 0
      assert result["edges"] == []
      assert result["pageInfo"]["hasNextPage"] == false
      assert result["pageInfo"]["hasPreviousPage"] == false
      assert result["pageInfo"]["startCursor"] == nil
      assert result["pageInfo"]["endCursor"] == nil
    end

    test "uses default pagination when not specified", %{conn: conn, site: site} do
      populate_stats(site, [
        build(:pageview, pathname: "/page-1"),
        build(:pageview, pathname: "/page-2"),
        build(:pageview, pathname: "/page-3")
      ])

      query = """
        query {
          pageviews(siteId: #{site.id}) {
            ... on PageviewConnection {
              edges {
                node {
                  pathname
                }
              }
              pageInfo {
                hasNextPage
              }
              totalCount
            }
          }
        }
      """

      conn = post(conn, "/api/graphql", %{query: query})

      assert %{"data" => %{"pageviews" => result}} = json_response(conn, 200)

      # Default limit is 50, so should return all 3
      assert result["totalCount"] == 3
      assert length(result["edges"]) == 3
      assert result["pageInfo"]["hasNextPage"] == false
    end

    test "returns error for invalid site ID", %{conn: conn} do
      query = """
        query {
          pageviews(siteId: 999999, pagination: { first: 10 }) {
            ... on PageviewConnection {
              edges {
                node {
                  pathname
                }
              }
            }
          }
        }
      """

      conn = post(conn, "/api/graphql", %{query: query})

      assert %{"errors" => [%{"message" => "Site not found"}]} = json_response(conn, 200)
    end

    test "requires authentication", %{conn: conn, site: site} do
      # Create a new conn without logging in
      query = """
        query {
          pageviews(siteId: #{site.id}) {
            ... on PageviewConnection {
              edges {
                node {
                  pathname
                }
              }
            }
          }
        }
      """

      conn = post(conn, "/api/graphql", %{query: query})

      # Should return authentication error
      assert %{"errors" => errors} = json_response(conn, 200)
      assert Enum.any?(errors, fn e -> e["message"] =~ "Authentication required" end)
    end
  end
end
