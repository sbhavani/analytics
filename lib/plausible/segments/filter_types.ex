defmodule Plausible.Segments.FilterTypes do
  @moduledoc """
  Types and validation for filter tree structures.
  """

  @type connector :: :and | :or

  @type condition :: %{
          required(:id) => String.t(),
          required(:field) => String.t(),
          required(:operator) => String.t(),
          required(:value) => String.t(),
          optional(:negated) => boolean()
        }

  @type group :: %{
          required(:id) => String.t(),
          required(:connector) => connector(),
          optional(:conditions) => [condition()],
          optional(:subgroups) => [group()]
        }

  @type tree :: %{
          required(:root_group) => group()
        }

  @valid_operators [
    "equals",
    "does_not_equal",
    "contains",
    "does_not_contain",
    "is_one_of",
    "is_not_one_of",
    "matches_regex",
    "not_equals",
    "greater_than",
    "less_than",
    "greater_or_equal",
    "less_or_equal",
    "is_true",
    "is_false"
  ]

  @max_nesting_depth 5

  @doc """
  Validates a filter tree structure.
  """
  @spec validate(tree()) :: {:ok, tree()} | {:error, String.t()}
  def validate(%{"root_group" => root_group}) do
    validate_group(root_group, 0)
  end

  def validate(_), do: {:error, "Invalid tree structure: missing root_group"}

  defp validate_group(group, depth) do
    cond do
      depth > @max_nesting_depth ->
        {:error, "Maximum nesting depth of #{@max_nesting_depth} exceeded"}

      not is_map(group) ->
        {:error, "Group must be a map"}

      is_nil(group["id"]) ->
        {:error, "Group missing required field: id"}

      is_nil(group["connector"]) ->
        {:error, "Group missing required field: connector"}

      group["connector"] not in ["AND", "OR", :and, :or] ->
        {:error, "Invalid connector: #{group["connector"]}"}

      true ->
        conditions = group["conditions"] || []
        subgroups = group["subgroups"] || []

        with {:ok, _} <- validate_conditions(conditions),
             {:ok, _} <- validate_subgroups(subgroups, depth + 1) do
          {:ok, group}
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp validate_conditions(conditions) when is_list(conditions) do
    Enum.reduce_while(conditions, {:ok, nil}, fn condition, acc ->
      case validate_condition(condition) do
        :ok -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_conditions(_), do: {:error, "conditions must be a list"}

  defp validate_condition(condition) when is_map(condition) do
    required_fields = ["id", "field", "operator", "value"]

    missing = Enum.filter(required_fields, fn field -> is_nil(condition[field]) end)

    if missing != [] do
      {:error, "Condition missing required fields: #{Enum.join(missing, ", ")}"}
    else
      if condition["operator"] not in @valid_operators do
        {:error, "Invalid operator: #{condition["operator"]}"}
      else
        :ok
      end
    end
  end

  defp validate_condition(_), do: {:error, "Condition must be a map"}

  defp validate_subgroups(subgroups, depth) when is_list(subgroups) do
    Enum.reduce_while(subgroups, {:ok, nil}, fn subgroup, acc ->
      case validate_group(subgroup, depth) do
        :ok -> {:cont, acc}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_subgroups(nil, _), do: {:ok, nil}
  defp validate_subgroups(_, _), do: {:error, "subgroups must be a list"}

  @doc """
  Returns the maximum nesting depth allowed.
  """
  @spec max_depth() :: non_neg_integer()
  def max_depth, do: @max_nesting_depth

  @doc """
  Returns list of valid operators.
  """
  @spec valid_operators() :: [String.t()]
  def valid_operators, do: @valid_operators
end
