defmodule PlausibleWeb.GraphQL.SchemaTest do
  @moduledoc """
  Tests for the GraphQL schema definitions.
  """
  use ExUnit.Case, async: true
  use PlausibleWeb.GraphQLCase

  alias PlausibleWeb.GraphQL.Schema

  describe "pageviews query - schema structure" do
    test "pageviews query exists in schema" do
      query_type = Schema.query_type()
      pageviews_field = Absinthe.Schema.lookup_type(query_type, :pageviews)

      assert pageviews_field != nil, "pageviews query field should exist"
    end

    test "pageviews query has correct arguments" do
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      pageviews_field = Absinthe.Schema.lookup_type(schema, :pageviews)

      # Verify required arguments
      assert pageviews_field.args[:site_id] != nil, "site_id argument should exist"
      assert pageviews_field.args[:site_id].type == non_null(:string), "site_id should be non-null string"

      assert pageviews_field.args[:date_range] != nil, "date_range argument should exist"
      assert pageviews_field.args[:date_range].type == non_null(:date_range_input), "date_range should be non-null date_range_input"

      # Verify optional arguments
      assert pageviews_field.args[:filter] != nil, "filter argument should exist"
      assert pageviews_field.args[:pagination] != nil, "pagination argument should exist"
      assert pageviews_field.args[:sort] != nil, "sort argument should exist"
    end

    test "pageviews query returns pageview_connection type" do
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      pageviews_field = Absinthe.Schema.lookup_type(schema, :pageviews)

      assert pageviews_field.type == :pageview_connection, "pageviews should return pageview_connection type"
    end
  end

  describe "pageviews query - execution" do
    test "returns pageviews for a valid site", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            edges {
              node {
                url
                title
                visitors
                viewsPerVisit
                bounceRate
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
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["pageviews"]
      assert is_map(data)
      assert is_list(data["edges"])
      assert is_map(data["pageInfo"])
      assert is_integer(data["totalCount"])
    end

    test "returns empty array when no data exists", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            edges {
              node {
                url
                visitors
              }
            }
            totalCount
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] == nil

      data = result["data"]["pageviews"]
      assert data["edges"] == []
      assert data["totalCount"] == 0
    end

    test "returns error when site_id is missing", %{site: _site} do
      query = """
        query {
          pageviews(dateRange: {from: "2024-01-01", to: "2024-01-31"}) {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] != nil
    end

    test "returns error when date_range is missing", %{site: site} do
      query = """
        query {
          pageviews(siteId: "#{site.domain}") {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] != nil
    end

    test "accepts pagination arguments", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            pagination: {first: 10}
          ) {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] == nil
      assert is_list(result["data"]["pageviews"]["edges"])
    end

    test "accepts filter arguments", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            filter: {urlPattern: "/blog/*"}
          ) {
            edges {
              node {
                url
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Should execute without GraphQL errors (filtering happens in resolver)
      assert result["errors"] == nil || result["data"]["pageviews"] != nil
    end

    test "accepts sort arguments", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            sort: [{field: "visitors", order: DESC}]
          ) {
            edges {
              node {
                url
                visitors
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] == nil || result["data"]["pageviews"] != nil
    end

    test "validates pageview_connection type has correct fields", %{site: site} do
      query = """
        query {
          pageviews(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            edges {
              node {
                url
                title
                visitors
                viewsPerVisit
                bounceRate
                timestamp
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

      result = run_query(query, Schema)

      # Query should execute without errors - all fields are valid
      assert result["errors"] == nil
      assert is_map(result["data"]["pageviews"])
    end
  end

  describe "pageview_connection type" do
    test "has edges field" do
      connection_type = Absinthe.Schema.lookup_type(Schema, :pageview_connection)

      assert connection_type.fields[:edges] != nil, "edges field should exist"
    end

    test "has page_info field" do
      connection_type = Absinthe.Schema.lookup_type(Schema, :pageview_connection)

      assert connection_type.fields[:page_info] != nil, "page_info field should exist"
    end

    test "has total_count field" do
      connection_type = Absinthe.Schema.lookup_type(Schema, :pageview_connection)

      assert connection_type.fields[:total_count] != nil, "total_count field should exist"
    end
  end

  describe "pageview type" do
    test "has correct fields" do
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      assert pageview_type.fields[:url] != nil, "url field should exist"
      assert pageview_type.fields[:title] != nil, "title field should exist"
      assert pageview_type.fields[:visitors] != nil, "visitors field should exist"
      assert pageview_type.fields[:views_per_visit] != nil, "views_per_visit field should exist"
      assert pageview_type.fields[:bounce_rate] != nil, "bounce_rate field should exist"
      assert pageview_type.fields[:timestamp] != nil, "timestamp field should exist"
    end
  end

  describe "aggregate query - schema structure" do
    test "aggregate query exists in schema" do
      # Verify the aggregate field exists in the query type
      query_type = Schema.query_type()
      aggregate_field = Absinthe.Schema.lookup_type(query_type, :aggregate)

      assert aggregate_field != nil, "aggregate query field should exist"
    end

    test "aggregate query has correct arguments" do
      # Get the aggregate field from the schema
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      aggregate_field = Absinthe.Schema.lookup_type(schema, :aggregate)

      # Verify required arguments
      assert aggregate_field.args[:site_id] != nil, "site_id argument should exist"
      assert aggregate_field.args[:site_id].type == non_null(:string), "site_id should be non-null string"

      assert aggregate_field.args[:date_range] != nil, "date_range argument should exist"
      assert aggregate_field.args[:date_range].type == non_null(:date_range_input), "date_range should be non-null date_range_input"

      assert aggregate_field.args[:metrics] != nil, "metrics argument should exist"

      # Verify optional arguments
      assert aggregate_field.args[:filter] != nil, "filter argument should exist"
    end

    test "aggregate query returns aggregate_result type" do
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      aggregate_field = Absinthe.Schema.lookup_type(schema, :aggregate)

      assert aggregate_field.type == :aggregate_result, "aggregate should return aggregate_result type"
    end

    test "aggregate_result type has correct fields" do
      aggregate_result = Absinthe.Schema.lookup_type(Schema, :aggregate_result)

      # Verify all expected fields exist
      assert aggregate_result.fields[:visitors] != nil, "visitors field should exist"
      assert aggregate_result.fields[:pageviews] != nil, "pageviews field should exist"
      assert aggregate_result.fields[:events] != nil, "events field should exist"
      assert aggregate_result.fields[:bounce_rate] != nil, "bounce_rate field should exist"
      assert aggregate_result.fields[:visit_duration] != nil, "visit_duration field should exist"
      assert aggregate_result.fields[:views_per_visit] != nil, "views_per_visit field should exist"
    end
  end

  describe "custom_metrics query" do
    test "returns custom metrics for a valid site", %{site: site} do
      query = """
        query {
          customMetrics(siteId: "#{site.domain}") {
            name
            value
            previousValue
            change
            historicalValues {
              timestamp
              value
            }
          }
        }
      """

      result = run_query(query, Schema)

      assert result["data"]["customMetrics"] == []
    end

    test "returns custom metrics with date range", %{site: site} do
      query = """
        query {
          customMetrics(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            name
            value
          }
        }
      """

      result = run_query(query, Schema)

      assert result["data"]["customMetrics"] == []
    end

    test "returns error for invalid site_id", %{user: user} do
      query = """
        query {
          customMetrics(siteId: "nonexistent-site") {
            name
            value
          }
        }
      """

      result = run_query(query, Schema, user)

      assert result["errors"] != nil
    end

    test "validates custom_metric type fields", %{site: site} do
      query = """
        query {
          customMetrics(siteId: "#{site.domain}") {
            name
            value
            previousValue
            change
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without errors
      assert result["errors"] == nil
      # Should return a list (empty for now)
      assert is_list(result["data"]["customMetrics"])
    end
  end

  describe "aggregate query" do
    test "returns aggregate metrics for a valid site", %{site: site} do
      query = """
        query {
          aggregate(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            metrics: ["visitors", "pageviews", "events"]
          ) {
            visitors
            pageviews
            events
            bounceRate
            visitDuration
            viewsPerVisit
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["aggregate"]
      assert is_map(data)
    end

    test "returns error when metrics are missing", %{site: site} do
      query = """
        query {
          aggregate(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            visitors
          }
        }
      """

      result = run_query(query, Schema)

      assert result["errors"] != nil
    end

    test "validates aggregate_result type fields", %{site: site} do
      query = """
        query {
          aggregate(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            metrics: ["visitors"]
          ) {
            visitors
            pageviews
            events
            bounceRate
            visitDuration
            viewsPerVisit
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without errors
      assert result["errors"] == nil
      assert is_map(result["data"]["aggregate"])
    end
  end

  describe "timeseries query" do
    test "returns timeseries data for a valid site", %{site: site} do
      query = """
        query {
          timeseries(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-07"},
            metrics: ["visitors", "pageviews"],
            interval: DAY
          ) {
            interval
            data {
              date
              visitors
              pageviews
              events
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["timeseries"]
      assert is_map(data)
      assert data["interval"] == "DAY"
      assert is_list(data["data"])
    end

    test "returns error for invalid date range", %{site: site} do
      query = """
        query {
          timeseries(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-31", to: "2024-01-01"},
            metrics: ["visitors"]
          ) {
            data {
              date
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Should have validation error
      assert result["errors"] != nil || result["data"]["timeseries"] == nil
    end
  end

  describe "events query" do
    test "returns events for a valid site", %{site: site} do
      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            edges {
              node {
                name
                category
                timestamp
                properties
                visitors
                events
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

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["events"]
      assert is_map(data)
      assert is_list(data["edges"])
      assert is_map(data["pageInfo"])
      assert is_integer(data["totalCount"])
    end

    test "returns events with filter by name", %{site: site} do
      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            filter: {name: "pageview"}
          ) {
            edges {
              node {
                name
              }
            }
            totalCount
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["events"]
      assert is_map(data)
    end

    test "returns events with filter by category", %{site: site} do
      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            filter: {category: "engagement"}
          ) {
            edges {
              node {
                name
                category
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["events"]
      assert is_map(data)
    end

    test "returns events with pagination", %{site: site} do
      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-01", to: "2024-01-31"},
            pagination: {first: 10, after: "YXZlcmFnZT0x"}
          ) {
            edges {
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Query should execute without GraphQL errors
      assert result["errors"] == nil

      data = result["data"]["events"]
      assert is_map(data)
    end

    test "returns error for invalid site_id", %{site: _site} do
      query = """
        query {
          events(
            siteId: "nonexistent-site",
            dateRange: {from: "2024-01-01", to: "2024-01-31"}
          ) {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Should have an error or return empty data
      assert result["errors"] != nil || result["data"]["events"] == nil
    end

    test "returns error for missing required date_range", %{site: site} do
      query = """
        query {
          events(siteId: "#{site.domain}") {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Should have validation error for missing required field
      assert result["errors"] != nil
    end

    test "returns error for invalid date range (from > to)", %{site: site} do
      query = """
        query {
          events(
            siteId: "#{site.domain}",
            dateRange: {from: "2024-01-31", to: "2024-01-01"}
          ) {
            edges {
              node {
                name
              }
            }
          }
        }
      """

      result = run_query(query, Schema)

      # Should have validation error
      assert result["errors"] != nil
    end

    test "events query has correct schema structure" do
      # Verify the events field exists in the query type
      query_type = Schema.query_type()
      events_field = Absinthe.Schema.lookup_type(query_type, :events)

      assert events_field != nil, "events query field should exist"
    end

    test "events query has correct arguments" do
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      events_field = Absinthe.Schema.lookup_type(schema, :events)

      # Verify required arguments
      assert events_field.args[:site_id] != nil, "site_id argument should exist"
      assert events_field.args[:site_id].type == non_null(:string), "site_id should be non-null string"

      assert events_field.args[:date_range] != nil, "date_range argument should exist"
      assert events_field.args[:date_range].type == non_null(:date_range_input), "date_range should be non-null date_range_input"

      # Verify optional arguments
      assert events_field.args[:filter] != nil, "filter argument should exist"
      assert events_field.args[:pagination] != nil, "pagination argument should exist"
    end

    test "events query returns event_connection type" do
      {:ok, schema} = Absinthe.Schema.lookup_type(Schema, :query_type)
      events_field = Absinthe.Schema.lookup_type(schema, :events)

      assert events_field.type == :event_connection, "events should return event_connection type"
    end
  end
end
