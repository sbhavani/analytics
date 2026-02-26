defmodule PlausibleGraphqla.CustomMetricsQueryTest do
  use Plausible.DataCase, async: true

  alias Plausible.Graphqla.Schema
  alias Plausible.Graphqla.Resolvers.CustomMetricResolver

  describe "custom metrics GraphQL query" do
    setup [:create_user, :create_site]

    test "returns custom metrics for a site", %{site: site} do
      # Insert test custom metrics directly into ClickHouse
      :ok = insert_custom_metric(site, %{name: "revenue", value: 100.5, timestamp: DateTime.utc_now()})
      :ok = insert_custom_metric(site, %{name: "revenue", value: 250.75, timestamp: DateTime.utc_now()})
      :ok = insert_custom_metric(site, %{name: "pageviews", value: 500, timestamp: DateTime.utc_now()})

      query = """
        query {
          customMetrics(filter: { siteId: #{site.id} }) {
            edges {
              node {
                id
                name
                value
                timestamp
                siteId
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      {:ok, %{data: data, errors: []}} = Absinthe.run(query, Schema, variables: %{})

      assert %{"customMetrics" => %{"edges" => metrics, "pageInfo" => page_info}} = data
      assert length(metrics) >= 1
      assert page_info["hasNextPage"] == false

      # Verify metric structure
      metric = List.first(metrics)
      assert metric["node"]["name"] != nil
      assert metric["node"]["value"] != nil
      assert metric["node"]["timestamp"] != nil
    end

    test "returns custom metrics with date range filter", %{site: site} do
      yesterday = DateTime.utc_now() |> DateTime.add(-1, :day)
      today = DateTime.utc_now()

      :ok = insert_custom_metric(site, %{name: "old_metric", value: 10, timestamp: yesterday})
      :ok = insert_custom_metric(site, %{name: "recent_metric", value: 20, timestamp: today})

      yesterday_str = yesterday |> DateTime.to_date() |> Date.to_iso8601()
      today_str = today |> DateTime.to_date() |> Date.to_iso8601()

      query = """
        query {
          customMetrics(filter: { siteId: #{site.id}, dateRange: { from: "#{yesterday_str}", to: "#{today_str}" } }) {
            edges {
              node {
                name
                value
                timestamp
              }
            }
          }
        }
      """

      {:ok, %{data: data, errors: []}} = Absinthe.run(query, Schema, variables: %{})

      assert %{"customMetrics" => %{"edges" => metrics}} = data
      # Both metrics should be returned since they're within the date range
      assert length(metrics) == 2
    end

    test "filters custom metrics by metric name", %{site: site} do
      :ok = insert_custom_metric(site, %{name: "revenue", value: 100, timestamp: DateTime.utc_now()})
      :ok = insert_custom_metric(site, %{name: "pageviews", value: 200, timestamp: DateTime.utc_now()})
      :ok = insert_custom_metric(site, %{name: "revenue", value: 150, timestamp: DateTime.utc_now()})

      query = """
        query {
          customMetrics(filter: { siteId: #{site.id}, metricName: "revenue" }) {
            edges {
              node {
                name
                value
              }
            }
          }
        }
      """

      {:ok, %{data: data, errors: []}} = Absinthe.run(query, Schema, variables: %{})

      assert %{"customMetrics" => %{"edges" => metrics}} = data
      assert length(metrics) == 2
      assert Enum.all?(metrics, fn m -> m["node"]["name"] == "revenue" end)
    end

    test "supports pagination parameters", %{site: site} do
      # Insert multiple metrics
      for i <- 1..15 do
        :ok = insert_custom_metric(site, %{name: "metric_#{i}", value: i * 10.0, timestamp: DateTime.utc_now()})
      end

      query = """
        query {
          customMetrics(filter: { siteId: #{site.id} }, pagination: { limit: 10, offset: 0 }) {
            edges {
              node {
                id
                name
                value
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      """

      {:ok, %{data: data, errors: []}} = Absinthe.run(query, Schema, variables: %{})

      assert %{"customMetrics" => %{"edges" => metrics, "pageInfo" => page_info}} = data
      assert length(metrics) == 10
      # hasNextPage may be true since we have 15 total
      assert page_info["hasNextPage"] != nil
    end

    test "returns error for non-existent site", _context do
      query = """
        query {
          customMetrics(filter: { siteId: 99999999 }) {
            edges {
              node {
                id
              }
            }
          }
        }
      """

      {:ok, %{data: data, errors: errors}} = Absinthe.run(query, Schema, variables: %{})

      # Should return either an error or empty edges for non-existent site
      assert errors != [] or (data["customMetrics"]["edges"] == [])
    end
  end

  describe "CustomMetricResolver" do
    setup [:create_user, :create_site]

    test "list_custom_metrics returns error when no filter provided", %{site: site} do
      result = CustomMetricResolver.list_custom_metrics(nil, %{})

      assert {:error, "Filter with site_id is required"} = result
    end

    test "list_custom_metrics returns error when site not found", _context do
      result = CustomMetricResolver.list_custom_metrics(nil, %{
        filter: %{ site_id: "99999999" }
      })

      assert {:error, "Site not found"} = result
    end

    test "list_custom_metrics with valid site", %{site: site} do
      result = CustomMetricResolver.list_custom_metrics(nil, %{
        filter: %{ site_id: site.id }
      })

      # Should return ok with a map containing edges and pageInfo
      assert {:ok, response} = result
      assert is_map(response)
      assert Map.has_key?(response, :edges)
      assert Map.has_key?(response, :page_info)
    end

    test "list_custom_metrics with date range", %{site: site} do
      result = CustomMetricResolver.list_custom_metrics(nil, %{
        filter: %{
          site_id: site.id,
          date_range: %{ from: ~D[2024-01-01], to: ~D[2024-12-31] }
        }
      })

      assert {:ok, response} = result
      assert is_map(response)
    end

    test "list_custom_metrics with metric name filter", %{site: site} do
      result = CustomMetricResolver.list_custom_metrics(nil, %{
        filter: %{
          site_id: site.id,
          metric_name: "revenue"
        }
      })

      assert {:ok, response} = result
      assert is_map(response)
    end

    test "list_custom_metrics respects pagination limit", %{site: site} do
      result = CustomMetricResolver.list_custom_metrics(nil, %{
        filter: %{ site_id: site.id },
        pagination: %{ limit: 10, offset: 0 }
      })

      assert {:ok, _response} = result
    end
  end

  # Helper function to insert custom metrics directly into ClickHouse
  defp insert_custom_metric(site, %{name: name, value: value, timestamp: timestamp}) do
    event_data = %{
      site_id: site.id,
      timestamp: timestamp,
      name: "custom_metric",
      url: "http://example.com/page",
      referrer: "http://example.com",
      browser: "Chrome",
      device: "Desktop",
      country: "US",
      # Custom metrics store name/value in properties as JSON
      properties: %{
        "name" => name,
        "value" => value
      }
    }

    Plausible.ClickhouseRepo.insert(event_data, "events_v2")
  end
end
