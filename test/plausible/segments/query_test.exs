defmodule Plausible.Segments.QueryTest do
  use ExUnit.Case, async: true
  alias Plausible.Segments.Query

  describe "build_tree_query/2" do
    test "builds query for single condition" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"}
        ],
        "groups" => []
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "country_code = 'US'"
    end

    test "builds query for multiple AND conditions" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"},
          %{"field" => "pages_visited", "operator" => "greater_than", "value" => 5}
        ],
        "groups" => []
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "country_code = 'US' AND pageviews > 5"
    end

    test "builds query for OR conditions" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "OR",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"},
          %{"field" => "country", "operator" => "equals", "value" => "GB"}
        ],
        "groups" => []
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "country_code = 'US' OR country_code = 'GB'"
    end
  end

  describe "nested filter groups" do
    test "builds query for nested group (2 levels)" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"}
        ],
        "groups" => [
          %{
            "operator" => "OR",
            "conditions" => [
              %{"field" => "device_type", "operator" => "equals", "value" => "mobile"},
              %{"field" => "device_type", "operator" => "equals", "value" => "tablet"}
            ],
            "groups" => []
          }
        ]
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "country_code = 'US' AND (device = 'mobile' OR device = 'tablet')"
    end

    test "builds query for deeply nested groups (3 levels)" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"}
        ],
        "groups" => [
          %{
            "operator" => "AND",
            "conditions" => [
              %{"field" => "pages_visited", "operator" => "greater_than", "value" => 3}
            ],
            "groups" => [
              %{
                "operator" => "OR",
                "conditions" => [
                  %{"field" => "device_type", "operator" => "equals", "value" => "mobile"},
                  %{"field" => "device_type", "operator" => "equals", "value" => "desktop"}
                ],
                "groups" => []
              }
            ]
          }
        ]
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "country_code = 'US' AND pageviews > 3 AND (device = 'mobile' OR device = 'desktop')"
    end

    test "builds query with multiple nested groups at same level" do
      site = %{id: 1}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [],
        "groups" => [
          %{
            "operator" => "OR",
            "conditions" => [
              %{"field" => "country", "operator" => "equals", "value" => "US"},
              %{"field" => "country", "operator" => "equals", "value" => "GB"}
            ],
            "groups" => []
          },
          %{
            "operator" => "AND",
            "conditions" => [
              %{"field" => "pages_visited", "operator" => "greater_than", "value" => 5}
            ],
            "groups" => []
          }
        ]
      }

      result = Query.build_tree_query(site, filter_tree)

      assert result == "(country_code = 'US' OR country_code = 'GB') AND pageviews > 5"
    end
  end

  describe "validate_filter_tree/1" do
    test "validates filter tree with valid condition count" do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [
          %{"field" => "country", "operator" => "equals", "value" => "US"},
          %{"field" => "pages_visited", "operator" => "greater_than", "value" => 5}
        ],
        "groups" => []
      }

      assert Query.validate_filter_tree(filter_tree) == :ok
    end

    test "returns error when exceeding max conditions (10)" do
      conditions = Enum.map(1..11, fn i ->
        %{"field" => "country_#{i}", "operator" => "equals", "value" => "US"}
      end)

      filter_tree = %{
        "operator" => "AND",
        "conditions" => conditions,
        "groups" => []
      }

      assert Query.validate_filter_tree(filter_tree) == {:error, "Maximum 10 conditions allowed per segment"}
    end

    test "validates filter tree with valid nesting depth (3 levels)" do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [],
        "groups" => [
          %{
            "operator" => "AND",
            "conditions" => [],
            "groups" => [
              %{
                "operator" => "AND",
                "conditions" => [
                  %{"field" => "country", "operator" => "equals", "value" => "US"}
                ],
                "groups" => []
              }
            ]
          }
        ]
      }

      assert Query.validate_filter_tree(filter_tree) == :ok
    end

    test "returns error when exceeding max nesting depth (3)" do
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [],
        "groups" => [
          %{
            "operator" => "AND",
            "conditions" => [],
            "groups" => [
              %{
                "operator" => "AND",
                "conditions" => [],
                "groups" => [
                  %{
                    "operator" => "AND",
                    "conditions" => [
                      %{"field" => "country", "operator" => "equals", "value" => "US"}
                    ],
                    "groups" => []
                  }
                ]
              }
            ]
          }
        ]
      }

      assert Query.validate_filter_tree(filter_tree) == {:error, "Maximum 3 nesting levels allowed"}
    end
  end

  describe "condition_to_sql/1" do
    test "handles equals operator" do
      condition = %{"field" => "country", "operator" => "equals", "value" => "US"}
      # Access private function through build_tree_query
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "country_code = 'US'"
    end

    test "handles not_equals operator" do
      condition = %{"field" => "country", "operator" => "not_equals", "value" => "US"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "country_code != 'US'"
    end

    test "handles greater_than operator" do
      condition = %{"field" => "pages_visited", "operator" => "greater_than", "value" => 5}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "pageviews > 5"
    end

    test "handles less_than operator" do
      condition = %{"field" => "session_duration", "operator" => "less_than", "value" => 300}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "session_duration < 300"
    end

    test "handles contains operator" do
      condition = %{"field" => "referrer_source", "operator" => "contains", "value" => "google"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "position(referrer, 'google') > 0"
    end

    test "handles is_empty operator" do
      condition = %{"field" => "referrer_source", "operator" => "is_empty", "value" => nil}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "referrer = '' OR referrer IS NULL"
    end

    test "handles is_not_empty operator" do
      condition = %{"field" => "referrer_source", "operator" => "is_not_empty", "value" => nil}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "referrer != '' AND referrer IS NOT NULL"
    end

    test "escapes single quotes in values" do
      condition = %{"field" => "country", "operator" => "equals", "value" => "US'S"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "country_code = 'US''S'"
    end
  end

  describe "field_to_column mapping" do
    test "maps country to country_code" do
      condition = %{"field" => "country", "operator" => "equals", "value" => "US"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "country_code = 'US'"
    end

    test "maps pages_visited to pageviews" do
      condition = %{"field" => "pages_visited", "operator" => "greater_than", "value" => 5}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "pageviews > 5"
    end

    test "maps total_spent to total_revenue" do
      condition = %{"field" => "total_spent", "operator" => "greater_than", "value" => 100}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "total_revenue > 100"
    end

    test "maps device_type to device" do
      condition = %{"field" => "device_type", "operator" => "equals", "value" => "mobile"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "device = 'mobile'"
    end

    test "maps referrer_source to referrer" do
      condition = %{"field" => "referrer_source", "operator" => "equals", "value" => "google.com"}
      filter_tree = %{
        "operator" => "AND",
        "conditions" => [condition],
        "groups" => []
      }

      result = Query.build_tree_query(%{id: 1}, filter_tree)

      assert result == "referrer = 'google.com'"
    end
  end
end
