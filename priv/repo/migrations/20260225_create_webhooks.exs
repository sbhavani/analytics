defmodule Plausible.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    # Webhook configurations
    create table(:webhooks, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :secret, :string, null: false
      add :name, :string, null: false
      add :enabled, :boolean, default: true, null: false

      timestamps()
    end

    create index(:webhooks, [:site_id])

    # Webhook triggers
    create table(:webhook_triggers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :trigger_type, :string, null: false
      add :goal_id, references(:goals, on_delete: :delete_all), null: true
      add :threshold, :integer, null: true
      add :enabled, :boolean, default: true, null: false

      timestamps()
    end

    create index(:webhook_triggers, [:webhook_id])
    create index(:webhook_triggers, [:trigger_type])

    # Webhook deliveries
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :trigger_id, references(:webhook_triggers, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status_code, :integer, null: true
      add :response_body, :text, null: true
      add :error_message, :text, null: true
      add :attempt_number, :integer, default: 1, null: false

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:inserted_at])
  end
end
