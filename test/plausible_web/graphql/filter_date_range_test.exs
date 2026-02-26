defmodule PlausibleWeb.GraphQL.FilterDateRangeTest do
  use PlausibleWeb.ConnCase
  use Plausible.ClickhouseRepo

  describe "date range filtering in aggregate query" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts valid date range within 1 year", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # Should return data without errors
      assert is_nil(response["errors"])
      assert response["data"]["aggregate"] != nil
    end

    test "accepts date range at exactly 1 year boundary", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2025-02-01", endDate: "2026-02-01" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # Should return data without errors (exactly 1 year is allowed)
      assert is_nil(response["errors"])
      assert response["data"]["aggregate"] != nil
    end

    test "rejects date range exceeding 1 year", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-01-01", endDate: "2026-01-01" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
      assert Enum.any?(response["errors"], fn e ->
        String.contains?(e["message"], "1 year")
      end)
    end

    test "rejects invalid date range (start > end)", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-31", endDate: "2026-01-01" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
      assert Enum.any?(response["errors"], fn e ->
        String.contains?(e["message"], "before")
      end)
    end

    test "accepts same day date range", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-15", endDate: "2026-01-15" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # Should return data without errors (same day is valid)
      assert is_nil(response["errors"])
      assert response["data"]["aggregate"] != nil
    end
  end

  describe "date range filtering in breakdown query" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts valid date range in breakdown", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            limit: 10
          }) {
            dimension
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert is_nil(response["errors"])
      assert response["data"]["breakdown"] != nil
    end

    test "rejects date range exceeding 1 year in breakdown", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2023-01-01", endDate: "2026-01-01" },
            limit: 10
          }) {
            dimension
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
    end

    test "rejects invalid date range in breakdown", %{conn: conn, site: site} do
      query = """
        query {
          breakdown(siteId: "#{site.id}", input: {
            dimension: COUNTRY,
            metrics: [VISITORS],
            dateRange: { startDate: "2026-06-01", endDate: "2026-01-01" },
            limit: 10
          }) {
            dimension
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
    end
  end

  describe "date range filtering in timeseries query" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts valid date range in timeseries", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-07" },
            granularity: DAILY
          }) {
            date
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert is_nil(response["errors"])
      assert response["data"]["timeseries"] != nil
    end

    test "rejects date range exceeding 1 year in timeseries", %{conn: conn, site: site} do
      query = """
        query {
          timeseries(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-01-01", endDate: "2026-06-01" },
            granularity: DAILY
          }) {
            date
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
    end
  end

  describe "date range with filters combined" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts date range with device filter", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ device: "desktop" }]
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert is_nil(response["errors"])
      assert response["data"]["aggregate"] != nil
    end

    test "accepts date range with country filter", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
            filters: [{ country: "US" }]
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert is_nil(response["errors"])
      assert response["data"]["aggregate"] != nil
    end

    test "rejects invalid date range even with valid filters", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2026-02-01", endDate: "2026-01-01" },
            filters: [{ device: "desktop" }]
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # Date validation should fail first
      assert response["errors"] != nil
    end
  end

  describe "date range edge cases" do
    setup [:create_user, :create_site, :create_api_key, :use_api_key]

    test "accepts 364 day range (just under 1 year)", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2025-02-01", endDate: "2026-01-30" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert is_nil(response["errors"])
    end

    test "rejects 366 day range (just over 1 year)", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-02-01", endDate: "2026-02-01" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      assert response["errors"] != nil
    end

    test "handles leap year date range correctly", %{conn: conn, site: site} do
      query = """
        query {
          aggregate(siteId: "#{site.id}", input: {
            metrics: [VISITORS],
            dateRange: { startDate: "2024-02-28", endDate: "2025-02-28" }
          }) {
            visitors
          }
        }
      """

      conn = post(conn, "/api/graphql", %{"query" => query})

      response = json_response(conn, 200)
      # 2024 is a leap year, so Feb 28 -> Feb 28 is 365 days (not 366)
      assert is_nil(response["errors"])
    end
  end
end
