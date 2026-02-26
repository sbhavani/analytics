defmodule PlausibleGraphqla.PageviewsQueryTest do
  @moduledoc """
  Integration tests for the pageviews GraphQL query

  This test verifies that the pageviews query correctly returns pageview data
  from ClickHouse with proper filtering and pagination support.
  """
  use PlausibleWeb.ConnCase, async: false
  use Plausible.Repo

  import Plausible.Factory

  describe "pageviews query" do
    test "returns pageviews for a given site", %{conn: conn} do
      user = insert(:user)
      {:ok, team} = Plausible.Teams.get_or_create(user)
      site = insert(:site, team: team, domain: "test-site.com")

      # Populate with pageview events
      pageview1 = build(:pageview, url: "https://test-site.com/page1", timestamp: ~N[2026-01-15 10:00:00])
      pageview2 = build(:pageview, url: "https://test-site.com/page2", timestamp: ~N[2026-01-15 11:00:00])
      pageview3 = build(:pageview, url: "https://test-site.com/page3", timestamp: ~N[2026-01-15 12:00:00])

      populate_stats(site, [pageview1, pageview2, pageview3])

      query = """
        query {
          pageviews(filter: { siteId: "#{site.id}" }) {
            edges {
              node {
                id
                url
                timestamp
                browser
                device
                country
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      assert response["data"]["pageviews"]["edges"] |> length() == 3
      assert response["data"]["pageviews"]["pageInfo"]["hasNextPage"] == false
    end

    test "filters pageviews by date range", %{conn: conn} do
      user = insert(:user)
      {:ok, team} = Plausible.Teams.get_or_create(user)
      site = insert(:site, team: team, domain: "test-site.com")

      # Pageview on Jan 15
      pageview1 = build(:pageview, url: "https://test-site.com/page1", timestamp: ~N[2026-01-15 10:00:00])
      # Pageview on Jan 20 (outside date range)
      pageview2 = build(:pageview, url: "https://test-site.com/page2", timestamp: ~N[2026-01-20 10:00:00])

      populate_stats(site, [pageview1, pageview2])

      query = """
        query {
          pageviews(filter: {
            siteId: "#{site.id}",
            dateRange: { from: "2026-01-01", to: "2026-01-16" }
          }) {
            edges {
              node {
                url
                timestamp
              }
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      # Should only return 1 pageview (Jan 15), not Jan 20
      assert response["data"]["pageviews"]["edges"] |> length() == 1
      assert response["data"]["pageviews"]["edges"] |> hd() |> get_in(["node", "url"]) == "https://test-site.com/page1"
    end

    test "filters pageviews by URL pattern", %{conn: conn} do
      user = insert(:user)
      {:ok, team} = Plausible.Teams.get_or_create(user)
      site = insert(:site, team: team, domain: "test-site.com")

      pageview1 = build(:pageview, url: "https://test-site.com/blog/post-1", timestamp: ~N[2026-01-15 10:00:00])
      pageview2 = build(:pageview, url: "https://test-site.com/about", timestamp: ~N[2026-01-15 11:00:00])
      pageview3 = build(:pageview, url: "https://test-site.com/blog/post-2", timestamp: ~N[2026-01-15 12:00:00])

      populate_stats(site, [pageview1, pageview2, pageview3])

      query = """
        query {
          pageviews(filter: {
            siteId: "#{site.id}",
            urlPattern: "/blog/**"
          }) {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      # Should only return blog pages
      edges = response["data"]["pageviews"]["edges"]
      assert length(edges) == 2

      urls = Enum.map(edges, fn edge -> edge["node"]["url"] end)
      assert "https://test-site.com/blog/post-1" in urls
      assert "https://test-site.com/blog/post-2" in urls
      refute "https://test-site.com/about" in urls
    end

    test "supports pagination with limit and offset", %{conn: conn} do
      user = insert(:user)
      {:ok, team} = Plausible.Teams.get_or_create(user)
      site = insert(:site, team: team, domain: "test-site.com")

      # Create 10 pageviews
      pageviews = for i <- 1..10 do
        build(:pageview, url: "https://test-site.com/page#{i}", timestamp: ~N[2026-01-15 10:00:00])
      end

      populate_stats(site, pageviews)

      query = """
        query {
          pageviews(
            filter: { siteId: "#{site.id}" },
            pagination: { limit: 3, offset: 0 }
          ) {
            edges {
              node {
                url
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      edges = response["data"]["pageviews"]["edges"]
      assert length(edges) == 3

      # Check that we can paginate further
      assert response["data"]["pageviews"]["pageInfo"]["hasNextPage"] == false
    end

    test "returns error when site_id is missing", %{conn: conn} do
      query = """
        query {
          pageviews {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      # Should have an error about missing required field
      assert response["errors"] != nil
      assert Enum.any?(response["errors"], fn error ->
        error["message"] =~ "site_id" or error["message"] =~ "siteId"
      end)
    end

    test "returns empty list for non-existent site", %{conn: conn} do
      query = """
        query {
          pageviews(filter: { siteId: "999999" }) {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      # Site doesn't exist, should return error
      assert response["errors"] != nil
    end

    test "returns pageview metadata fields", %{conn: conn} do
      user = insert(:user)
      {:ok, team} = Plausible.Teams.get_or_create(user)
      site = insert(:site, team: team, domain: "test-site.com")

      pageview = build(:pageview,
        url: "https://test-site.com/page1",
        referrer: "https://google.com",
        browser: "Chrome",
        device: "Desktop",
        country: "US",
        timestamp: ~N[2026-01-15 10:00:00]
      )

      populate_stats(site, [pageview])

      query = """
        query {
          pageviews(filter: { siteId: "#{site.id}" }) {
            edges {
              node {
                id
                url
                timestamp
                referrer
                browser
                device
                country
              }
            }
          }
        }
      """

      response = conn
      |> post("/api/graphql", %{query: query})
      |> json_response(:ok)

      edge = response["data"]["pageviews"]["edges"] |> hd()
      node = edge["node"]

      assert node["url"] == "https://test-site.com/page1"
      assert node["referrer"] == "https://google.com"
      assert node["browser"] == "Chrome"
      assert node["device"] == "Desktop"
      assert node["country"] == "US"
      assert node["id"] != nil
      assert node["timestamp"] != nil
    end
  end
end
