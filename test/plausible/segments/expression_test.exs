defmodule Plausible.Segments.ExpressionTest do
  use Plausible.DataCase, async: true

  alias Plausible.Segments.Expression

  describe "validate/1" do
    test "validates a simple single-condition expression" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{
              id: "c1",
              field: "country",
              operator: :equals,
              value: "US"
            }
          ]
        }
      }

      assert :ok = Expression.validate(expression)
    end

    test "validates multiple conditions with AND" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :equals, value: "US"},
            %{id: "c2", field: "pageviews", operator: :greater_than, value: 10}
          ]
        }
      }

      assert :ok = Expression.validate(expression)
    end

    test "validates multiple conditions with OR" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :OR,
          conditions: [
            %{id: "c1", field: "source", operator: :equals, value: "google"},
            %{id: "c2", field: "source", operator: :equals, value: "bing"}
          ]
        }
      }

      assert :ok = Expression.validate(expression)
    end

    test "validates nested condition groups" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :OR,
          conditions: [
            %{
              id: "g2",
              operator: :AND,
              conditions: [
                %{id: "c1", field: "country", operator: :equals, value: "US"},
                %{id: "c2", field: "pageviews", operator: :greater_than, value: 10}
              ]
            },
            %{id: "c3", field: "country", operator: :equals, value: "UK"}
          ]
        }
      }

      assert :ok = Expression.validate(expression)
    end

    test "rejects invalid version" do
      expression = %{
        version: 2,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: []
        }
      }

      assert {:error, ["Invalid version: expected 1"]} = Expression.validate(expression)
    end

    test "rejects missing rootGroup" do
      expression = %{version: 1}

      assert {:error, ["rootGroup is required"]} = Expression.validate(expression)
    end

    test "rejects empty conditions" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: []
        }
      }

      assert {:error, ["Group must have at least one condition" | _]} = Expression.validate(expression)
    end

    test "rejects invalid group operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :XOR,
          conditions: [
            %{id: "c1", field: "country", operator: :equals, value: "US"}
          ]
        }
      }

      assert {:error, ["Group operator must be AND or OR" | _]} = Expression.validate(expression)
    end

    test "rejects missing field" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "", operator: :equals, value: "US"}
          ]
        }
      }

      assert {:error, ["Condition field is required" | _]} = Expression.validate(expression)
    end

    test "rejects invalid operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :invalid_op, value: "US"}
          ]
        }
      }

      assert {:error, ["Invalid operator: invalid_op" | _]} = Expression.validate(expression)
    end

    test "rejects missing value when required" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :equals, value: nil}
          ]
        }
      }

      assert {:error, ["Value is required for operator equals" | _]} = Expression.validate(expression)
    }

    test "allows missing value for is_set operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :is_set, value: nil}
          ]
        }
      }

      assert :ok = Expression.validate(expression)
    end
  end

  describe "to_legacy_filters/1" do
    test "converts single condition to legacy format" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :equals, value: "US"}
          ]
        }
      }

      assert [[:is, "country", ["US"]]] = Expression.to_legacy_filters(expression)
    end

    test "converts multiple AND conditions" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :equals, value: "US"},
            %{id: "c2", field: "pageviews", operator: :greater_than, value: 10}
          ]
        }
      }

      assert [
        [:is, "country", ["US"]],
        [:is, "pageviews", [10]]
      ] = Expression.to_legacy_filters(expression)
    end

    test "converts OR conditions" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :OR,
          conditions: [
            %{id: "c1", field: "source", operator: :equals, value: "google"},
            %{id: "c2", field: "source", operator: :equals, value: "bing"}
          ]
        }
      }

      assert [
        [:is, "source", ["google"]],
        [:is, "source", ["bing"]]
      ] = Expression.to_legacy_filters(expression)
    end

    test "flattens nested groups" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :OR,
          conditions: [
            %{
              id: "g2",
              operator: :AND,
              conditions: [
                %{id: "c1", field: "country", operator: :equals, value: "US"},
                %{id: "c2", field: "pageviews", operator: :greater_than, value: 10}
              ]
            },
            %{id: "c3", field: "country", operator: :equals, value: "UK"}
          ]
        }
      }

      # Nested groups are flattened for legacy format
      result = Expression.to_legacy_filters(expression)
      assert length(result) == 3
    end

    test "handles not_equals operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :not_equals, value: "US"}
          ]
        }
      }

      assert [[:is_not, "country", ["US"]]] = Expression.to_legacy_filters(expression)
    end

    test "handles contains operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "page", operator: :contains, value: "/blog"}
          ]
        }
      }

      assert [[:contains, "page", ["/blog"]]] = Expression.to_legacy_filters(expression)
    end

    test "handles is_set operator" do
      expression = %{
        version: 1,
        rootGroup: %{
          id: "g1",
          operator: :AND,
          conditions: [
            %{id: "c1", field: "country", operator: :is_set, value: nil}
          ]
        }
      }

      assert [[:is_not_null, "country", ["country"]]] = Expression.to_legacy_filters(expression)
    end
  end

  describe "parse/1" do
    test "parses expression with string keys" do
      expression = %{
        "version" => 1,
        "rootGroup" => %{
          "id" => "g1",
          "operator" => "AND",
          "conditions" => [
            %{"id" => "c1", "field" => "country", "operator" => "equals", "value" => "US"}
          ]
        }
      }

      assert {:ok, parsed} = Expression.parse(expression)
      assert parsed.version == 1
      assert parsed.rootGroup.operator == :AND
    end
  end
end
