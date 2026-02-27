defmodule Plausible.Segments.FilterTemplateRepo do
  @moduledoc """
  Data access functions for filter templates.
  """

  import Ecto.Query

  alias Plausible.Segments.FilterTemplate
  alias Plausible.Repo

  @doc """
  Lists all filter templates for a site.
  """
  @spec list_by_site(String.t()) :: [FilterTemplate.t()]
  def list_by_site(site_id) do
    FilterTemplate
    |> where([t], t.site_id == ^site_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
  end

  @doc """
  Gets a single filter template by ID.
  """
  @spec get!(String.t(), String.t()) :: FilterTemplate.t() | nil
  def get!(site_id, template_id) do
    FilterTemplate
    |> where([t], t.site_id == ^site_id and t.id == ^template_id)
    |> Repo.one()
  end

  @doc """
  Gets a filter template by name for a site.
  """
  @spec get_by_name(String.t(), String.t()) :: FilterTemplate.t() | nil
  def get_by_name(site_id, name) do
    FilterTemplate
    |> where([t], t.site_id == ^site_id and t.name == ^name)
    |> Repo.one()
  end

  @doc """
  Creates a new filter template.
  """
  @spec create(map()) :: {:ok, FilterTemplate.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %FilterTemplate{}
    |> FilterTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing filter template.
  """
  @spec update(FilterTemplate.t(), map()) :: {:ok, FilterTemplate.t()} | {:error, Ecto.Changeset.t()}
  def update(template, attrs) do
    template
    |> FilterTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a filter template.
  """
  @spec delete(FilterTemplate.t()) :: {:ok, FilterTemplate.t()} | {:error, Ecto.Changeset.t()}
  def delete(template) do
    Repo.delete(template)
  end
end
