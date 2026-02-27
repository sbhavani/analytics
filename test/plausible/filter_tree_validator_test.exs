defmodule Plausible.FilterTreeValidatorTest do
  use Plausible.DataCase, async: true
  alias Plausible.FilterTreeValidator

  describe "validate/1" do
    test "validates a simple valid filter tree" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "visit:country",
              "operator" => "is",
              "value" => "US",
              "negated" => false
            }
          ]
        }
      }

      assert :ok = FilterTreeValidator.validate(filter_tree)
    end

    test "validates nested groups" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "or",
          "children" => [
            %{
              "id" => "group-1",
              "type" => "group",
              "operator" => "and",
              "children" => [
                %{
                  "id" => "cond-1",
                  "type" => "condition",
                  "attribute" => "visit:country",
                  "operator" => "is",
                  "value" => "US",
                  "negated" => false
                }
              ]
            },
            %{
              "id" => "cond-2",
              "type" => "condition",
              "attribute" => "visit:country",
              "operator" => "is",
              "value" => "GB",
              "negated" => false
            }
          ]
        }
      }

      assert :ok = FilterTreeValidator.validate(filter_tree)
    end

    test "rejects invalid version" do
      filter_tree = %{
        "version" => 2,
        "root" => %{}
      }

      assert {:error, _} = FilterTreeValidator.validate(filter_tree)
    end

    test "rejects missing root" do
      filter_tree = %{
        "version" => 1
      }

      assert {:error, _} = FilterTreeValidator.validate(filter_tree)
    end

    test "rejects empty group" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => []
        }
      }

      assert {:error, _} = FilterTreeValidator.validate(filter_tree)
    end

    test "rejects invalid operator in group" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "xor",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "visit:country",
              "operator" => "is",
              "value" => "US",
              "negated" => false
            }
          ]
        }
      }

      assert {:error, _} = FilterTreeValidator.validate(filter_tree)
    end

    test "rejects condition without required fields" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "visit:country"
              # missing operator and value
            }
          ]
        }
      }

      assert {:error, _} = FilterTreeValidator.validate(filter_tree)
    end
  end

  describe "validate_attributes/1" do
    test "validates known attributes" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "visit:country",
              "operator" => "is",
              "value" => "US",
              "negated" => false
            }
          ]
        }
      }

      assert :ok = FilterTreeValidator.validate_attributes(filter_tree)
    end

    test "validates event:props:* custom attributes" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "event:props:subscription_tier",
              "operator" => "is",
              "value" => "premium",
              "negated" => false
            }
          ]
        }
      }

      assert :ok = FilterTreeValidator.validate_attributes(filter_tree)
    end

    test "rejects unknown attributes" do
      filter_tree = %{
        "version" => 1,
        "root" => %{
          "id" => "root-1",
          "type" => "group",
          "operator" => "and",
          "children" => [
            %{
              "id" => "cond-1",
              "type" => "condition",
              "attribute" => "unknown:property",
              "operator" => "is",
              "value" => "test",
              "negated" => false
            }
          ]
        }
      }

      assert {:error, _} = FilterTreeValidator.validate_attributes(filter_tree)
    end
  end
end
