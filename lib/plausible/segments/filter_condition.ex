defmodule Plausible.Segments.FilterCondition do
  @moduledoc """
  Schema for a single filter condition in the advanced filter builder.
  """
  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @valid_operators ~w(equals not_equals greater_than less_than contains is_empty is_not_empty)

  @type t() :: %__MODULE__{}

  schema "filter_conditions" do
    field :field, :string
    field :operator, :string
    field :value, :string

    belongs_to :group, Plausible.Segments.FilterGroup, foreign_key: :group_id, type: :uuid

    timestamps()
  end

  def changeset(condition, attrs) do
    condition
    |> cast(attrs, [:field, :operator, :value, :group_id])
    |> validate_required([:field, :operator, :group_id])
    |> validate_inclusion(:operator, @valid_operators)
    |> validate_required_for_operator()
  end

  # Value is required unless operator is is_empty or is_not_empty
  defp validate_required_for_operator(changeset) do
    operator = get_field(changeset, :operator)

    if operator in ["is_empty", "is_not_empty"] do
      changeset
    else
      validate_required(changeset, [:value])
    end
  end

  def valid_operators, do: @valid_operators
end
