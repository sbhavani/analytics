defmodule PlausibleWeb.Api.SegmentController do
  @moduledoc """
  API controller for advanced filter builder segments.
  """
  use Plausible
  use PlausibleWeb, :controller
  use Plausible.Repo
  use PlausibleWeb.Plugs.ErrorHandler

  alias Plausible.Segments.Context
  alias Plausible.Segments.VisitorSegment
  alias Plausible.Site
  alias PlausibleWeb.Api.Helpers, as: H

  require Logger

  @doc """
  Preview visitor count for a filter configuration.
  POST /api/sites/:site_id/segments/preview
  """
  def preview(conn, %{"site_id" => site_id, "filter_tree" => filter_tree}) do
    site = H.fetch_site(site_id, conn)

    case Context.preview_segment(site, filter_tree) do
      {:ok, count} ->
        json(conn, %{visitor_count: count})

      {:error, :timeout} ->
        conn
        |> put_status(408)
        json(%{error: %{code: :timeout, message: "Query timed out. Please try with fewer conditions or a narrower date range."}})

      {:error, reason} when is_binary(reason) ->
        conn
        |> put_status(400)
        json(%{error: %{code: :invalid_filter, message: reason}})

      {:error, _reason} ->
        conn
        |> put_status(500)
        json(%{error: %{code: :internal_error, message: "An error occurred while previewing the segment"}})
    end
  end

  @doc """
  List all segments for a site.
  GET /api/sites/:site_id/segments
  """
  def index(conn, %{"site_id" => site_id}) do
    site = H.fetch_site(site_id, conn)
    segments = Context.list_segments(site)

    json(conn, %{
      segments: Enum.map(segments, &serialize_segment/1)
    })
  end

  @doc """
  Get a single segment.
  GET /api/sites/:site_id/segments/:id
  """
  def show(conn, %{"site_id" => site_id, "id" => id}) do
    site = H.fetch_site(site_id, conn)

    case Context.get_segment!(id) do
      segment when segment.site_id == site.id ->
        json(conn, serialize_segment_with_filter(segment))

      _ ->
        conn
        |> put_status(404)
        json(%{error: %{code: :not_found}})
    end
  end

  @doc """
  Create a new segment.
  POST /api/sites/:site_id/segments
  """
  def create(conn, %{"site_id" => site_id, "name" => name, "filter_tree" => filter_tree})
      when is_binary(name) and is_map(filter_tree) do
    site = H.fetch_site(site_id, conn)
    user = conn.assigns[:current_user]

    case Context.create_segment(site, %{"name" => name, "filter_tree" => filter_tree}, user) do
      {:ok, segment} ->
        # Compute visitor count for the created segment
        filter_tree = build_filter_tree(segment)
        visitor_count = case Context.preview_segment(site, filter_tree) do
          {:ok, count} -> count
          _ -> 0
        end
        segment_with_count = Map.put(segment, :visitor_count, visitor_count)

        conn
        |> put_status(201)
        json(serialize_segment_with_filter(segment_with_count))

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)

        conn
        |> put_status(400)
        json(%{error: %{code: :validation_error, message: "Invalid segment", details: errors}})
    end
  end

  def create(conn, %{"site_id" => _site_id}) do
    conn
    |> put_status(400)
    json(%{error: %{code: :missing_required_fields, message: "name and filter_tree are required"}})
  end

  @doc """
  Update an existing segment.
  PUT /api/sites/:site_id/segments/:id
  """
  def update(conn, %{"site_id" => site_id, "id" => id} = params) do
    site = H.fetch_site(site_id, conn)

    segment = Context.get_segment!(id)

    if segment.site_id == site.id do
      attrs = Map.take(params, ["name", "filter_tree"])

      case Context.update_segment(segment, attrs) do
        {:ok, updated_segment} ->
          json(serialize_segment_with_filter(updated_segment))

        {:error, changeset} ->
          errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

          conn
          |> put_status(400)
          json(%{error: %{code: :validation_error, message: "Invalid segment", details: errors}})
      end
    else
      conn
      |> put_status(404)
      json(%{error: %{code: :not_found}})
    end
  end

  @doc """
  Delete a segment.
  DELETE /api/sites/:site_id/segments/:id
  """
  def delete(conn, %{"site_id" => site_id, "id" => id}) do
    site = H.fetch_site(site_id, conn)

    case Context.get_segment!(id) do
      segment when segment.site_id == site.id ->
        Context.delete_segment(segment)
        send_resp(conn, 204, "")

      _ ->
        conn
        |> put_status(404)
        json(%{error: %{code: :not_found}})
    end
  end

  # Serialization helpers

  defp serialize_segment(%VisitorSegment{} = segment) do
    %{
      id: segment.id,
      name: segment.name,
      visitor_count: segment.visitor_count || 0,
      created_at: segment.inserted_at,
      updated_at: segment.updated_at
    }
  end

  defp serialize_segment_with_filter(%VisitorSegment{} = segment) do
    base = serialize_segment(segment)

    Map.put(base, :filter_tree, build_filter_tree(segment))
  end

  defp build_filter_tree(%VisitorSegment{root_group_id: nil}) do
    %{operator: "AND", conditions: [], groups: []}
  end

  defp build_filter_tree(%VisitorSegment{} = segment) do
    root_group = segment.root_group

    if root_group do
      %{
        operator: root_group.operator,
        conditions: Enum.map(root_group.conditions || [], &serialize_condition/1),
        groups: Enum.map(root_group.nested_groups || [], &serialize_group/1)
      }
    else
      %{operator: "AND", conditions: [], groups: []}
    end
  end

  defp serialize_condition(condition) do
    %{
      id: condition.id,
      field: condition.field,
      operator: condition.operator,
      value: condition.value
    }
  end

  defp serialize_group(group) do
    %{
      id: group.id,
      operator: group.operator,
      conditions: Enum.map(group.conditions || [], &serialize_condition/1),
      groups: Enum.map(group.nested_groups || [], &serialize_group/1)
    }
  end
end
