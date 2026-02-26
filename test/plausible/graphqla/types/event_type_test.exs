defmodule Plausible.Graphqla.Types.EventTypeTest do
  @moduledoc """
  Unit tests for EventType GraphQL types
  """
  use Plausible.DataCase, async: true

  alias Plausible.Graphqla.Schema
  alias Plausible.Graphqla.Types.EventTypes

  describe "Event object type" do
    test "defines the expected fields" do
      # Verify the Event object type is defined with correct fields
      # by checking the schema can parse and resolve the type
      event_type = Schema.types()[:event]

      assert event_type != nil

      # Get field definitions from the schema
      fields = Absinthe.Schema.object_type_fields(event_type)

      # Verify all expected fields exist
      assert Map.has_key?(fields, :id)
      assert Map.has_key?(fields, :timestamp)
      assert Map.has_key?(fields, :name)
      assert Map.has_key?(fields, :properties)
      assert Map.has_key?(fields, :browser)
      assert Map.has_key?(fields, :device)
      assert Map.has_key?(fields, :country)
    end

    test "id field is non-null" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      id_field = Map.get(fields, :id)
      assert id_field.non_null? == true
    end

    test "timestamp field is non-null datetime" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      timestamp_field = Map.get(fields, :timestamp)
      assert timestamp_field.non_null? == true
      assert timestamp_field.type == :datetime
    end

    test "name field is non-null string" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      name_field = Map.get(fields, :name)
      assert name_field.non_null? == true
      assert name_field.type == :string
    end

    test "properties field is nullable JSON" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      properties_field = Map.get(fields, :properties)
      assert properties_field.type == :json
    end

    test "browser field is nullable string" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      browser_field = Map.get(fields, :browser)
      assert browser_field.type == :string
    end

    test "device field is nullable string" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      device_field = Map.get(fields, :device)
      assert device_field.type == :string
    end

    test "country field is nullable string" do
      event_type = Schema.types()[:event]
      fields = Absinthe.Schema.object_type_fields(event_type)

      country_field = Map.get(fields, :country)
      assert country_field.type == :string
    end
  end

  describe "EventFilter input type" do
    test "defines the expected input fields" do
      # Verify the EventFilter input type is defined
      event_filter_type = Schema.types()[:event_filter_input]

      assert event_filter_type != nil

      # Get input field definitions from the schema
      input_fields = Absinthe.Schema.input_object_type_fields(event_filter_type)

      # Verify all expected input fields exist
      assert Map.has_key?(input_fields, :site_id)
      assert Map.has_key?(input_fields, :date_range)
      assert Map.has_key?(input_fields, :event_type)
    end

    test "site_id field is non-null ID" do
      event_filter_type = Schema.types()[:event_filter_input]
      input_fields = Absinthe.Schema.input_object_type_fields(event_filter_type)

      site_id_field = Map.get(input_fields, :site_id)
      assert site_id_field.non_null? == true
      assert site_id_field.type == :id
    end

    test "date_range field is nullable date_range_input" do
      event_filter_type = Schema.types()[:event_filter_input]
      input_fields = Absinthe.Schema.input_object_type_fields(event_filter_type)

      date_range_field = Map.get(input_fields, :date_range)
      assert date_range_field.type == :date_range_input
    end

    test "event_type field is nullable string" do
      event_filter_type = Schema.types()[:event_filter_input]
      input_fields = Absinthe.Schema.input_object_type_fields(event_filter_type)

      event_type_field = Map.get(input_fields, :event_type)
      assert event_type_field.type == :string
    end
  end

  describe "EventTypes module" do
    test "uses Absinthe.Schema.Notation" do
      # Verify the module uses the correct notation
      assert Keyword.has_key?(EventTypes.__info__(:attributes), :behaviour) ||
             function_exported?(EventTypes, :__using__, 1)
    end
  end
end
