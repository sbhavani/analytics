defmodule Plausible.Repo.Migrations.CreateWebhookConfigurations do
  use Ecto.Migration

  def change do
    create table(:webhook_configurations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :secret, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :triggers, {:array, :string}, null: false, default: []
      add :thresholds, :map, default: %{}
      add :deleted_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_configurations, [:site_id])
    create index(:webhook_configurations, [:site_id, :deleted_at])
  end
end
