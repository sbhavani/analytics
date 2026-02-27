defmodule Plausible.Repo.Migrations.AddFilterTreeToSegments do
  @moduledoc """
  Adds filter_tree column to support advanced filter builder with AND/OR nested groups.
  """
  use Ecto.Migration

  def change do
    alter table(:segments) do
      add :filter_tree, :map
    end

    create index(:segments, [:filter_tree], using: :gin, if_not_exists: true)
  end
end
