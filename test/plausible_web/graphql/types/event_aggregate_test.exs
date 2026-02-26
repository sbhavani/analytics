defmodule PlausibleWeb.GraphQL.Types.EventAggregateTest do
  @moduledoc """
  Unit tests for the EventAggregate GraphQL type.
  """

  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Schema

  describe "EventAggregate type" do
    test "defines the event_aggregate type with correct fields" do
      type = Absinthe.Schema.type(Schema, :event_aggregate)

      assert type != nil

      field_names =
        type.fields
        |> Map.keys()

      assert :count in field_names
      assert :visitors in field_names
      assert :event_name in field_names
      assert :group in field_names
    end

    test "count field has correct type" do
      type = Absinthe.Schema.type(Schema, :event_aggregate)
      count_field = Map.get(type.fields, :count)

      assert count_field.type == :integer
      assert count_field.description == "Total count of events"
    end

    test "visitors field has correct type" do
      type = Absinthe.Schema.type(Schema, :event_aggregate)
      visitors_field = Map.get(type.fields, :visitors)

      assert visitors_field.type == :integer
      assert visitors_field.description == "Unique visitors who triggered events"
    end

    test "event_name field has correct type" do
      type = Absinthe.Schema.type(Schema, :event_aggregate)
      event_name_field = Map.get(type.fields, :event_name)

      assert event_name_field.type == :string
      assert event_name_field.description == "Event name"
    end

    test "group field has correct type" do
      type = Absinthe.Schema.type(Schema, :event_aggregate)
      group_field = Map.get(type.fields, :group)

      assert group_field.type == :string
      assert group_field.description == "Group value (if grouped by dimension)"
    end
  end
end
