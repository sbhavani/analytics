defmodule Plausible.Segments.FilterParser do
  @moduledoc """
  Parses and validates filter tree structures.
  """

  alias Plausible.Segments.FilterTypes
  alias Plausible.Segments.Fields

  @doc """
  Parses a filter tree from JSON map.
  """
  @spec parse(map()) :: {:ok, FilterTypes.tree()} | {:error, String.t()}
  def parse(%{"root_group" => _} = tree) do
    FilterTypes.validate(tree)
  end

  def parse(_), do: {:error, "Invalid filter tree structure"}

  @doc """
  Creates a new empty filter tree.
  """
  @spec new() :: FilterTypes.tree()
  def new do
    %{
      "root_group" => %{
        "id" => generate_id(),
        "connector" => "AND",
        "conditions" => [],
        "subgroups" => []
      }
    }
  end

  @doc """
  Adds a condition to a filter tree.
  """
  @spec add_condition(FilterTypes.tree(), FilterTypes.condition()) :: FilterTypes.tree()
  def add_condition(tree, condition) do
    update_in(tree, ["root_group", "conditions"], fn conditions ->
      (conditions || []) ++ [condition]
    end)
  end

  @doc """
  Updates a condition in a filter tree.
  """
  @spec update_condition(FilterTypes.tree(), String.t(), map()) :: FilterTypes.tree()
  def update_condition(tree, condition_id, updates) do
    update_in(tree, ["root_group", "conditions"], fn conditions ->
      Enum.map(conditions, fn
        %{^:id => ^condition_id} -> Map.merge(condition, updates)
        condition -> condition
      end)
    end)
  end

  @doc """
  Removes a condition from a filter tree.
  """
  @spec remove_condition(FilterTypes.tree(), String.t()) :: FilterTypes.tree()
  def remove_condition(tree, condition_id) do
    update_in(tree, ["root_group", "conditions"], fn conditions ->
      Enum.reject(conditions, &(&1["id"] == condition_id))
    end)
  end

  @doc """
  Changes the connector of a group.
  """
  @spec change_connector(FilterTypes.tree(), String.t(), :and | :or) :: FilterTypes.tree()
  def change_connector(tree, group_id, connector) do
    update_group(tree, group_id, fn group ->
      Map.put(group, "connector", String.upcase(Atom.to_string(connector)))
    end)
  end

  @doc """
  Creates a nested group from selected conditions.
  """
  @spec create_group(FilterTypes.tree(), [String.t()], :and | :or) :: FilterTypes.tree()
  def create_group(tree, condition_ids, connector) do
    conditions = get_in(tree, ["root_group", "conditions"])
    {group_conditions, remaining} = Enum.split_with(conditions, &(&1["id"] in condition_ids))

    new_group = %{
      "id" => generate_id(),
      "connector" => String.upcase(Atom.to_string(connector)),
      "conditions" => group_conditions,
      "subgroups" => []
    }

    tree
    |> put_in(["root_group", "conditions"], remaining)
    |> update_in(["root_group", "subgroups"], &(&1 ++ [new_group]))
  end

  @doc """
  Converts filter tree to WhereBuilder format.
  """
  @spec to_where_builder(FilterTypes.tree()) :: [FilterTypes.condition() | {:and | :or, [any()]}]
  def to_where_builder(%{"root_group" => root_group}) do
    group_to_where_builder(root_group)
  end

  defp group_to_where_builder(%{"connector" => connector, "conditions" => conditions, "subgroups" => subgroups}) do
    connector_atom = String.downcase(connector) |> String.to_atom()

    parts =
      Enum.map(conditions, &condition_to_filter/1) ++
        Enum.map(subgroups, &group_to_where_builder/1)

    case parts do
      [] -> []
      [single] -> [single]
      multiple -> [{connector_atom, multiple}]
    end
  end

  defp condition_to_filter(%{
         "field" => field,
         "operator" => operator,
         "value" => value,
         "negated" => negated
       }) do
    {[field, operator_to_where(operator), value], negated}
  end

  defp condition_to_filter(%{
         "field" => field,
         "operator" => operator,
         "value" => value
       }) do
    {[field, operator_to_where(operator), value], false}
  end

  defp operator_to_where("equals"), do: :==
  defp operator_to_where("does_not_equal"), do: :!=
  defp operator_to_where("contains"), do: :contains
  defp operator_to_where("does_not_contain"), do: :not_contains
  defp operator_to_where("greater_than"), do: :>
  defp operator_to_where("less_than"), do: :<
  defp operator_to_where("greater_or_equal"), do: :>=
  defp operator_to_where("less_or_equal"), do: :<=
  defp operator_to_where("is_one_of"), do: :in
  defp operator_to_where("is_not_one_of"), do: :not_in
  defp operator_to_where("is_true"), do: :is_true
  defp operator_to_where("is_false"), do: :is_false

  defp update_group(tree, group_id, update_fn) do
    update_in(tree, ["root_group", "subgroups"], fn subgroups ->
      Enum.map(subgroups, fn
        %{^:id => ^group_id} -> update_fn.(group)
        group -> group
      end)
    end)
  end

  defp generate_id do
    :crypto.hash(:sha256, :rand.bytes(16))
    |> Base.encode16()
    |> String.slice(0, 8)
  end
end
