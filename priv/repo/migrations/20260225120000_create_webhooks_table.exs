defmodule Plausible.Repo.Migrations.CreateWebhooksTable do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :secret, :string, null: false
      add :triggers, {:array, :string}, null: false
      add :active, :boolean, default: true, null: false
      add :name, :string

      timestamps()
    end

    create index(:webhooks, [:site_id])
    create index(:webhooks, [:inserted_at])
  end
end
