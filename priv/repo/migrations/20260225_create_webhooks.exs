defmodule Plausible.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :url, :string, null: false, size: 500
      add :secret, :string, size: 64
      add :name, :string, size: 100
      add :events, {:array, :string}, null: false
      add :enabled, :boolean, default: true, null: false
      add :failure_threshold, :integer, default: 3, null: false

      timestamps()
    end

    create index(:webhooks, [:site_id])
    create index(:webhooks, [:site_id], where: "enabled = true")
  end
end
