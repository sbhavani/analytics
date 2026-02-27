defmodule PlausibleWeb.Api.SegmentController do
  @moduledoc """
  API controller for managing filter templates and segment previews.

  Endpoints:
  - GET /api/v1/sites/:site_id/filter-templates - List all templates
  - POST /api/v1/sites/:site_id/filter-templates - Create a template
  - GET /api/v1/sites/:site_id/filter-templates/:id - Get a template
  - PUT /api/v1/sites/:site_id/filter-templates/:id - Update a template
  - DELETE /api/v1/sites/:site_id/filter-templates/:id - Delete a template
  - POST /api/v1/sites/:site_id/segments/preview - Preview matching visitors
  """

  use Plausible
  use PlausibleWeb, :controller
  use Plausible.Repo
  use PlausibleWeb.Plugs.ErrorHandler

  alias Plausible.Segments.FilterTemplateRepo
  alias Plausible.Segments.FilterParser
  alias Plausible.Segments.FilterEvaluator
  alias PlausibleWeb.Api.Helpers, as: H

  # The site is loaded by the AuthorizePublicAPI plug via api_context: :site
  # Filter Templates CRUD

  @doc """
  List all filter templates for a site.

  GET /api/v1/sites/:site_id/filter-templates
  """
  def list_templates(conn, %{"site_id" => _site_id}) do
    site = conn.assigns[:site]

    templates = FilterTemplateRepo.list_by_site(site.id)

    conn
    |> put_status(200)
    |> json(%{
      data: Enum.map(templates, &template_to_json/1)
    })
  end

  @doc """
  Create a new filter template.

  POST /api/v1/sites/:site_id/filter-templates
  """
  def create_template(conn, %{"site_id" => _site_id, "name" => name, "filter_tree" => filter_tree}) do
    site = conn.assigns[:site]

    case FilterParser.parse(filter_tree) do
      {:ok, _parsed} ->
        attrs = %{
          site_id: site.id,
          name: name,
          filter_tree: filter_tree
        }

        case FilterTemplateRepo.create(attrs) do
          {:ok, template} ->
            conn
            |> put_status(201)
            |> json(%{
              data: template_to_json(template)
            })

          {:error, %{errors: errors}} ->
            if Enum.any?(errors, fn {field, _} -> field == :name end) do
              H.bad_request(conn, "A template with this name already exists for this site")
            else
              H.bad_request(conn, "Invalid template data")
            end
        end

      {:error, reason} ->
        H.bad_request(conn, "Invalid filter tree: #{reason}")
    end
  end

  def create_template(conn, _) do
    H.bad_request(conn, "Missing required fields: name, filter_tree")
  end

  @doc """
  Get a specific filter template.

  GET /api/v1/sites/:site_id/filter-templates/:id
  """
  def get_template(conn, %{"site_id" => _site_id, "id" => id}) do
    site = conn.assigns[:site]

    case FilterTemplateRepo.get!(site.id, id) do
      nil ->
        H.not_found(conn, "Template not found")

      template ->
        conn
        |> put_status(200)
        |> json(%{
          data: template_to_json(template)
        })
    end
  end

  @doc """
  Update an existing filter template.

  PUT /api/v1/sites/:site_id/filter-templates/:id
  """
  def update_template(conn, %{"site_id" => _site_id, "id" => id}) do
    site = conn.assigns[:site]

    case FilterTemplateRepo.get!(site.id, id) do
      nil ->
        H.not_found(conn, "Template not found")

      template ->
        attrs = Map.take(conn.params, ["name", "filter_tree"])

        # Validate filter_tree if provided
        if Map.has_key?(attrs, "filter_tree") do
          case FilterParser.parse(attrs["filter_tree"]) do
            {:ok, _parsed} ->
              do_update_template(conn, template, attrs)

            {:error, reason} ->
              H.bad_request(conn, "Invalid filter tree: #{reason}")
          end
        else
          do_update_template(conn, template, attrs)
        end
    end
  end

  defp do_update_template(conn, template, attrs) do
    # Convert string keys to atoms for the changeset
    attrs =
      attrs
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Enum.into(%{})

    case FilterTemplateRepo.update(template, attrs) do
      {:ok, updated_template} ->
        conn
        |> put_status(200)
        |> json(%{
          data: template_to_json(updated_template)
        })

      {:error, %{errors: errors}} ->
        if Enum.any?(errors, fn {field, _} -> field == :name end) do
          H.bad_request(conn, "A template with this name already exists for this site")
        else
          H.bad_request(conn, "Invalid template data")
        end
    end
  end

  @doc """
  Delete a filter template.

  DELETE /api/v1/sites/:site_id/filter-templates/:id
  """
  def delete_template(conn, %{"site_id" => _site_id, "id" => id}) do
    site = conn.assigns[:site]

    case FilterTemplateRepo.get!(site.id, id) do
      nil ->
        H.not_found(conn, "Template not found")

      template ->
        {:ok, _deleted} = FilterTemplateRepo.delete(template)

        conn
        |> put_status(204)
        |> json(%{})
    end
  end

  # Segment Preview

  @doc """
  Preview matching visitor count for a filter tree.

  POST /api/v1/sites/:site_id/segments/preview

  Request body:
  ```json
  {
    "filter_tree": {...},
    "date_range": {
      "period": "month",
      "from": "2026-01-01",
      "to": "2026-01-31"
    }
  }
  ```

  Response:
  ```json
  {
    "matching_visitors": 1234,
    "total_visitors": 5000,
    "percentage": 24.68
  }
  ```
  """
  def preview(conn, %{"site_id" => _site_id, "filter_tree" => filter_tree, "date_range" => date_range}) do
    site = conn.assigns[:site]

    case FilterParser.parse(filter_tree) do
      {:ok, parsed_tree} ->
        case parse_date_range(date_range) do
          {:ok, {from_date, to_date}} ->
            # Get total visitors for the period
            total_visitors =
              Plausible.Stats.visitor_count(site, %{
                date_range: {from_date, to_date}
              })

            # Get matching visitor count
            matching_visitors = FilterEvaluator.get_visitor_count(site, parsed_tree, from_date, to_date)

            percentage =
              if total_visitors > 0 do
                Float.round(matching_visitors / total_visitors * 100, 2)
              else
                0.0
              end

            conn
            |> put_status(200)
            |> json(%{
              matching_visitors: matching_visitors,
              total_visitors: total_visitors,
              percentage: percentage
            })

          {:error, reason} ->
            H.bad_request(conn, "Invalid date range: #{reason}")
        end

      {:error, reason} ->
        H.bad_request(conn, "Invalid filter tree: #{reason}")
    end
  end

  def preview(conn, %{"site_id" => _site_id}) do
    H.bad_request(conn, "Missing required fields: filter_tree, date_range")
  end

  # Private helpers

  defp template_to_json(template) do
    %{
      id: template.id,
      name: template.name,
      filter_tree: template.filter_tree,
      inserted_at: template.inserted_at |> DateTime.to_iso8601(),
      updated_at: template.updated_at |> DateTime.to_iso8601()
    }
  end

  defp parse_date_range(%{"period" => "custom", "from" => from_str, "to" => to_str}) do
    with {:ok, from} <- Date.from_iso8601(from_str),
         {:ok, to} <- Date.from_iso8601(to_str) do
      {:ok, {from, to}}
    else
      _ -> {:error, "Invalid date format"}
    end
  end

  defp parse_date_range(%{"period" => period}) do
    now = Date.utc_today()

    case period do
      "day" ->
        {:ok, {now, now}}

      "7d" ->
        from = Date.add(now, -6)
        {:ok, {from, now}}

      "30d" ->
        from = Date.add(now, -29)
        {:ok, {from, now}}

      "month" ->
        from = %{now | day: 1}
        {:ok, {from, now}}

      "12mo" ->
        from = %{now | day: 1} |> Date.add(-365)
        {:ok, {from, now}}

      _ ->
        {:error, "Unknown period: #{period}"}
    end
  end

  defp parse_date_range(_), do: {:error, "Missing date_range"}
end
