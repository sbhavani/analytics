defmodule Plausible.Segments.FilterGroup do
  @moduledoc """
  Schema for a group of filter conditions with AND/OR logic.
  Supports nested groups through parent_group_id.
  """
  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "filter_groups" do
    field :operator, :string
    field :sort_order, :integer

    belongs_to :segment, Plausible.Segments.VisitorSegment, foreign_key: :segment_id, type: :uuid
    belongs_to :parent_group, Plausible.Segments.FilterGroup, foreign_key: :parent_group_id, type: :uuid

    has_many :conditions, Plausible.Segments.FilterCondition, foreign_key: :group_id, delete: :delete_all
    has_many :nested_groups, Plausible.Segments.FilterGroup, foreign_key: :parent_group_id, as: :children

    timestamps()
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:operator, :sort_order, :segment_id, :parent_group_id])
    |> validate_required([:operator, :segment_id])
    |> validate_inclusion(:operator, ["AND", "OR"])
    |> check_constraint(:operator, name: :filter_groups_operator_check)
  end

  @doc """
  Calculate the depth of this group in the tree.
  Returns 0 for root groups, 1 for first-level nested groups, etc.
  """
  def depth(group, acc \\ 0)

  def depth(%__MODULE__{parent_group_id: nil}, acc), do: acc

  def depth(%__MODULE__{parent_group_id: parent_id}, acc) when not is_nil(parent_id) do
    # This would need to be calculated from the database
    # For now, we track it when building the tree
    acc + 1
  end
end
