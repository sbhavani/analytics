defmodule Plausible.GraphQL.TypesTest do
  @moduledoc """
  Unit tests for GraphQL types.

  These tests verify the structure and definitions of GraphQL types
  used in the analytics API.
  """

  use ExUnit.Case, async: true

  alias Plausible.GraphQL.Schema
  alias Plausible.GraphQL.Types.EventTypes
  alias Plausible.GraphQL.Types.CustomMetricTypes
  alias Plausible.GraphQL.Types.CommonTypes

  describe "PageviewTypes - :pageview object type" do
    test "defines the pageview object type" do
      # Get the type definition from the schema
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      assert pageview_type != nil
      assert pageview_type.identifier == :pageview
    end

    test "pageview type has url field as string" do
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      url_field =
        Enum.find(pageview_type.fields, fn field -> field.identifier == :url end)

      assert url_field != nil
      assert url_field.type == :string
      assert url_field.description == "Full URL of the page viewed"
    end

    test "pageview type has timestamp field as datetime" do
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      timestamp_field =
        Enum.find(pageview_type.fields, fn field -> field.identifier == :timestamp end)

      assert timestamp_field != nil
      assert timestamp_field.type == :datetime
      assert timestamp_field.description == "When the pageview occurred"
    end

    test "pageview type has referrer field as string" do
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      referrer_field =
        Enum.find(pageview_type.fields, fn field -> field.identifier == :referrer end)

      assert referrer_field != nil
      assert referrer_field.type == :string
      assert referrer_field.description == "Traffic source (may be empty)"
    end

    test "pageview type has visitor_id field as string" do
      pageview_type = Absinthe.Schema.lookup_type(Schema, :pageview)

      visitor_id_field =
        Enum.find(pageview_type.fields, fn field -> field.identifier == :visitor_id end)

      assert visitor_id_field != nil
      assert visitor_id_field.type == :string
      assert visitor_id_field.description == "Anonymous visitor identifier"
    end
  end

  describe "PageviewTypes - :pageview_filter_input input object" do
    test "defines the pageview_filter_input input type" do
      # Get the input type definition from the schema
      input_type = Absinthe.Schema.lookup_type(Schema, :pageview_filter_input)

      assert input_type != nil
      assert input_type.identifier == :pageview_filter_input
    end

    test "pageview_filter_input has url field as string" do
      input_type = Absinthe.Schema.lookup_type(Schema, :pageview_filter_input)

      url_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :url end)

      assert url_field != nil
      assert url_field.type == :string
      assert url_field.description == "Exact URL to filter by"
    end

    test "pageview_filter_input has url_pattern field as string" do
      input_type = Absinthe.Schema.lookup_type(Schema, :pageview_filter_input)

      url_pattern_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :url_pattern end)

      assert url_pattern_field != nil
      assert url_pattern_field.type == :string
      assert url_pattern_field.description == "URL pattern to match (supports wildcards)"
    end

    test "pageview_filter_input has referrer field as string" do
      input_type = Absinthe.Schema.lookup_type(Schema, :pageview_filter_input)

      referrer_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :referrer end)

      assert referrer_field != nil
      assert referrer_field.type == :string
      assert referrer_field.description == "Referrer to filter by"
    end
  end

  describe "EventTypes - :event object type" do
    test "defines the event object type" do
      # Get the type definition from the schema
      event_type = Absinthe.Schema.lookup_type(Schema, :event)

      assert event_type != nil
      assert event_type.identifier == :event
    end

    test "event type has name field as string" do
      event_type = Absinthe.Schema.lookup_type(Schema, :event)

      name_field =
        Enum.find(event_type.fields, fn field -> field.identifier == :name end)

      assert name_field != nil
      assert name_field.type == :string
      assert name_field.description == "Event type (e.g., signup, click)"
    end

    test "event type has timestamp field as datetime" do
      event_type = Absinthe.Schema.lookup_type(Schema, :event)

      timestamp_field =
        Enum.find(event_type.fields, fn field -> field.identifier == :timestamp end)

      assert timestamp_field != nil
      assert timestamp_field.type == :datetime
      assert timestamp_field.description == "When the event occurred"
    end

    test "event type has properties field as json" do
      event_type = Absinthe.Schema.lookup_type(Schema, :event)

      properties_field =
        Enum.find(event_type.fields, fn field -> field.identifier == :properties end)

      assert properties_field != nil
      assert properties_field.type == :json
      assert properties_field.description == "Custom event properties"
    end

    test "event type has visitor_id field as string" do
      event_type = Absinthe.Schema.lookup_type(Schema, :event)

      visitor_id_field =
        Enum.find(event_type.fields, fn field -> field.identifier == :visitor_id end)

      assert visitor_id_field != nil
      assert visitor_id_field.type == :string
      assert visitor_id_field.description == "Anonymous visitor identifier"
    end
  end

  describe "EventTypes - :event_filter_input input object" do
    test "defines the event_filter_input input type" do
      # Get the input type definition from the schema
      input_type = Absinthe.Schema.lookup_type(Schema, :event_filter_input)

      assert input_type != nil
      assert input_type.identifier == :event_filter_input
    end

    test "event_filter_input has name field as string" do
      input_type = Absinthe.Schema.lookup_type(Schema, :event_filter_input)

      name_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :name end)

      assert name_field != nil
      assert name_field.type == :string
      assert name_field.description == "Event name to filter by"
    end
  end

  describe "CustomMetricTypes - :custom_metric object type" do
    test "defines the custom_metric object type" do
      custom_metric_type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      assert custom_metric_type != nil
      assert custom_metric_type.identifier == :custom_metric
    end

    test "custom_metric type has name field as string" do
      custom_metric_type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      name_field =
        Enum.find(custom_metric_type.fields, fn field -> field.identifier == :name end)

      assert name_field != nil
      assert name_field.type == :string
      assert name_field.description == "Metric identifier"
    end

    test "custom_metric type has value field as float" do
      custom_metric_type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      value_field =
        Enum.find(custom_metric_type.fields, fn field -> field.identifier == :value end)

      assert value_field != nil
      assert value_field.type == :float
      assert value_field.description == "Metric value"
    end

    test "custom_metric type has timestamp field as datetime" do
      custom_metric_type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      timestamp_field =
        Enum.find(custom_metric_type.fields, fn field -> field.identifier == :timestamp end)

      assert timestamp_field != nil
      assert timestamp_field.type == :datetime
      assert timestamp_field.description == "When the metric was recorded"
    end

    test "custom_metric type has dimensions field as json" do
      custom_metric_type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      dimensions_field =
        Enum.find(custom_metric_type.fields, fn field -> field.identifier == :dimensions end)

      assert dimensions_field != nil
      assert dimensions_field.type == :json
      assert dimensions_field.description == "Additional grouping dimensions"
    end
  end

  describe "CustomMetricTypes - :metric_filter_input input object" do
    test "defines the metric_filter_input input type" do
      input_type = Absinthe.Schema.lookup_type(Schema, :metric_filter_input)

      assert input_type != nil
      assert input_type.identifier == :metric_filter_input
    end

    test "metric_filter_input has name field as string" do
      input_type = Absinthe.Schema.lookup_type(Schema, :metric_filter_input)

      name_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :name end)

      assert name_field != nil
      assert name_field.type == :string
      assert name_field.description == "Metric name to filter by"
    end
  end

  describe "CommonTypes - :aggregation_type enum" do
    test "defines the aggregation_type enum" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      assert agg_type != nil
      assert agg_type.identifier == :aggregation_type
    end

    test "aggregation_type has count value" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      values = Enum.map(agg_type.values, & &1.identifier)

      assert :count in values
    end

    test "aggregation_type has sum value" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      values = Enum.map(agg_type.values, & &1.identifier)

      assert :sum in values
    end

    test "aggregation_type has avg value" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      values = Enum.map(agg_type.values, & &1.identifier)

      assert :avg in values
    end

    test "aggregation_type has min value" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      values = Enum.map(agg_type.values, & &1.identifier)

      assert :min in values
    end

    test "aggregation_type has max value" do
      agg_type = Absinthe.Schema.lookup_type(Schema, :aggregation_type)

      values = Enum.map(agg_type.values, & &1.identifier)

      assert :max in values
    end
  end

  describe "CommonTypes - :aggregation_input input object" do
    test "defines the aggregation_input input type" do
      input_type = Absinthe.Schema.lookup_type(Schema, :aggregation_input)

      assert input_type != nil
      assert input_type.identifier == :aggregation_input
    end

    test "aggregation_input has type field as non_null aggregation_type" do
      input_type = Absinthe.Schema.lookup_type(Schema, :aggregation_input)

      type_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :type end)

      assert type_field != nil
      assert type_field.description == "Type of aggregation to perform"
    end

    test "aggregation_input has optional field field" do
      input_type = Absinthe.Schema.lookup_type(Schema, :aggregation_input)

      field_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :field end)

      assert field_field != nil
      assert field_field.description == "Field to aggregate (for SUM, AVG, MIN, MAX)"
    end
  end

  describe "CommonTypes - :date_range_input input object" do
    test "defines the date_range_input input type" do
      input_type = Absinthe.Schema.lookup_type(Schema, :date_range_input)

      assert input_type != nil
      assert input_type.identifier == :date_range_input
    end

    test "date_range_input has from field as non_null datetime" do
      input_type = Absinthe.Schema.lookup_type(Schema, :date_range_input)

      from_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :from end)

      assert from_field != nil
      assert from_field.description == "Start of date range (inclusive)"
    end

    test "date_range_input has to field as non_null datetime" do
      input_type = Absinthe.Schema.lookup_type(Schema, :date_range_input)

      to_field =
        Enum.find(input_type.fields, fn field -> field.identifier == :to end)

      assert to_field != nil
      assert to_field.description == "End of date range (inclusive)"
    end
  end

  describe "CommonTypes - :aggregate_result object" do
    test "defines the aggregate_result object type" do
      result_type = Absinthe.Schema.lookup_type(Schema, :aggregate_result)

      assert result_type != nil
      assert result_type.identifier == :aggregate_result
    end

    test "aggregate_result has value field as float" do
      result_type = Absinthe.Schema.lookup_type(Schema, :aggregate_result)

      value_field =
        Enum.find(result_type.fields, fn field -> field.identifier == :value end)

      assert value_field != nil
      assert value_field.description == "The aggregated value"
    end

    test "aggregate_result has type field as aggregation_type" do
      result_type = Absinthe.Schema.lookup_type(Schema, :aggregate_result)

      type_field =
        Enum.find(result_type.fields, fn field -> field.identifier == :type end)

      assert type_field != nil
      assert type_field.description == "The type of aggregation performed"
    end
  end

  describe "CommonTypes - validate_date_range/1" do
    test "returns :ok for valid date range within 365 days" do
      from = ~U[2026-01-01 00:00:00Z]
      to = ~U[2026-01-31 23:59:59Z]

      result = CommonTypes.validate_date_range(%{from: from, to: to})

      assert result == :ok
    end

    test "returns error for date range exceeding 365 days" do
      from = ~U[2024-01-01 00:00:00Z]
      to = ~U[2026-01-02 23:59:59Z]

      result = CommonTypes.validate_date_range(%{from: from, to: to})

      assert {:error, message} = result
      assert message =~ "365"
    end

    test "returns :ok for exactly 365 day range" do
      from = ~U[2025-01-01 00:00:00Z]
      to = ~U[2025-12-31 23:59:59Z]

      result = CommonTypes.validate_date_range(%{from: from, to: to})

      assert result == :ok
    end

    test "returns :ok for empty or missing input" do
      assert CommonTypes.validate_date_range(%{}) == :ok
      assert CommonTypes.validate_date_range(nil) == :ok
    end
  end
end
