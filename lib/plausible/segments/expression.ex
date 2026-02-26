defmodule Plausible.Segments.Expression do
  @moduledoc """
  Validation module for filter expressions.

  Filter expressions are tree structures that represent complex filter logic
  with AND/OR operators and nested condition groups.
  """

  @max_nesting_depth 5
  @max_total_conditions 50

  @type filter_operator :: :equals | :not_equals | :contains | :not_contains |
                          :greater_than | :less_than | :matches_regex |
                          :is_set | :is_not_set

  @type logical_operator :: :AND | :OR

  @type condition :: %{
    required(:id) => String.t(),
    required(:field) => String.t(),
    required(:operator) => filter_operator(),
    optional(:value) => String.t() | number() | boolean() | nil
  }

  @type condition_group :: %{
    required(:id) => String.t(),
    required(:operator) => logical_operator(),
    required(:conditions) => [condition() | condition_group()]
  }

  @type filter_expression :: %{
    required(:version) => 1,
    required(:rootGroup) => condition_group()
  }

  @doc """
  Validate a filter expression and return :ok or {:error, reason}
  """
  @spec validate(filter_expression()) :: :ok | {:error, [String.t()]}
  def validate(expression) when is_map(expression) do
    errors = []

    # Check version
    errors = if expression.version == 1 do
      errors
    else
      ["Invalid version: expected 1" | errors]
    end

    # Check rootGroup exists
    errors = if Map.has_key?(expression, :rootGroup) do
      errors
    else
      ["rootGroup is required" | errors]
    end

    # If we already have critical errors, return early
    if errors != [] do
      {:error, Enum.reverse(errors)}
    else
      # Validate root group
      validate_group(expression.rootGroup, 1, errors)
    end
  end

  def validate(_), do: {:error, ["Expression must be a map"]}

  defp validate_group(group, depth, acc) when is_map(group) do
    errors = acc

    # Check operator
    errors = if group.operator in [:AND, :OR] do
      errors
    else
      ["Group operator must be AND or OR" | errors]
    end

    # Check conditions exist and not empty
    errors = if is_list(group.conditions) && length(group.conditions) > 0 do
      errors
    else
      ["Group must have at least one condition" | errors]
    end

    # Check nesting depth
    errors = if depth > @max_nesting_depth do
      ["Maximum nesting depth (#{@max_nesting_depth}) exceeded" | errors]
    else
      errors
    end

    # Validate each condition/group
    {final_errors, condition_count} = Enum.reduce(group.conditions, {errors, 0}, fn
      condition, {errs, count} when is_map(condition) and has_key?(condition, :field) ->
        {validate_condition(condition, depth, errs), count + 1}

      nested_group, {errs, count} when is_map(nested_group) ->
        {validate_group(nested_group, depth + 1, errs), count}
    end, {errors, 0})

    # Check total condition count
    errors = if condition_count > @max_total_conditions do
      ["Maximum number of conditions (#{@max_total_conditions}) exceeded" | final_errors]
    else
      final_errors
    end

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  defp validate_group(_group, _depth, acc) do
    {:error, ["Invalid group structure" | acc]}
  end

  defp validate_condition(condition, _depth, acc) do
    errors = acc

    # Check field
    errors = if is_binary(condition.field) && condition.field != "" do
      errors
    else
      ["Condition field is required" | errors]
    end

    # Check operator
    valid_operators = [:equals, :not_equals, :contains, :not_contains,
                      :greater_than, :less_than, :matches_regex,
                      :is_set, :is_not_set]

    errors = if condition.operator in valid_operators do
      errors
    else
      ["Invalid operator: #{condition.operator}" | errors]
    end

    # Check value if required
    needs_value = condition.operator in [:equals, :not_equals, :contains,
                                        :not_contains, :greater_than,
                                        :less_than, :matches_regex]

    errors = if needs_value do
      if is_nil(condition.value) or condition.value == "" do
        ["Value is required for operator #{condition.operator}" | errors]
      else
        errors
      end
    else
      errors
    end

    errors
  end

  # Helper to check if map has a key (works with both atom and string keys)
  defp has_key?(map, key) do
    Map.has_key?(map, key) or Map.has_key?(map, Atom.to_string(key))
  end

  @doc """
  Convert a filter expression to legacy filter format for backward compatibility.
  Returns a list of filters in the format expected by the query builder.
  """
  @spec to_legacy_filters(filter_expression()) :: [[any()]]
  def to_legacy_filters(expression) do
    if Map.has_key?(expression, :rootGroup) do
      flatten_group(expression.rootGroup)
    else
      []
    end
  end

  defp flatten_group(group) do
    Enum.flat_map(group.conditions, fn
      condition when is_map(condition) and has_key?(condition, :field) ->
        [condition_to_filter(condition)]

      nested_group when is_map(nested_group) ->
        flatten_group(nested_group)
    end)
  end

  defp condition_to_filter(condition) do
    field = condition.field
    operator = condition.operator
    value = condition.value

    case operator do
      :equals ->
        [:is, field, wrap_value(value)]

      :not_equals ->
        [:is_not, field, wrap_value(value)]

      :contains ->
        [:contains, field, wrap_value(value)]

      :not_contains ->
        [:contains_not, field, wrap_value(value)]

      :greater_than ->
        [:is, field, wrap_value(value)]

      :less_than ->
        [:is, field, wrap_value(value)]

      :matches_regex ->
        [:matches, field, wrap_value(value)]

      :is_set ->
        [:is_not_null, field, [field]]

      :is_not_set ->
        [:is_null, field, [field]]

      _ ->
        [:is, field, wrap_value(value)]
    end
  end

  defp wrap_value(value) when is_list(value), do: value
  defp wrap_value(value) when is_binary(value) or is_number(value), do: [value]
  defp wrap_value(value), do: [to_string(value)]

  @doc """
  Parse an expression from API format (string keys) to internal format (atom keys).
  """
  @spec parse(map()) :: {:ok, filter_expression()} | {:error, [String.t()]}
  def parse(expression) when is_map(expression) do
    # Convert string keys to atoms
    parsed = convert_keys_to_atoms(expression)

    case validate(parsed) do
      :ok -> {:ok, parsed}
      {:error, errors} -> {:error, errors}
    end
  end

  defp convert_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_binary(k) ->
        key = String.to_existing_atom(k)
        {key, convert_keys_to_atoms(v)}

      {k, v} ->
        {k, convert_keys_to_atoms(v)}
    end)
  end

  defp convert_keys_to_atoms(list) when is_list(list) do
    Enum.map(list, &convert_keys_to_atoms/1)
  end

  defp convert_keys_to_atoms(value), do: value
end
