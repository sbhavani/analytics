defmodule Plausible.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :enabled, :boolean, null: false, default: true
      add :trigger_types, {:array, :string}, null: false, default: []

      timestamps()
    end

    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :jsonb, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :error_message, :text
      add :attempted_at, :naive_datetime, default: fragment("now()"), null: false
      add :completed_at, :naive_datetime

      timestamps()
    end

    # Indexes for query performance
    create index(:webhooks, [:site_id], concurrently: true)
    create index(:webhook_deliveries, [:webhook_id], concurrently: true)
    create index(:webhook_deliveries, [:status], concurrently: true)
    create index(:webhook_deliveries, [:attempted_at], concurrently: true)
  end
end
