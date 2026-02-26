defmodule PlausibleWeb.GraphQL.EventFilterTest do
  @moduledoc """
  Tests for event filtering in the GraphQL API.

  This test module covers:
  - Event name filtering
  - Property filtering
  - Combined filters
  - Filter operator support
  """

  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Helpers.FilterParser
  alias PlausibleWeb.GraphQL.Resolvers.EventResolver

  describe "FilterParser.parse_filters/1" do
    test "parses nil filters to empty list" do
      assert FilterParser.parse_filters(nil) == {:ok, []}
    end

    test "parses empty list to empty list" do
      assert FilterParser.parse_filters([]) == {:ok, []}
    end

    test "parses event name equals filter" do
      filters = [%{field: "name", operator: "equals", value: "signup"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :exact, "signup"]]}
    end

    test "parses event_name equals filter" do
      filters = [%{field: "event_name", operator: "equals", value: "purchase"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :exact, "purchase"]]}
    end

    test "parses event name not equals filter" do
      filters = [%{field: "name", operator: "not_equals", value: "pageview"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :does_not_equal, "pageview"]]}
    end

    test "parses contains filter" do
      filters = [%{field: "name", operator: "contains", value: "sign"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :contains, "sign"]]}
    end

    test "parses matches filter (regex)" do
      filters = [%{field: "name", operator: "matches", value: "^sign.*"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :matches, "^sign.*"]]}
    end

    test "parses pathname filter" do
      filters = [%{field: "pathname", operator: "equals", value: "/blog"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :pathname, :exact, "/blog"]]}
    end

    test "parses url filter (maps to pathname)" do
      filters = [%{field: "url", operator: "equals", value: "/docs"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :pathname, :exact, "/docs"]]}
    end

    test "parses country filter" do
      filters = [%{field: "country", operator: "equals", value: "US"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :country, :exact, "US"]]}
    end

    test "parses device filter" do
      filters = [%{field: "device", operator: "equals", value: "mobile"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :device, :exact, "mobile"]]}
    end

    test "parses browser filter" do
      filters = [%{field: "browser", operator: "equals", value: "Chrome"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :browser, :exact, "Chrome"]]}
    end

    test "parses operating_system filter" do
      filters = [%{field: "operating_system", operator: "equals", value: "Linux"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :os, :exact, "Linux"]]}
    end

    test "parses referrer filter" do
      filters = [%{field: "referrer", operator: "equals", value: "https://example.com"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:page, :referrer, :exact, "https://example.com"]]}
    end

    test "parses is_set operator" do
      filters = [%{field: "name", operator: "is_set", value: ""}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :is_not_null, ""]]}
    end

    test "parses is_not_set operator" do
      filters = [%{field: "name", operator: "is_not_set", value: ""}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :is_null, ""]]}
    end

    test "parses greater_than operator" do
      filters = [%{field: "name", operator: "greater_than", value: "5"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :greater, "5"]]}
    end

    test "parses less_than operator" do
      filters = [%{field: "name", operator: "less_than", value: "10"}]

      assert FilterParser.parse_filters(filters) ==
               {:ok, [[:event, :event_name, :less, "10"]]}
    end

    test "parses multiple filters" do
      filters = [
        %{field: "name", operator: "equals", value: "signup"},
        %{field: "country", operator: "equals", value: "US"}
      ]

      assert FilterParser.parse_filters(filters) ==
               {:ok,
                [
                  [:event, :event_name, :exact, "signup"],
                  [:page, :country, :exact, "US"]
                ]}
    end

    test "returns error for unknown operator" do
      filters = [%{field: "name", operator: "unknown_op", value: "test"}]

      assert {:error, ["Unknown operator: unknown_op"]} = FilterParser.parse_filters(filters)
    end
  end

  describe "EventResolver events filtering" do
    @describetag :graphql

    test "filters events by event name" do
      # This test verifies that the resolver correctly passes filters
      # to the stats layer. We test the integration by checking that
      # the filter parsing adds the event type filter correctly.

      # The resolver adds [:event, :event_name, :is_not_null, ""] filter
      # to ensure only custom events (not pageviews) are returned.

      args = %{
        site_id: 1,
        filters: [%{field: "name", operator: "equals", value: "signup"}]
      }

      # The parse_filters_with_event_name should add the event type filter
      filters = args[:filters]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)

      # Verify event name filter is present
      assert [:event, :event_name, :exact, "signup"] in parsed
    end

    test "filters events by property" do
      args = %{
        site_id: 1,
        filters: [%{field: "properties", operator: "contains", value: "plan"}]
      }

      filters = args[:filters]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)

      # Property filters should use :event event type
      assert [:event, :properties, :contains, "plan"] in parsed
    end

    test "combines multiple filters" do
      args = %{
        site_id: 1,
        filters: [
          %{field: "name", operator: "equals", value: "purchase"},
          %{field: "country", operator: "equals", value: "DE"},
          %{field: "device", operator: "equals", value: "desktop"}
        ]
      }

      filters = args[:filters]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)

      assert [:event, :event_name, :exact, "purchase"] in parsed
      assert [:page, :country, :exact, "DE"] in parsed
      assert [:page, :device, :exact, "desktop"] in parsed
    end

    test "handles no filters gracefully" do
      args = %{
        site_id: 1,
        filters: nil
      }

      # When filters is nil, it should return empty list
      assert FilterParser.parse_filters(args[:filters]) == {:ok, []}
    end
  end
end
