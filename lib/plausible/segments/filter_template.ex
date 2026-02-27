defmodule Plausible.Segments.FilterTemplate do
  @moduledoc """
  Schema for storing filter template configurations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "filter_templates" do
    field :site_id, :binary_id
    field :name, :string
    field :filter_tree, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:site_id, :name, :filter_tree])
    |> validate_required([:site_id, :name, :filter_tree])
    |> validate_length(:name, max: 100)
    |> validate_filter_tree()
    |> unique_constraint([:name], name: :filter_templates_site_id_name_index)
  end

  defp validate_filter_tree(changeset) do
    validate_change(:filter_tree, fn :filter_tree, tree ->
      case Plausible.Segments.FilterParser.parse(tree) do
        {:ok, _} -> []
        {:error, reason} -> [filter_tree: reason]
      end
    end)
  end
end
