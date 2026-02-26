defmodule PlausibleWeb.GraphQL.Types.PageviewAggregateTest do
  @moduledoc """
  Unit tests for the PageviewAggregate GraphQL type.

  These tests verify that the PageviewAggregate type is properly defined
  in the GraphQL schema with the correct fields and types.
  """

  use ExUnit.Case, async: true

  alias PlausibleWeb.GraphQL.Schema

  describe "PageviewAggregate type definition" do
    test "type exists in schema" do
      # Query the schema to verify the type exists
      type = Absinthe.Schema.introspect(Schema, :type, :pageview_aggregate)

      assert type != nil, "PageviewAggregate type should exist in schema"
    end

    test "has count field as integer" do
      type = Absinthe.Schema.introspect(Schema, :type, :pageview_aggregate)
      field = Absinthe.Type.Field.find(type, :count)

      assert field != nil, "count field should exist"
      assert field.type == :integer, "count field should be integer type"
    end

    test "has visitors field as integer" do
      type = Absinthe.Schema.introspect(Schema, :type, :pageview_aggregate)
      field = Absinthe.Type.Field.find(type, :visitors)

      assert field != nil, "visitors field should exist"
      assert field.type == :integer, "visitors field should be integer type"
    end

    test "has group field as string" do
      type = Absinthe.Schema.introspect(Schema, :type, :pageview_aggregate)
      field = Absinthe.Type.Field.find(type, :group)

      assert field != nil, "group field should exist"
      assert field.type == :string, "group field should be string type"
    end

    test "has period field as string" do
      type = Absinthe.Schema.introspect(Schema, :type, :pageview_aggregate)
      field = Absinthe.Type.Field.find(type, :period)

      assert field != nil, "period field should exist"
      assert field.type == :string, "period field should be string type"
    end
  end

  describe "pageviews query with PageviewAggregate type" do
    test "pageviews query returns list of PageviewAggregate" do
      # Verify the pageviews query is defined and uses the correct type
      query = Absinthe.Schema.introspect(Schema, :query, :pageviews)

      assert query != nil, "pageviews query should exist"

      # Verify it returns a list of pageview_aggregate
      assert query.type == {:list, :pageview_aggregate},
             "pageviews query should return list of pageview_aggregate"
    end
  end
end
