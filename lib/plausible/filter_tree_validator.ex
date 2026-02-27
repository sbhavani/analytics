defmodule Plausible.FilterTreeValidator do
  @moduledoc """
  Validates filter tree structure for the advanced filter builder.
  Ensures nesting depth, condition count, and structural integrity.
  """

  @max_nesting_depth 5
  @max_conditions_per_group 10

  @type validation_error :: {:error, String.t()}

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(filter_tree) when is_map(filter_tree) do
    with {:ok, root} <- validate_structure(filter_tree),
         :ok <- validate_nesting_depth(root, 0),
         :ok <- validate_condition_count(root) do
      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  def validate(_), do: {:error, "Filter tree must be a map"}

  defp validate_structure(%{"version" => 1, "root" => root}) do
    validate_node(root)
  end

  defp validate_structure(_), do: {:error, "Filter tree must have version and root"}

  defp validate_node(%{"type" => "group", "operator" => operator, "children" => children})
       when operator in ["and", "or"] and is_list(children) do
    if Enum.empty?(children) do
      {:error, "Group must have at least one child"}
    else
      Enum.reduce_while(children, :ok, fn child, _acc ->
        case validate_node(child) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end
      end)
    end
  end

  defp validate_node(%{"type" => "group"}) do
    {:error, "Group must have operator and children"}
  end

  defp validate_node(%{
         "type" => "condition",
         "attribute" => attribute,
         "operator" => operator,
         "value" => value
       })
       when is_binary(attribute) and is_binary(operator) do
    if is_nil(value) or (is_binary(value) and String.trim(value) == "") do
      if operator in ["has_done", "has_not_done"] do
        :ok
      else
        {:error, "Condition value cannot be empty"}
      end
    else
      :ok
    end
  end

  defp validate_node(%{"type" => "condition"}) do
    {:error, "Condition must have attribute, operator, and value"}
  end

  defp validate_node(_), do: {:error, "Invalid node structure"}

  defp validate_nesting_depth(%{"type" => "group", "children" => children}, current_depth)
       when current_depth >= @max_nesting_depth do
    {:error, "Maximum nesting depth of #{@max_nesting_depth} exceeded"}
  end

  defp validate_nesting_depth(%{"type" => "group", "children" => children}, current_depth) do
    Enum.reduce_while(children, :ok, fn
      %{"type" => "group"} = child, _acc ->
        case validate_nesting_depth(child, current_depth + 1) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end

      _child, _acc ->
        {:cont, :ok}
    end)
  end

  defp validate_nesting_depth(_, _), do: :ok

  defp validate_condition_count(%{"type" => "group", "children" => children}) do
    condition_count = count_conditions(children)

    if condition_count > @max_conditions_per_group do
      {:error, "Maximum #{@max_conditions_per_group} conditions per group exceeded"}
    else
      :ok
    end
  end

  defp validate_condition_count(_), do: :ok

  defp count_conditions(children) do
    Enum.reduce(children, 0, fn
      %{"type" => "condition"}, acc -> acc + 1
      %{"type" => "group", "children" => nested_children}, acc ->
        acc + count_conditions(nested_children)
      _, acc ->
        acc
    end)
  end

  @doc """
  Validates that filter attributes are known Plausible properties.
  """
  @spec validate_attributes(map()) :: :ok | {:error, String.t()}
  def validate_attributes(%{"root" => root}) do
    validate_node_attributes(root)
  end

  def validate_attributes(_), do: :ok

  defp validate_node_attributes(%{"type" => "group", "children" => children}) do
    Enum.reduce_while(children, :ok, fn child, _acc ->
      case validate_node_attributes(child) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_node_attributes(%{"type" => "condition", "attribute" => attr}) do
    if known_attribute?(attr) do
      :ok
    else
      {:error, "Unknown filter attribute: #{attr}"}
    end
  end

  defp validate_node_attributes(_), do: :ok

  defp known_attribute?(attr) when is_binary(attr) do
    known_prefixes = ["visit:", "event:", "event:props:"]
    Enum.any?(known_prefixes, &String.starts_with?(attr, &1))
  end

  defp known_attribute?(_), do: false
end
