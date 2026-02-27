defmodule Plausible.Segments.FilterTree do
  @moduledoc """
  This module handles parsing and serialization of filter trees.

  Filter trees support nested AND/OR groups for complex filtering scenarios.
  """

  alias Plausible.Stats.QueryBuilder

  @type filter_operator() :: :is | :is_not | :contains | :contains_not | :has_not_done | :matches | :does_not_match | :is_set | :is_not_set | :greater_than | :less_than
  @type group_operator() :: :and | :or

  @type condition() :: %{
    optional(:id) => String.t(),
    dimension: String.t(),
    operator: filter_operator(),
    values: [String.t()]
  }

  @type group() :: %{
    optional(:id) => String.t(),
    operator: group_operator(),
    children: [group() | condition()]
  }

  @type t() :: %{
    root_group: group(),
    version: non_neg_integer()
  }

  @max_depth 3

  @doc """
  Creates a new empty filter tree with default values.
  """
  def new do
    %{
      root_group: %{
        id: generate_id(),
        operator: :and,
        children: []
      },
      version: 1
    }
  end

  @doc """
  Adds a condition to the filter tree.
  """
  def add_condition(tree, condition, group_id \\ nil) do
    new_condition = %{
      id: generate_id(),
      dimension: condition.dimension,
      operator: condition.operator,
      values: condition.values
    }

    update_in(tree, [:root_group], fn root ->
      if is_nil(group_id) do
        %{root | children: root.children ++ [new_condition]}
      else
        add_condition_to_group(root, group_id, new_condition)
      end
    end)
  end

  defp add_condition_to_group(group, group_id, condition) do
    if group.id == group_id do
      %{group | children: group.children ++ [condition]}
    else
      %{group | children: Enum.map(group.children, &add_condition_to_group(&1, group_id, condition))}
    end
  end

  @doc """
  Adds a nested group to the filter tree.
  """
  def add_group(tree, operator \\ :or, parent_group_id \\ nil) do
    depth = get_depth(tree.root_group)

    if depth >= @max_depth do
      raise "Maximum nesting depth of #{@max_depth} exceeded"
    end

    new_group = %{
      id: generate_id(),
      operator: operator,
      children: []
    }

    update_in(tree, [:root_group], fn root ->
      if is_nil(parent_group_id) do
        %{root | children: root.children ++ [new_group]}
      else
        add_group_to_parent(root, parent_group_id, new_group)
      end
    end)
  end

  defp add_group_to_parent(group, parent_id, new_group) do
    if group.id == parent_id do
      %{group | children: group.children ++ [new_group]}
    else
      %{group | children: Enum.map(group.children, &add_group_to_parent(&1, parent_id, new_group))}
    end
  end

  @doc """
  Removes an item (condition or group) from the filter tree by ID.
  """
  def remove_item(tree, item_id) do
    update_in(tree, [:root_group], fn root ->
      remove_from_group(root, item_id)
    end)
  end

  defp remove_from_group(group, item_id) do
    children =
      group.children
      |> Enum.filter(fn
        %{id: id} -> id != item_id
        _ -> true
      end)
      |> Enum.map(&remove_from_group(&1, item_id))

    %{group | children: children}
  end

  @doc """
  Deletes an entire group and all its contents.
  """
  def delete_group(tree, group_id) do
    # Cannot delete root group
    if group_id == tree.root_group.id do
      tree
    else
      update_in(tree, [:root_group], fn root ->
        delete_group_from(root, group_id)
      end)
    end
  end

  defp delete_group_from(group, group_id) do
    children =
      group.children
      |> Enum.filter(fn
        %{id: id, operator: _} -> id != group_id
        _ -> true
      end)
      |> Enum.map(fn
        %{id: _, operator: _, children: _} = g -> delete_group_from(g, group_id)
        c -> c
      end)

    %{group | children: children}
  end

  @doc """
  Updates a condition in the filter tree.
  """
  def update_condition(tree, condition_id, updates) do
    update_in(tree, [:root_group], fn root ->
      update_condition_in(root, condition_id, updates)
    end)
  end

  defp update_condition_in(group, condition_id, updates) do
    %{group | children: Enum.map(group.children, &update_condition_item(&1, condition_id, updates))}
  end

  defp update_condition_item(%{id: id, operator: _, children: _} = g, condition_id, updates) do
    update_condition_in(g, condition_id, updates)
  end

  defp update_condition_item(%{id: id} = c, condition_id, updates) do
    if id == condition_id do
      Map.merge(c, updates)
    else
      c
    end
  end

  @doc """
  Changes the operator of a group (AND/OR).
  """
  def change_group_operator(tree, group_id, new_operator) do
    update_in(tree, [:root_group], fn root ->
      change_operator_in(root, group_id, new_operator)
    end)
  end

  defp change_operator_in(group, group_id, new_operator) do
    if group.id == group_id do
      %{group | operator: new_operator}
    else
      %{group | children: Enum.map(group.children, &change_operator_in(&1, group_id, new_operator))}
    end
  end

  @doc """
  Gets the nesting depth of the filter tree.
  """
  def get_depth(group, current_depth \\ 1)
  def get_depth(%{children: []}, depth), do: depth
  def get_depth(%{children: children}, depth) do
    Enum.reduce(children, depth, fn
      %{operator: _, children: _} = g, acc ->
        max(acc, get_depth(g, depth + 1))
      _, acc -> acc
    end)
  end

  @doc """
  Validates the filter tree.
  """
  def validate(tree) do
    errors = []

    # Check root has children
    if length(tree.root_group.children) == 0 do
      errors = ["Filter tree must have at least one condition" | errors]
    end

    # Check depth
    depth = get_depth(tree.root_group)
    if depth > @max_depth do
      errors = ["Maximum nesting depth of #{@max_depth} exceeded" | errors]
    end

    # Validate conditions
    errors = validate_conditions(tree.root_group, "root", errors)

    %{valid: Enum.empty?(errors), errors: Enum.reverse(errors)}
  end

  defp validate_conditions(group, path, errors) do
    if length(group.children) == 0 do
      ["Group at #{path} has no children" | errors]
    else
      group.children
      |> Enum.with_index()
      |> Enum.reduce(errors, fn
        { %{operator: _, children: _} = g, index }, acc ->
          validate_conditions(g, "#{path}/group[#{index}]", acc)
        { %{dimension: _, operator: _, values: _} = c, index }, acc ->
          validate_condition(c, "#{path}/condition[#{index}]", acc)
      end)
    end
  end

  defp validate_condition(condition, path, errors) do
    errors =
      if condition.dimension == "" or is_nil(condition.dimension) do
        ["Condition at #{path} missing dimension" | errors]
      else
        errors
      end

    errors =
      if condition.operator == "" or is_nil(condition.operator) do
        ["Condition at #{path} missing operator" | errors]
      else
        errors
      end

    if condition.operator not in [:is_set, :is_not_set] and length(condition.values) == 0 do
      ["Condition at #{path} missing value" | errors]
    else
      errors
    end
  end

  @doc """
  Serializes a filter tree to the legacy flat array format.
  """
  def serialize(%{root_group: root}) do
    serialize_group(root)
  end

  defp serialize_group(group) do
    Enum.map(group.children, fn
      %{operator: _, children: _} = g ->
        nested = serialize_group(g)
        if length(nested) == 1 do
          [group.operator | hd(nested)]
        else
          [group.operator, nested]
        end
      %{dimension: d, operator: o, values: v} ->
        [o, d, v]
    end)
  end

  @doc """
  Deserializes a flat filter array to a filter tree.
  """
  def deserialize([]), do: new()
  def deserialize(filters) when is_list(filters) do
    root = deserialize_group(filters, :and)
    %{root_group: root, version: 1}
  end

  defp deserialize_group(filters, default_op) do
    # Check for explicit operator
    if length(filters) == 1 and is_list(hd(filters)) and is_atom(hd(hd(filters))) do
      [op, children] = hd(filters)
      %{
        id: generate_id(),
        operator: op,
        children: deserialize_children(children, op)
      }
    else
      # Check for mixed operators
      has_and = Enum.any?(filters, &(&1 == :and))
      has_or = Enum.any?(filters, &(&1 == :or))

      if has_and or has_or do
        {children, _} = Enum.reduce(filters, {[], nil}, fn
          op when op in [:and, :or], {acc, _} ->
            {acc, op}
          filter, {acc, current_op} when current_op != nil ->
            {[deserialize_condition(filter) | acc], current_op}
          filter, {acc, nil} ->
            {[deserialize_condition(filter) | acc], default_op}
        end)

        %{
          id: generate_id(),
          operator: default_op,
          children: Enum.reverse(children)
        }
      else
        # Simple flat filters - implicitly ANDed
        %{
          id: generate_id(),
          operator: :and,
          children: Enum.map(filters, &deserialize_condition/1)
        }
      end
    end
  end

  defp deserialize_children(filters, parent_op) do
    Enum.map(filters, fn
      [op, children] when is_atom(op) and is_list(children) ->
        deserialize_group([op, children], parent_op)
      filter ->
        deserialize_condition(filter)
    end)
  end

  defp deserialize_condition([op, dim, vals]) do
    %{
      id: generate_id(),
      operator: op,
      dimension: dim,
      values: vals
    }
  end

  @doc """
  Converts a filter tree to a query that can be used with QueryBuilder.
  """
  def to_query(tree) do
    serialized = serialize(tree)

    case QueryBuilder.build(nil, %{filters: serialized}) do
      {:ok, query} -> {:ok, query}
      {:error, %{__struct__: mod, code: code, message: message}} ->
        {:error, %{code: code, message: message}}
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
