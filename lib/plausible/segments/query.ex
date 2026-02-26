defmodule Plausible.Segments.Query do
  @moduledoc """
  Query builder for filtering visitors in ClickHouse based on segment filter trees.
  """
  alias Plausible.Segments.{
    FilterCondition,
    FilterGroup,
    VisitorSegment
  }

  alias Plausible.ClickhouseRepo

  @max_nesting_level 3
  @max_conditions 10

  # Valid fields and their allowed operators
  @valid_fields %{
    "country" => ["equals", "not_equals", "contains", "is_empty", "is_not_empty"],
    "pages_visited" => ["equals", "not_equals", "greater_than", "less_than"],
    "session_duration" => ["equals", "not_equals", "greater_than", "less_than"],
    "total_spent" => ["equals", "not_equals", "greater_than", "less_than"],
    "device_type" => ["equals", "not_equals", "is_empty", "is_not_empty"],
    "referrer_source" => ["equals", "not_equals", "contains", "is_empty", "is_not_empty"]
  }

  # Timeout for preview queries in milliseconds (10 seconds)
  @preview_timeout 10_000
  def preview_timeout, do: @preview_timeout

  @doc """
  Build a ClickHouse query to count visitors matching the segment filters.
  """
  def build_segment_query(site, %VisitorSegment{} = segment) do
    root_group = segment_filter_group(segment)

    if root_group do
      build_group_query(site, root_group)
    else
      # Fallback to legacy segment_data format
      build_legacy_query(site, segment.segment_data)
    end
  end

  @doc """
  Preview visitor count for a filter tree without saving.
  Returns {:ok, count} on success or {:error, :timeout} if query takes too long.
  """
  def preview_count(site, filter_tree) do
    query = build_tree_query(site, filter_tree)
    sql = build_count_sql(site, query)

    try do
      result = ClickhouseRepo.query(sql, [], timeout: @preview_timeout)
      {:ok, parse_count_result(result)}
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}
      :exit, _ ->
        {:error, :query_error}
    end
  end

  @doc """
  Execute preview count with a custom timeout (for testing).
  """
  def preview_count(site, filter_tree, timeout_ms) do
    query = build_tree_query(site, filter_tree)
    sql = build_count_sql(site, query)

    try do
      result = ClickhouseRepo.query(sql, [], timeout: timeout_ms)
      {:ok, parse_count_result(result)}
    catch
      :exit, {:timeout, _} ->
        {:error, :timeout}
      :exit, _ ->
        {:error, :query_error}
    end
  end

  @doc """
  Validate filter tree structure.
  """
  def validate_filter_tree(filter_tree) do
    with :ok <- validate_condition_count(filter_tree),
         :ok <- validate_nesting_depth(filter_tree),
         :ok <- validate_conditions(filter_tree) do
      :ok
    end
  end

  # Private functions

  defp segment_filter_group(%VisitorSegment{root_group_id: root_group_id}) when is_nil(root_group_id), do: nil

  defp segment_filter_group(%VisitorSegment{root_group_id: root_group_id}) do
    Plausible.Repo.get(FilterGroup, root_group_id)
    |> Plausible.Repo.preload([:conditions, :nested_groups])
  end

  defp build_group_query(site, %FilterGroup{} = group) do
    conditions = Plausible.Repo.preload(group, [:conditions, :nested_groups]).conditions
    nested_groups = Plausible.Repo.preload(group, [:conditions, :nested_groups]).nested_groups

    build_conditions_sql(site, conditions, group.operator)
    |> Kernel.<>(build_nested_groups_sql(site, nested_groups, group.operator))
  end

  defp build_tree_query(site, filter_tree) do
    operator = Map.get(filter_tree, "operator", "AND")
    conditions = Map.get(filter_tree, "conditions", [])
    groups = Map.get(filter_tree, "groups", [])

    conditions_sql = build_conditions_list_sql(site, conditions, operator)
    groups_sql = build_groups_list_sql(site, groups, operator)

    combine_group_queries(conditions_sql, groups_sql, operator)
  end

  defp build_conditions_sql(_site, conditions, "AND") do
    conditions
    |> Enum.map(&condition_to_sql/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" AND ")
  end

  defp build_conditions_sql(_site, conditions, "OR") do
    conditions
    |> Enum.map(&condition_to_sql/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" OR ")
  end

  defp build_conditions_list_sql(_site, conditions, "AND") do
    conditions
    |> Enum.map(&condition_to_sql/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" AND ")
  end

  defp build_conditions_list_sql(_site, conditions, "OR") do
    conditions
    |> Enum.map(&condition_to_sql/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" OR ")
  end

  defp build_nested_groups_sql(_site, [], _parent_operator) do
    ""
  end

  defp build_nested_groups_sql(site, nested_groups, parent_operator) do
    nested_queries =
      nested_groups
      |> Enum.map(fn group ->
        Plausible.Repo.preload(group, [:conditions, :nested_groups])
        |> build_group_query(site)
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" #{parent_operator} ")

    if nested_queries != "" do
      " #{parent_operator} (" <> nested_queries <> ")"
    else
      ""
    end
  end

  defp build_groups_list_sql(_site, [], _parent_operator) do
    ""
  end

  defp build_groups_list_sql(site, groups, parent_operator) do
    group_queries =
      groups
      |> Enum.map(fn group ->
        operator = Map.get(group, "operator", "AND")
        conditions = Map.get(group, "conditions", [])
        nested_groups = Map.get(group, "groups", [])

        conditions_sql = build_conditions_list_sql(site, conditions, operator)
        nested_sql = build_groups_list_sql(site, nested_groups, operator)

        combine_group_queries(conditions_sql, nested_sql, operator)
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" #{parent_operator} ")

    if group_queries != "" do
      " #{parent_operator} (" <> group_queries <> ")"
    else
      ""
    end
  end

  defp combine_group_queries(conditions_sql, groups_sql, operator) do
    parts = Enum.reject([conditions_sql, groups_sql], &(&1 == ""))

    case length(parts) do
      0 -> ""
      1 -> hd(parts)
      _ -> Enum.join(parts, " #{operator} ")
    end
  end

  # Map filter fields to ClickHouse columns
  defp condition_to_sql(condition) when is_map(condition) do
    field = Map.get(condition, "field")
    operator = Map.get(condition, "operator")
    value = Map.get(condition, "value")

    condition_to_sql(%{field: field, operator: operator, value: value})
  end

  defp condition_to_sql(%{field: field, operator: operator, value: value}) do
    column = field_to_column(field)

    case operator do
      "equals" ->
        "#{column} = #{escape_value(value)}"

      "not_equals" ->
        "#{column} != #{escape_value(value)}"

      "greater_than" ->
        "#{column} > #{escape_value(value)}"

      "less_than" ->
        "#{column} < #{escape_value(value)}"

      "contains" ->
        "position(#{column}, #{escape_value(value)}) > 0"

      "is_empty" ->
        "#{column} = '' OR #{column} IS NULL"

      "is_not_empty" ->
        "#{column} != '' AND #{column} IS NOT NULL"

      _ ->
        nil
    end
  end

  defp field_to_column("country"), do: "country_code"
  defp field_to_column("pages_visited"), do: "pageviews"
  defp field_to_column("session_duration"), do: "session_duration"
  defp field_to_column("total_spent"), do: "total_revenue"
  defp field_to_column("device_type"), do: "device"
  defp field_to_column("referrer_source"), do: "referrer"
  defp field_to_column(field), do: field

  defp escape_value(nil), do: "NULL"
  defp escape_value(value) when is_binary(value), do: "'#{String.replace(value, "'", "''")}'"
  defp escape_value(value) when is_integer(value), do: to_string(value)
  defp escape_value(value) when is_float(value), do: to_string(value)

  defp build_count_sql(site, where_clause) do
    base_query = """
    SELECT count(DISTINCT visitor_id) as count
    FROM plausible_events_v3
    WHERE site_id = #{site.id}
    """

    if where_clause != "" do
      base_query <> " AND " <> where_clause
    else
      base_query
    end
  end

  defp build_legacy_query(_site, nil), do: ""
  defp build_legacy_query(_site, %{"filters" => []}), do: ""
  defp build_legacy_query(site, %{"filters" => filters}) do
    filters
    |> Enum.map(&legacy_condition_to_sql/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" AND ")
  end

  defp legacy_condition_to_sql(filter) do
    case filter do
      ["is", dimension, clauses] ->
        column = field_to_column(dimension)
        values = Enum.map(clauses, &escape_value/1)
        "#{column} IN (#{Enum.join(values, ", ")})"

      ["not is", dimension, clauses] ->
        column = field_to_column(dimension)
        values = Enum.map(clauses, &escape_value/1)
        "#{column} NOT IN (#{Enum.join(values, ", ")})"

      _ ->
        nil
    end
  end

  # Validation functions

  defp validate_condition_count(filter_tree) do
    count = count_conditions(filter_tree)

    if count > @max_conditions do
      {:error, "Maximum #{@max_conditions} conditions allowed per segment"}
    else
      :ok
    end
  end

  defp validate_nesting_depth(filter_tree) do
    depth = calculate_depth(filter_tree)

    if depth > @max_nesting_level do
      {:error, "Maximum #{@max_nesting_level} nesting levels allowed"}
    else
      :ok
    end
  end

  defp validate_conditions(filter_tree) do
    conditions = Map.get(filter_tree, "conditions", [])
    groups = Map.get(filter_tree, "groups", [])

    # Validate each condition
    with {:error, reason} <- validate_condition_fields(conditions),
         do: {:error, reason},
         else: (_ ->
           # Recursively validate nested groups
           Enum.reduce_while(groups, :ok, fn group, :ok ->
             case validate_conditions(group) do
               :ok -> {:cont, :ok}
               {:error, _} = error -> {:halt, error}
             end
           end)
         end)
  end

  defp validate_condition_fields(conditions) do
    Enum.reduce_while(conditions, :ok, fn condition, :ok ->
      field = Map.get(condition, "field")
      operator = Map.get(condition, "operator")
      value = Map.get(condition, "value")

      # Check if field is provided
      if is_nil(field) or field == "" do
        {:halt, {:error, "Missing required field: field is required for each condition"}}
      else
        # Check if field is valid
        if not Map.has_key?(@valid_fields, field) do
          {:halt, {:error, "Invalid field: '#{field}' is not a valid filter field"}}
        else
          # Check if operator is provided
          if is_nil(operator) or operator == "" do
            {:halt, {:error, "Missing required operator for field '#{field}'"}}
          else
            # Check if operator is valid for this field
            valid_operators = Map.get(@valid_fields, field, [])
            if operator not in valid_operators do
              {:halt, {:error, "Invalid operator '#{operator}' for field '#{field}'. Valid operators: #{Enum.join(valid_operators, ", ")}"}}
            else
              # Check if value is required (not required for is_empty/is_not_empty)
              needs_value = operator not in ["is_empty", "is_not_empty"]
              if needs_value and (is_nil(value) or value == "") do
                {:halt, {:error, "Missing required value for field '#{field}' with operator '#{operator}'"}}
              else
                {:cont, :ok}
              end
            end
          end
        end
      end
    end)
  end

  defp count_conditions(filter_tree) do
    conditions = Map.get(filter_tree, "conditions", [])
    groups = Map.get(filter_tree, "groups", [])

    group_count = Enum.reduce(groups, 0, fn g, acc ->
      acc + count_conditions(g)
    end)

    length(conditions) + group_count
  end

  defp calculate_depth(filter_tree, acc \\ 0)
  defp calculate_depth(nil, acc), do: acc

  defp calculate_depth(filter_tree, acc) do
    groups = Map.get(filter_tree, "groups", [])

    if groups == [] do
      acc
    else
      max_depth = Enum.reduce(groups, acc, fn g, inner_acc ->
        max(calculate_depth(g, acc + 1), inner_acc)
      end)
      max_depth
    end
  end

  # Parse ClickHouse query result to extract count
  defp parse_count_result({:ok, %{rows: [[count]]}}), do: count || 0
  defp parse_count_result({:ok, %{rows: []}}), do: 0
  defp parse_count_result(_), do: 0
end
