defmodule PlausibleWeb.GraphQL.PageviewTest do
  use PlausibleWeb.ConnCase, async: true

  describe "pageviews query" do
    test "returns unauthorized when not authenticated", %{conn: conn} do
      query = """
        query {
          pageviews(siteId: "1") {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  pathname
                }
              }
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> post("/api/graphql", %{query: query})

      assert %{
               "errors" => [
                 %{
                   "message" => "Authentication required"
                 }
               ]
             } = json_response(conn, 200)
    end

    test "returns pageview data with valid authentication", %{conn: conn} do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(siteId: "#{site.id}") {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  url
                  pathname
                  visitorId
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

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "data" => %{
                 "pageviews" => %{
                   "edges" => edges,
                   "pageInfo" => page_info,
                   "totalCount" => total_count
                 }
               }
             } = json_response(conn, 200)

      assert is_list(edges)
      assert is_map(page_info)
      assert is_integer(total_count)
      assert page_info["hasNextPage"] == false
      assert page_info["hasPreviousPage"] == false
    end

    test "returns pageview data with date range filter", %{conn: conn} do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            dateRange: {
              startDate: "2026-01-01"
              endDate: "2026-01-31"
            }
          ) {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  pathname
                }
              }
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "data" => %{
                 "pageviews" => %{
                   "edges" => _,
                   "totalCount" => _
                 }
               }
             } = json_response(conn, 200)
    end

    test "returns pageview data with pagination", %{conn: conn} do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            pagination: {
              first: 10
            }
          ) {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  pathname
                }
                cursor
              }
              pageInfo {
                hasNextPage
                endCursor
              }
              totalCount
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "data" => %{
                 "pageviews" => %{
                   "edges" => edges,
                   "pageInfo" => page_info,
                   "totalCount" => total_count
                 }
               }
             } = json_response(conn, 200)

      assert length(edges) <= 10
      assert is_boolean(page_info["hasNextPage"])
      assert is_integer(total_count)
    end

    test "returns aggregation result when aggregation is specified", %{conn: conn} do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(
            siteId: "#{site.id}",
            dateRange: {
              startDate: "2026-01-01"
              endDate: "2026-01-31"
            },
            aggregation: {
              type: COUNT
              dimension: "pathname"
            }
          ) {
            ... on AggregateResult {
              aggregationType
              value
              dimension
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "data" => %{
                 "pageviews" => %{
                   "aggregationType" => _,
                   "value" => _,
                   "dimension" => _
                 }
               }
             } = json_response(conn, 200)
    end

    test "returns error for non-existent site", %{conn: conn} do
      user = insert(:user)

      query = """
        query {
          pageviews(siteId: "999999") {
            ... on PageviewConnection {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "errors" => [
                 %{
                   "message" => "Site not found",
                   "extensions" => %{
                     "code" => "NOT_FOUND"
                   }
                 }
               ]
             } = json_response(conn, 200)
    end

    test "returns site the user does not have access to", %{conn: conn} do
      user = insert(:user)
      # Create a site that the user is NOT a member of
      other_site = insert(:site, members: [insert(:user)])

      query = """
        query {
          pageviews(siteId: "#{other_site.id}") {
            ... on PageviewConnection {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "errors" => [
                 %{
                   "message" => "Site not found",
                   "extensions" => %{
                     "code" => "NOT_FOUND"
                   }
                 }
               ]
             } = json_response(conn, 200)
    end

    test "returns pageview fields correctly", %{conn: conn} do
      user = insert(:user)
      site = insert(:site, members: [user])

      query = """
        query {
          pageviews(siteId: "#{site.id}") {
            ... on PageviewConnection {
              edges {
                node {
                  id
                  url
                  pathname
                  timestamp
                  visitorId
                  referrer
                  sessionId
                  country
                  device
                  browser
                  operatingSystem
                }
              }
            }
          }
        }
      """

      conn =
        conn
        |> init_session()
        |> put_session(:current_user, user)
        |> post("/api/graphql", %{query: query})

      assert %{
               "data" => %{
                 "pageviews" => %{
                   "edges" => [
                     %{
                       "node" => node
                     }
                     | _
                   ]
                 }
               }
             } = json_response(conn, 200)

      assert node["id"] != nil
      assert node["url"] != nil
      assert node["pathname"] != nil
      assert node["timestamp"] != nil
      assert node["visitorId"] != nil
      # Optional fields can be nil
      assert node["referrer"] == nil or is_binary(node["referrer"])
      assert node["sessionId"] == nil or is_binary(node["sessionId"])
      assert node["country"] == nil or is_binary(node["country"])
      assert node["device"] != nil
      assert node["browser"] != nil
      assert node["operatingSystem"] != nil
    end
  end
end
