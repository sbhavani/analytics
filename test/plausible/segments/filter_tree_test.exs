defmodule Plausible.Segments.FilterTreeTest do
  use Plausible.DataCase, async: true
  alias Plausible.Segments.FilterTree

  describe "new/0" do
    test "creates an empty filter tree" do
      tree = FilterTree.new()

      assert tree.root_group.operator == :and
      assert tree.root_group.children == []
      assert tree.version == 1
    end
  end

  describe "add_condition/2" do
    test "adds a condition to root group" do
      tree = FilterTree.new()
      condition = %{dimension: "country", operator: :is, values: ["US"]}

      new_tree = FilterTree.add_condition(tree, condition)

      assert length(new_tree.root_group.children) == 1
      child = hd(new_tree.root_group.children)
      assert child.dimension == "country"
      assert child.operator == :is
      assert child.values == ["US"]
    end

    test "adds multiple conditions to root group" do
      tree = FilterTree.new()
      condition1 = %{dimension: "country", operator: :is, values: ["US"]}
      condition2 = %{dimension: "device", operator: :is, values: ["mobile"]}

      tree = FilterTree.add_condition(tree, condition1)
      tree = FilterTree.add_condition(tree, condition2)

      assert length(tree.root_group.children) == 2
    end
  end

  describe "add_group/2" do
    test "adds a nested group to root" do
      tree = FilterTree.new()

      new_tree = FilterTree.add_group(tree, :or)

      assert length(new_tree.root_group.children) == 1
      child = hd(new_tree.root_group.children)
      assert child.operator == :or
      assert child.children == []
    end

    test "adds group to parent group" do
      tree = FilterTree.new()
      tree = FilterTree.add_group(tree, :or)

      [group | _] = tree.root_group.children

      new_tree = FilterTree.add_group(tree, :and, group.id)

      [nested_group | _] = hd(new_tree.root_group.children).children
      assert nested_group.operator == :and
    end
  end

  describe "remove_item/2" do
    test "removes a condition by id" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: ["US"]})
      tree = FilterTree.add_condition(tree, %{dimension: "device", operator: :is, values: ["mobile"]})

      [to_remove | _] = tree.root_group.children
      new_tree = FilterTree.remove_item(tree, to_remove.id)

      assert length(new_tree.root_group.children) == 1
    end
  end

  describe "delete_group/2" do
    test "deletes a nested group" do
      tree = FilterTree.new()
      tree = FilterTree.add_group(tree, :or)
      tree = FilterTree.add_condition(tree, %{dimension: "country", values: ["US"]})

      [group | _] = tree.root_group.children
      new_tree = FilterTree.delete_group(tree, group.id)

      # The condition should remain
      assert length(new_tree.root_group.children) == 1
    end

    test "does not delete root group" do
      tree = FilterTree.new()
      new_tree = FilterTree.delete_group(tree, tree.root_group.id)

      assert new_tree.root_group.id == tree.root_group.id
    end
  end

  describe "update_condition/3" do
    test "updates condition values" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: ["US"]})

      [condition | _] = tree.root_group.children
      new_tree = FilterTree.update_condition(tree, condition.id, %{values: ["UK"]})

      updated = hd(new_tree.root_group.children)
      assert updated.values == ["UK"]
    end

    test "updates condition operator" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: ["US"]})

      [condition | _] = tree.root_group.children
      new_tree = FilterTree.update_condition(tree, condition.id, %{operator: :contains})

      updated = hd(new_tree.root_group.children)
      assert updated.operator == :contains
    end
  end

  describe "change_group_operator/3" do
    test "changes group operator from and to or" do
      tree = FilterTree.new()
      tree = FilterTree.add_group(tree, :and)
      tree = FilterTree.add_condition(tree, %{dimension: "country", values: ["US"]})

      [group | _] = tree.root_group.children
      new_tree = FilterTree.change_group_operator(tree, group.id, :or)

      updated = hd(new_tree.root_group.children)
      assert updated.operator == :or
    end
  end

  describe "get_depth/1" do
    test "returns 1 for flat group" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", values: ["US"]})

      assert FilterTree.get_depth(tree.root_group) == 1
    end

    test "returns 2 for single nesting" do
      tree = FilterTree.new()
      tree = FilterTree.add_group(tree, :or)

      [group | _] = tree.root_group.children
      tree = FilterTree.add_group(tree, :and, group.id)

      assert FilterTree.get_depth(tree.root_group) == 2
    end
  end

  describe "validate/1" do
    test "returns error for empty tree" do
      tree = FilterTree.new()
      result = FilterTree.validate(tree)

      assert result.valid == false
      assert "Filter tree must have at least one condition" in result.errors
    end

    test "returns valid for tree with conditions" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: ["US"]})

      result = FilterTree.validate(tree)

      assert result.valid == true
      assert result.errors == []
    end

    test "returns error for missing dimension" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "", operator: :is, values: ["US"]})

      result = FilterTree.validate(tree)

      assert result.valid == false
      assert Enum.any?(result.errors, &String.contains?(&1, "missing dimension"))
    end

    test "returns error for missing value" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: []})

      result = FilterTree.validate(tree)

      assert result.valid == false
      assert Enum.any?(result.errors, &String.contains?(&1, "missing value"))
    end
  end

  describe "serialize/1" do
    test "serializes simple filter" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", operator: :is, values: ["US"]})

      serialized = FilterTree.serialize(tree)

      assert serialized == [[:is, "country", ["US"]]]
    end

    test "serializes multiple filters as AND" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", values: ["US"]})
      tree = FilterTree.add_condition(tree, %{dimension: "device", values: ["mobile"]})

      serialized = FilterTree.serialize(tree)

      assert serialized == [
        [:is, "country", ["US"]],
        [:is, "device", ["mobile"]]
      ]
    end

    test "serializes nested groups" do
      tree = FilterTree.new()
      tree = FilterTree.add_condition(tree, %{dimension: "country", values: ["US"]})
      tree = FilterTree.add_group(tree, :or)
      [group | _] = tree.root_group.children
      tree = FilterTree.add_condition(tree, %{dimension: "device", values: ["mobile"]}, group.id)

      serialized = FilterTree.serialize(tree)

      assert serialized == [
        [:is, "country", ["US"]],
        [:or, [[:is, "device", ["mobile"]]]]
      ]
    end
  end

  describe "deserialize/1" do
    test "deserializes simple filter" do
      filters = [[:is, "country", ["US"]]]

      tree = FilterTree.deserialize(filters)

      assert length(tree.root_group.children) == 1
      condition = hd(tree.root_group.children)
      assert condition.dimension == "country"
      assert condition.values == ["US"]
    end

    test "deserializes empty array to empty tree" do
      tree = FilterTree.deserialize([])

      assert tree.root_group.children == []
    end

    test "deserializes nested groups" do
      filters = [
        [:is, "country", ["US"]],
        [:or, [
          [:is, "device", ["mobile"]],
          [:is, "browser", ["Chrome"]]
        ]]
      ]

      tree = FilterTree.deserialize(filters)

      assert length(tree.root_group.children) == 2
    end
  end
end
