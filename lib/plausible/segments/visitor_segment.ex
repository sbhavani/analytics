defmodule Plausible.Segments.VisitorSegment do
  @moduledoc """
  Schema for a saved visitor segment with advanced filter configuration.
  """
  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "segments" do
    field :name, :string

    # Advanced filter builder fields
    field :root_group_id, :uuid

    # Backward compatibility with existing segment schema
    field :type, :string, default: "site"
    field :segment_data, :map

    belongs_to :site, Plausible.Site, foreign_key: :site_id, type: :uuid
    belongs_to :owner, Plausible.Auth.User, foreign_key: :owner_id, type: :uuid
    belongs_to :root_group, Plausible.Segments.FilterGroup, foreign_key: :root_group_id, type: :uuid

    has_many :filter_groups, Plausible.Segments.FilterGroup, foreign_key: :segment_id, delete: :delete_all

    timestamps()
  end

  def changeset(segment, attrs) do
    segment
    |> cast(attrs, [
      :name,
      :site_id,
      :root_group_id,
      :type,
      :segment_data,
      :owner_id
    ])
    |> validate_required([:name, :site_id, :type])
    |> validate_length(:name, count: :bytes, min: 1, max: 100)
    |> foreign_key_constraint(:site_id)
    |> foreign_key_constraint(:owner_id)
    |> unique_constraint(:name, name: :segments_site_id_name_index)
  end

  @doc """
  Check if the segment has a valid filter configuration
  """
  def has_filters?(%__MODULE__{root_group_id: nil}), do: false
  def has_filters?(%__MODULE__{}), do: true

  @doc """
  Create a new visitor segment with filter configuration.
  """
  def create(site, attrs, user) do
    %__MODULE__{}
    |> changeset(%{
      name: attrs[:name],
      site_id: site.id,
      owner_id: user.id,
      root_group_id: attrs[:root_group_id],
      type: attrs[:type] || "site",
      segment_data: attrs[:segment_data]
    })
    |> Plausible.Repo.insert()
  end
end
