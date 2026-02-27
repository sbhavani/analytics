defmodule Plausible.Repo.Migrations.CreateFilterTemplates do
  use Ecto.Migration

  def change do
    create table(:filter_templates, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references("sites", on_delete: :delete_all), null: false
      add :name, :string, null: false, size: 100
      add :filter_tree, :jsonb, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:filter_templates, [:site_id])
    create unique_index(:filter_templates, [:site_id, :name])
  end
end
