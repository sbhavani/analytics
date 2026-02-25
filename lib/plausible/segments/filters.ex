defmodule Plausible.Segments.Filters do
  @moduledoc """
  This module contains functions that enable resolving segments in filters.
  """
  alias Plausible.Segments
  alias Plausible.Stats.{Filters, ApiQueryParser, QueryError}

  @max_segment_filters_count 10
  @max_nesting_depth 3

  @valid_operators ["is", "is_not", "contains", "contains_not"]
  @valid_logics ["AND", "OR"]

  # ============================================================================
  # Advanced Filter Structure Validation (for Filter Builder UI)
  # ============================================================================

  @doc """
  Validates the structure of an advanced filter from the Filter Builder UI.

  An advanced filter is expected to be a map with an "items" key containing
  a list of filter items (conditions or groups).

  ## Examples

      iex> validate_structure(%{"items" => []})
      {:error, ["At least one filter condition is required"]}

      iex> validate_structure(%{"items" => [%{"id" => "1", "dimension" => "country", "operator" => "is", "value" => ["US"]}]})
      :ok

      iex> validate_structure(%{"items" => [%{"id" => "1", "dimension" => "", "operator" => "is", "value" => ["US"]}]})
      {:error, ["Dimension is required"]}

      iex> validate_structure(%{"items" => [%{"id" => "1", "dimension" => "country", "operator" => "invalid", "value" => ["US"]}]})
      {:error, ["Invalid operator: invalid"]}
  """
  def validate_structure(filter) when is_map(filter) do
    items = Map.get(filter, "items", [])

    if is_list(items) and length(items) > 0 do
      items
      |> Enum.flat_map(&validate_filter_item/1)
      |> case do
        [] -> :ok
        errors -> {:error, errors}
      end
    else
      {:error, ["At least one filter condition is required"]}
    end
  end

  def validate_structure(_), do: {:error, ["Invalid filter structure"]}

  @doc """
  Validates a single filter item (condition or group) from the advanced filter format.

  ## Examples

      iex> validate_filter_item(%{"id" => "1", "dimension" => "country", "operator" => "is", "value" => ["US"]})
      []

      iex> validate_filter_item(%{"id" => "1", "dimension" => "", "operator" => "is", "value" => ["US"]})
      ["Dimension is required"]

      iex> validate_filter_item(%{"id" => "1", "logic" => "AND", "children" => [], "depth" => 1})
      []
  """
  def validate_filter_item(item) when is_map(item) do
    cond do
      # It's a condition group
      Map.has_key?(item, "logic") and Map.has_key?(item, "children") ->
        validate_condition_group(item)

      # It's a filter condition
      Map.has_key?(item, "dimension") and Map.has_key?(item, "operator") ->
        validate_filter_condition(item)

      # Unknown structure
      true ->
        ["Invalid filter item structure"]
    end
  end

  def validate_filter_item(_), do: ["Invalid filter item"]

  defp validate_filter_condition(condition) do
    errors = []

    # Validate dimension
    dimension = Map.get(condition, "dimension", "")
    errors = if dimension == "" or is_nil(dimension), do: ["Dimension is required" | errors], else: errors

    # Validate operator
    operator = Map.get(condition, "operator", "")
    errors =
      if operator == "" or is_nil(operator) do
        ["Operator is required" | errors]
      else
        if operator in @valid_operators do
          errors
        else
          ["Invalid operator: #{operator}" | errors]
        end
      end

    # Validate value
    value = Map.get(condition, "value", [])
    errors =
      if not is_list(value) or length(value) == 0 do
        ["At least one value is required" | errors]
      else
        errors
      end

    Enum.reverse(errors)
  end

  defp validate_condition_group(group) do
    errors = []

    # Validate logic
    logic = Map.get(group, "logic", "")
    errors =
      if logic in @valid_logics do
        errors
      else
        ["Invalid group logic: #{logic}" | errors]
      end

    # Validate depth
    depth = Map.get(group, "depth", 1)
    errors =
      if depth > @max_nesting_depth do
        ["Maximum nesting depth of #{@max_nesting_depth} exceeded" | errors]
      else
        errors
      end

    # Validate children
    children = Map.get(group, "children", [])
    child_errors = Enum.flat_map(children, &validate_filter_item/1)

    Enum.reverse(errors) ++ child_errors
  end

  @doc """
  Validates that the filter structure does not exceed the maximum nesting depth.

  ## Examples
    # Valid: Single level
    iex> validate_depth([[:is, "visit:country", ["US"]]])
    :ok

    # Valid: Two levels
    iex> validate_depth([[:and, [[:is, "visit:country", ["US"]], [:is, "visit:device", ["Desktop"]]]]])
    :ok

    # Valid: Three levels
    iex> validate_depth([[:and, [[:or, [[:is, "visit:country", ["US"]], [:is, "visit:country", ["UK"]]]], [:is, "visit:device", ["Desktop"]]]]])
    :ok

    # Invalid: Four levels (exceeds max)
    iex> validate_depth([[:and, [[:or, [[:and, [[:is, "visit:country", ["US"]]]]]]]])
    {:error, %Plausible.Stats.QueryError{code: :invalid_filter_depth, message: "Invalid filters. Maximum nesting depth is 3 levels."}}

    # Also invalid: Four levels via nested :not
    iex> validate_depth([[:not, [:and, [:not, [:and, [:not, [:is, "visit:country", ["US"]]]]]]]])
    {:error, %Plausible.Stats.QueryError{code: :invalid_filter_depth, message: "Invalid filters. Maximum nesting depth is 3 levels."}}
  """
  def validate_depth(filters) do
    case calculate_depth(filters, 1) do
      depth when depth > @max_nesting_depth ->
        {:error,
         %QueryError{
           code: :invalid_filter_depth,
           message: "Invalid filters. Maximum nesting depth is #{@max_nesting_depth} levels."
         }}

      _ ->
        :ok
    end
  end

  defp calculate_depth(filters, current_depth) do
    Enum.reduce(filters, current_depth, fn filter, max_depth ->
      case filter do
        # Unary operators (:not, :ignore_in_totals_query, etc.) add one level
        [op, _]
        when op in [:not, :ignore_in_totals_query, :has_done, :has_not_done] ->
          calculate_depth([List.last(filter)], max_depth + 1)

        # Binary operators (:and, :or) add one level and recurse into children
        [op, children]
        when op in [:and, :or] and is_list(children) ->
          child_depth = calculate_depth(children, max_depth + 1)
          max(max_depth, child_depth)

        # Leaf filter - no nesting
        _ ->
          max_depth
      end
    end)
  end

  @doc """
  Finds unique segment IDs used in query filters.

  ## Examples
    iex> get_segment_ids([[:not, [:is, "segment", [10, 20]]], [:contains, "visit:entry_page", ["blog"]]])
    {:ok, [10, 20]}

    iex> get_segment_ids([[:and, [[:is, "segment", Enum.to_list(1..6)], [:is, "segment", Enum.to_list(1..6)]]]])
    {:error, %Plausible.Stats.QueryError{code: :invalid_filters, message: "Invalid filters. You can only use up to 10 segment filters in a query."}}
  """
  def get_segment_ids(filters) do
    ids =
      filters
      |> Filters.traverse()
      |> Enum.flat_map(fn
        {[_operation, "segment", clauses], _} -> clauses
        _ -> []
      end)

    if length(ids) > @max_segment_filters_count do
      {:error,
       %QueryError{
         code: :invalid_filters,
         message:
           "Invalid filters. You can only use up to #{@max_segment_filters_count} segment filters in a query."
       }}
    else
      {:ok, Enum.uniq(ids)}
    end
  end

  def preload_needed_segments(%Plausible.Site{} = site, filters) do
    with {:ok, segment_ids} <- get_segment_ids(filters),
         {:ok, segments} <-
           Segments.get_many(
             site,
             segment_ids,
             fields: [:id, :segment_data]
           ),
         {:ok, segments_by_id} <-
           {:ok,
            Enum.into(
              segments,
              %{},
              fn %Segments.Segment{id: id, segment_data: segment_data} ->
                case ApiQueryParser.parse_filters(segment_data["filters"]) do
                  {:ok, filters} -> {id, filters}
                  _ -> {id, nil}
                end
              end
            )},
         :ok <-
           if(Enum.any?(segment_ids, fn id -> is_nil(Map.get(segments_by_id, id)) end),
             do:
               {:error,
                %QueryError{
                  code: :invalid_filters,
                  message: "Invalid filters. Some segments don't exist or aren't accessible."
                }},
             else: :ok
           ) do
      {:ok, segments_by_id}
    end
  end

  defp expand_first_level_and_filters(filter) do
    case filter do
      [:and, clauses] -> clauses
      filter -> [filter]
    end
  end

  defp replace_segment_with_filter_tree([_, "segment", clauses], preloaded_segments) do
    if length(clauses) == 1 do
      [[:and, Map.get(preloaded_segments, Enum.at(clauses, 0))]]
    else
      [[:or, Enum.map(clauses, fn id -> [:and, Map.get(preloaded_segments, id)] end)]]
    end
  end

  defp replace_segment_with_filter_tree(_filter, _preloaded_segments) do
    nil
  end

  @doc """
  ## Examples

    iex> resolve_segments([[:is, "visit:entry_page", ["/home"]]], %{})
    {:ok, [[:is, "visit:entry_page", ["/home"]]]}

    iex> resolve_segments([[:is, "visit:entry_page", ["/home"]], [:is, "segment", [1]]], %{1 => [[:contains, "visit:entry_page", ["blog"]], [:is, "visit:country", ["PL"]]]})
    {:ok, [
      [:is, "visit:entry_page", ["/home"]],
      [:contains, "visit:entry_page", ["blog"]],
      [:is, "visit:country", ["PL"]]
    ]}

    iex> resolve_segments([[:is, "visit:entry_page", ["/home"]], [:is, "segment", [1]], [:is, "segment", [2]]], %{1 => [[:is, "visit:country", ["PL"]]], 2 => [[:is, "event:goal", ["Signup"]]]})
    {:ok, [
      [:is, "visit:entry_page", ["/home"]],
      [:is, "visit:country", ["PL"]],
      [:is, "event:goal", ["Signup"]]
    ]}


    iex> resolve_segments([[:is, "segment", [1, 2]]], %{1 => [[:contains, "event:goal", ["Singup"]], [:is, "visit:country", ["PL"]]], 2 => [[:contains, "event:goal", ["Sauna"]], [:is, "visit:country", ["EE"]]]})
    {:ok, [
      [:or, [
        [:and, [[:contains, "event:goal", ["Singup"]], [:is, "visit:country", ["PL"]]]],
        [:and, [[:contains, "event:goal", ["Sauna"]], [:is, "visit:country", ["EE"]]]]]
      ]
    ]}
  """
  def resolve_segments(original_filters, preloaded_segments) do
    if map_size(preloaded_segments) > 0 do
      {:ok,
       original_filters
       |> Filters.transform_filters(fn f ->
         replace_segment_with_filter_tree(f, preloaded_segments)
       end)
       |> Filters.transform_filters(&expand_first_level_and_filters/1)}
    else
      {:ok, original_filters}
    end
  end
end
