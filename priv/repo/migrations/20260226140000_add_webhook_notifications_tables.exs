defmodule Plausible.Repo.Migrations.AddWebhookNotificationsTables do
  use Ecto.Migration

  def change do
    create table(:webhook_configs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :endpoint_url, :string, null: false
      add :secret, :string, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:webhook_configs, [:site_id])

    create table(:event_triggers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_config_id, references(:webhook_configs, on_delete: :delete_all), null: false
      add :trigger_type, :string, null: false
      add :is_enabled, :boolean, default: true, null: false
      add :threshold_value, :integer
      add :threshold_unit, :string

      timestamps()
    end

    create index(:event_triggers, [:webhook_config_id])

    create table(:webhook_delivery_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_config_id, references(:webhook_configs, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :jsonb, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :response_body, :text
      add :attempt_number, :integer, default: 1, null: false
      add :delivered_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_delivery_logs, [:webhook_config_id])
    create index(:webhook_delivery_logs, [:created_at])
  end
end
