defmodule Plausible.Segments.Context do
  @moduledoc """
  Context module for managing visitor segments.
  """
  alias Plausible.Segments.{
    FilterCondition,
    FilterGroup,
    VisitorSegment,
    Query
  }
  alias Plausible.Repo
  alias Plausible.Site

  require Logger

  @max_conditions 10

  @doc """
  List all segments for a site with visitor counts.
  """
  def list_segments(%Site{} = site) do
    segments = VisitorSegment
      |> where([s], s.site_id == ^site.id)
      |> Repo.all()
      |> Repo.preload([:root_group])

    Enum.map(segments, fn segment ->
      visitor_count = if segment.root_group do
        filter_tree = build_filter_tree_from_segment(segment)
        case Query.validate_filter_tree(filter_tree) do
          :ok -> Query.preview_count(site, filter_tree)
          _ -> 0
        end
      else
        0
      end

      Map.put(segment, :visitor_count, visitor_count)
    end)
  end

  defp build_filter_tree_from_segment(%VisitorSegment{root_group: nil}) do
    %{operator: "AND", conditions: [], groups: []}
  end

  defp build_filter_tree_from_segment(%VisitorSegment{} = segment) do
    root_group = segment.root_group |> Repo.preload([:conditions, :nested_groups])

    %{
      operator: root_group.operator,
      conditions: Enum.map(root_group.conditions || [], &serialize_condition/1),
      groups: Enum.map(root_group.nested_groups || [], &serialize_group/1)
    }
  end

  defp serialize_condition(condition) do
    %{
      "field" => condition.field,
      "operator" => condition.operator,
      "value" => condition.value
    }
  end

  defp serialize_group(group) do
    group = Repo.preload(group, [:conditions, :nested_groups])
    %{
      "operator" => group.operator,
      "conditions" => Enum.map(group.conditions || [], &serialize_condition/1),
      "groups" => Enum.map(group.nested_groups || [], &serialize_group/1)
    }
  end

  @doc """
  Get a segment by ID.
  """
  def get_segment!(id) do
    VisitorSegment
    |> Repo.get!(id)
    |> Repo.preload([
      :filter_groups,
      root_group: [
        :conditions,
        nested_groups: [:conditions, :nested_groups]
      ]
    ])
  end

  @doc """
  Create a new segment with filter configuration.
  """
  def create_segment(%Site{} = site, attrs, user) do
    Logger.info("Creating segment", segment_name: attrs["name"], site_id: site.id)

    # Validate max conditions before proceeding
    filter_tree = attrs["filter_tree"]

    with :ok <- validate_max_conditions(filter_tree) do
      create_segment_impl(site, attrs, user)
    end
  end

  defp create_segment_impl(%Site{} = site, attrs, user) do
    segment_attrs = %{
      name: attrs["name"],
      site_id: site.id,
      owner_id: user.id,
      type: "site"
    }

    Repo.transaction(fn ->
      with {:ok, root_group} <- create_filter_group(attrs["filter_tree"], nil),
           segment_attrs = Map.put(segment_attrs, :root_group_id, root_group.id),
           {:ok, segment} <- %VisitorSegment{} |> VisitorSegment.changeset(segment_attrs) |> Repo.insert() do
        # Link root group to segment
        root_group
        |> FilterGroup.changeset(%{segment_id: segment.id})
        |> Repo.update!()

        Logger.info("Segment created", segment_id: segment.id)

        segment |> Repo.preload([:root_group])
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Update an existing segment.
  """
  def update_segment(%VisitorSegment{} = segment, attrs) do
    Logger.info("Updating segment", segment_id: segment.id)

    # Validate max conditions before proceeding
    filter_tree = attrs["filter_tree"]

    with :ok <- validate_max_conditions(filter_tree) do
      update_segment_impl(segment, attrs)
    end
  end

  defp update_segment_impl(%VisitorSegment{} = segment, attrs) do
    Repo.transaction(fn ->
      # Delete existing groups and conditions
      segment
      |> Repo.preload([:filter_groups])
      |> Enum.each(fn group ->
        group
        |> Repo.preload([:conditions])
        |> Enum.each(fn c ->
          Repo.delete!(c)
        end)
        Repo.delete!(group)
      end)

      # Create new filter tree
      with {:ok, root_group} <- create_filter_group(attrs["filter_tree"], segment.id),
           {:ok, _} <- segment
             |> VisitorSegment.changeset(Map.put(attrs, :root_group_id, root_group.id))
             |> Repo.update() do
        Logger.info("Segment updated", segment_id: segment.id)
        segment |> Repo.preload([:root_group])
      else
        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Delete a segment.
  """
  def delete_segment(%VisitorSegment{} = segment) do
    Logger.info("Deleting segment", segment_id: segment.id)
    Repo.delete(segment)
  end

  @doc """
  Preview visitor count for a filter configuration.
  Returns {:ok, count} on success, {:error, :timeout} if query takes too long,
  or {:error, reason} for other errors.
  """
  def preview_segment(%Site{} = site, filter_tree) do
    Logger.info("Previewing segment", site_id: site.id)

    with :ok <- validate_max_conditions(filter_tree),
         :ok <- Query.validate_filter_tree(filter_tree) do
      case Query.preview_count(site, filter_tree) do
        {:ok, count} ->
          {:ok, count}
        {:error, :timeout} ->
          {:error, :timeout}
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp create_filter_group(nil, _segment_id), do: {:ok, nil}

  defp create_filter_group(filter_tree, segment_id) do
    operator = Map.get(filter_tree, "operator", "AND")

    %FilterGroup{}
    |> FilterGroup.changeset(%{
      operator: operator,
      segment_id: segment_id
    })
    |> Repo.insert()
    |> case do
      {:ok, group} ->
        # Create conditions
        conditions = Map.get(filter_tree, "conditions", [])

        Enum.each(conditions, fn cond_attrs ->
          %FilterCondition{}
          |> FilterCondition.changeset(%{
            group_id: group.id,
            field: cond_attrs["field"],
            operator: cond_attrs["operator"],
            value: cond_attrs["value"]
          })
          |> Repo.insert!()
        end)

        # Create nested groups
        nested_groups = Map.get(filter_tree, "groups", [])

        Enum.each(nested_groups, fn nested_tree ->
          {:ok, _nested_group} = create_filter_group_with_parent(nested_tree, group.id, segment_id)
        end)

        {:ok, group}

      error ->
        error
    end
  end

  defp create_filter_group_with_parent(filter_tree, parent_group_id, segment_id) do
    operator = Map.get(filter_tree, "operator", "AND")

    %FilterGroup{}
    |> FilterGroup.changeset(%{
      operator: operator,
      parent_group_id: parent_group_id,
      segment_id: segment_id
    })
    |> Repo.insert()
    |> case do
      {:ok, group} ->
        conditions = Map.get(filter_tree, "conditions", [])

        Enum.each(conditions, fn cond_attrs ->
          %FilterCondition{}
          |> FilterCondition.changeset(%{
            group_id: group.id,
            field: cond_attrs["field"],
            operator: cond_attrs["operator"],
            value: cond_attrs["value"]
          })
          |> Repo.insert!()
        end)

        nested_groups = Map.get(filter_tree, "groups", [])

        Enum.each(nested_groups, fn nested_tree ->
          {:ok, _} = create_filter_group_with_parent(nested_tree, group.id, segment_id)
        end)

        {:ok, group}

      error ->
        error
    end
  end

  # Validate that filter tree has at most @max_conditions conditions
  defp validate_max_conditions(nil), do: :ok

  defp validate_max_conditions(filter_tree) do
    count = count_conditions(filter_tree)

    if count > @max_conditions do
      {:error, "Maximum #{@max_conditions} conditions allowed per segment. Found #{count}."}
    else
      :ok
    end
  end

  # Count all conditions in a filter tree recursively (including nested groups)
  defp count_conditions(nil), do: 0

  defp count_conditions(filter_tree) when is_map(filter_tree) do
    direct_conditions = Map.get(filter_tree, "conditions", []) |> length()

    nested_groups = Map.get(filter_tree, "groups", [])
    nested_conditions = Enum.reduce(nested_groups, 0, fn group, acc ->
      acc + count_conditions(group)
    end)

    direct_conditions + nested_conditions
  end

  defp count_conditions(_), do: 0
end
