defmodule Plausible.GraphQL.TypesTest do
  use Plausible.DataCase, async: true

  alias Plausible.GraphQL.Schema

  describe "DateRangeInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :date_range_input)
      assert type != nil
    end

    test "has required start_date and end_date fields" do
      query = """
        query {
          __type(name: "DateRangeInput") {
            inputFields {
              name
              type {
                name
                kind
              }
              defaultValue
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "start_date" in fields
      assert "end_date" in fields
    end

    test "accepts valid date range input in query" do
      query = """
        query {
          pageviews(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"}
          ) {
            total
          }
        }
      """

      # This should parse without GraphQL validation errors
      assert {:ok, _parsed} = Absinthe.parse(query)
    end
  end

  describe "AggregationInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :aggregation_input)
      assert type != nil
    end

    test "has function and granularity fields" do
      query = """
        query {
          __type(name: "AggregationInput") {
            inputFields {
              name
              type {
                name
                kind
              }
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "function" in fields
      assert "granularity" in fields
    end

    test "defines aggregation_function enum" do
      query = """
        query {
          __type(name: "AggregationFunction") {
            enumValues {
              name
              description
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      values = Enum.map(type["enumValues"], & &1["name"])
      assert "SUM" in values
      assert "COUNT" in values
      assert "AVG" in values
      assert "MIN" in values
      assert "MAX" in values
    end

    test "defines granularity enum" do
      query = """
        query {
          __type(name: "Granularity") {
            enumValues {
              name
              description
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      values = Enum.map(type["enumValues"], & &1["name"])
      assert "HOUR" in values
      assert "DAY" in values
      assert "WEEK" in values
      assert "MONTH" in values
    end
  end

  describe "PaginationInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :pagination_input)
      assert type != nil
    end

    test "has limit and offset fields" do
      query = """
        query {
          __type(name: "PaginationInput") {
            inputFields {
              name
              type {
                name
                kind
              }
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "limit" in fields
      assert "offset" in fields
    end
  end

  describe "PageviewFilterInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :pageview_filter_input)
      assert type != nil
    end

    test "has filter fields: url_pattern, referrer, country, device" do
      query = """
        query {
          __type(name: "PageviewFilterInput") {
            inputFields {
              name
              type {
                name
                kind
              }
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "url_pattern" in fields
      assert "referrer" in fields
      assert "country" in fields
      assert "device" in fields
    end

    test "accepts valid filter input in query" do
      query = """
        query {
          pageviews(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"},
            filters: {url_pattern: "/page/*", device: "mobile", country: "US"}
          ) {
            total
          }
        }
      """

      assert {:ok, _parsed} = Absinthe.parse(query)
    end
  end

  describe "EventFilterInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :event_filter_input)
      assert type != nil
    end

    test "has filter fields: event_name, properties, url_pattern" do
      query = """
        query {
          __type(name: "EventFilterInput") {
            inputFields {
              name
              type {
                name
                kind
              }
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "event_name" in fields
      assert "properties" in fields
      assert "url_pattern" in fields
    end

    test "accepts valid filter input in query" do
      query = """
        query {
          events(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"},
            filters: {event_name: "pageview", url_pattern: "/home"}
          ) {
            total
          }
        }
      """

      assert {:ok, _parsed} = Absinthe.parse(query)
    end
  end

  describe "MetricFilterInput type" do
    test "is defined in the schema" do
      type = Absinthe.Schema.lookup_type(Schema, :metric_filter_input)
      assert type != nil
    end

    test "has required metric_name field" do
      query = """
        query {
          __type(name: "MetricFilterInput") {
            inputFields {
              name
              type {
                name
                kind
              }
            }
          }
        }
      """

      {:ok, %{data: %{"__type" => type}}} = Absinthe.run(query, Schema, [])

      assert type != nil
      fields = Enum.map(type["inputFields"], & &1["name"])
      assert "metric_name" in fields
    end
  end

  describe "integration - all input types work together" do
    test "pageviews query accepts all input types" do
      query = """
        query {
          pageviews(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"},
            filters: {url_pattern: "/page/*", device: "mobile"},
            aggregation: {function: SUM, granularity: DAY},
            pagination: {limit: 100, offset: 0}
          ) {
            total
            data {
              url_path
            }
            pagination {
              limit
              offset
              has_more
            }
          }
        }
      """

      assert {:ok, _parsed} = Absinthe.parse(query)
    end

    test "events query accepts all input types" do
      query = """
        query {
          events(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"},
            filters: {event_name: "pageview"},
            aggregation: {function: COUNT, granularity: WEEK},
            pagination: {limit: 50, offset: 10}
          ) {
            total
            data {
              event_name
            }
          }
        }
      """

      assert {:ok, _parsed} = Absinthe.parse(query)
    end

    test "metrics query accepts all input types" do
      query = """
        query {
          metrics(
            site_id: "test.com",
            date_range: {start_date: "2026-01-01", end_date: "2026-01-31"},
            filters: {metric_name: "revenue"},
            aggregation: {function: AVG, granularity: MONTH},
            pagination: {limit: 25, offset: 0}
          ) {
            total
            data {
              metric_name
              value
            }
          }
        }
      """

      assert {:ok, _parsed} = Absinthe.parse(query)
    end
  end
end
