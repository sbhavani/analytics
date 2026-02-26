defmodule PlausibleWeb.GraphQL.Types.CustomMetricTest do
  @moduledoc """
  Unit tests for CustomMetric GraphQL types.
  """

  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Schema

  describe "CustomMetric type" do
    test "defines custom_metric type with expected fields" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)

      assert type != nil

      fields = Absinthe.Type.fields(type)

      assert Map.has_key?(fields, :id)
      assert Map.has_key?(fields, :name)
      assert Map.has_key?(fields, :display_name)
      assert Map.has_key?(fields, :value)
      assert Map.has_key?(fields, :unit)
      assert Map.has_key?(fields, :category)
    end

    test "id field has correct type" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :id)

      assert field.type == :id
    end

    test "name field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :name)

      assert field.type == :string
      assert field.description == "Name of the custom metric"
    end

    test "display_name field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :display_name)

      assert field.type == :string
      assert field.description == "Display label"
    end

    test "value field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :value)

      assert field.type == :float
      assert field.description == "Current value"
    end

    test "unit field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :unit)

      assert field.type == :string
      assert field.description == "Metric unit (e.g., 'seconds', 'currency', 'percentage')"
    end

    test "category field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :category)

      assert field.type == :string
      assert field.description == "Category for grouping"
    end
  end

  describe "CustomMetricTimeSeries type" do
    test "defines custom_metric_time_series type with expected fields" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric_time_series)

      assert type != nil

      fields = Absinthe.Type.fields(type)

      assert Map.has_key?(fields, :timestamp)
      assert Map.has_key?(fields, :value)
    end

    test "timestamp field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric_time_series)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :timestamp)

      assert field.type == :string
      assert field.description == "Timestamp of the data point"
    end

    test "value field has correct type and description" do
      type = Absinthe.Schema.lookup_type(Schema, :custom_metric_time_series)
      fields = Absinthe.Type.fields(type)
      field = Map.get(fields, :value)

      assert field.type == :float
      assert field.description == "Metric value at this timestamp"
    end
  end
end
