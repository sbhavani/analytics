defmodule PlausibleWeb.GraphQL.Types.EventTypeTest do
  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Schema

  describe "event_result type" do
    test "defines name field as non-null string" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :name)

      assert field.name == "name"
      assert field.type == :string
      assert Absinthe.Type.NonNull in Absinthe.Type.field_type(type, :name)
    end

    test "defines count field as non-null integer" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :count)

      assert field.name == "count"
      assert field.type == :integer
      assert Absinthe.Type.NonNull in Absinthe.Type.field_type(type, :count)
    end

    test "defines properties field as json" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :properties)

      assert field.name == "properties"
      assert field.type == :json
    end

    test "defines timestamp field as date_time" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :timestamp)

      assert field.name == "timestamp"
      assert field.type == :date_time
    end
  end

  describe "event_result serialization" do
    test "serializes name field correctly" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :name)

      assert is_function(field, :resolve)
    end

    test "serializes count field correctly" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :count)

      assert is_function(field, :resolve)
    end

    test "serializes properties field correctly" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :properties)

      assert is_function(field, :resolve)
    end

    test "serializes timestamp field correctly" do
      type = Schema.types()[:event_result]
      field = Absinthe.Type.field(type, :timestamp)

      assert is_function(field, :resolve)
    end
  end

  describe "event_filter_input type" do
    test "defines date_range field as non-null date_range_input" do
      type = Schema.types()[:event_filter_input]
      field = Absinthe.Type.field(type, :date_range)

      assert field.name == "date_range"
      assert field.type == :date_range_input
      assert Absinthe.Type.NonNull in Absinthe.Type.field_type(type, :date_range)
    end

    test "defines event_name field as string" do
      type = Schema.types()[:event_filter_input]
      field = Absinthe.Type.field(type, :event_name)

      assert field.name == "event_name"
      assert field.type == :string
    end

    test "defines property field as property_filter_input" do
      type = Schema.types()[:event_filter_input]
      field = Absinthe.Type.field(type, :property)

      assert field.name == "property"
      assert field.type == :property_filter_input
    end
  end
end
