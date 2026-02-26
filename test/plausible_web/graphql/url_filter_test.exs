defmodule PlausibleWeb.GraphQL.URLFilterTest do
  @moduledoc """
  Tests for URL filtering in the GraphQL Analytics API.

  This test module covers filtering by URL, pathname, and referrer
  fields using various operators.
  """
  use ExUnit.Case, async: true
  alias PlausibleWeb.GraphQL.Helpers.FilterParser

  describe "parse_filters/1 for URL filtering" do
    test "parses url field with equals operator" do
      filters = [%{field: "url", operator: "equals", value: "https://example.com/page"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :exact, "https://example.com/page"]]
    end

    test "parses url field with contains operator" do
      filters = [%{field: "url", operator: "contains", value: "/blog"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :contains, "/blog"]]
    end

    test "parses url field with not_contains operator" do
      filters = [%{field: "url", operator: "not_contains", value: "/admin"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :does_not_contain, "/admin"]]
    end

    test "parses url field with matches operator (regex)" do
      filters = [%{field: "url", operator: "matches", value: "/blog/post-\\d+"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :matches, "/blog/post-\\d+"]]
    end

    test "parses url field with not_equals operator" do
      filters = [%{field: "url", operator: "not_equals", value: "/excluded"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :does_not_equal, "/excluded"]]
    end

    test "parses pathname field with equals operator" do
      filters = [%{field: "pathname", operator: "equals", value: "/about"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :exact, "/about"]]
    end

    test "parses pathname field with contains operator" do
      filters = [%{field: "pathname", operator: "contains", value: "/products"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :contains, "/products"]]
    end

    test "parses referrer field with equals operator" do
      filters = [%{field: "referrer", operator: "equals", value: "https://google.com"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :referrer, :exact, "https://google.com"]]
    end

    test "parses referrer field with contains operator" do
      filters = [%{field: "referrer", operator: "contains", value: "twitter"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :referrer, :contains, "twitter"]]
    end

    test "parses multiple URL filters together" do
      filters = [
        %{field: "url", operator: "contains", value: "/blog"},
        %{field: "referrer", operator: "equals", value: "https://google.com"}
      ]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [
        [:page, :pathname, :contains, "/blog"],
        [:page, :referrer, :exact, "https://google.com"]
      ]
    end

    test "parses is_set operator for url field" do
      filters = [%{field: "url", operator: "is_set", value: "true"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :is_not_null, "true"]]
    end

    test "parses is_not_set operator for url field" do
      filters = [%{field: "url", operator: "is_not_set", value: "true"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :is_null, "true"]]
    end

    test "handles empty filter list" do
      assert {:ok, []} = FilterParser.parse_filters([])
    end

    test "handles nil filters" do
      assert {:ok, []} = FilterParser.parse_filters(nil)
    end

    test "returns error for unknown operator" do
      filters = [%{field: "url", operator: "invalid_op", value: "/test"}]

      assert {:error, ["Unknown operator: invalid_op"]} = FilterParser.parse_filters(filters)
    end

    test "handles complex URL patterns" do
      filters = [%{field: "url", operator: "matches", value: "/products/*/details"}]

      assert {:ok, parsed} = FilterParser.parse_filters(filters)
      assert parsed == [[:page, :pathname, :matches, "/products/*/details"]]
    end
  end
end
