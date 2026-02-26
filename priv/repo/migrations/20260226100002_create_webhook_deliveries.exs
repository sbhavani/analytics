defmodule Plausible.Repo.Migrations.CreateWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :trigger_id, references(:webhook_triggers, on_delete: :delete_all), null: false
      add :payload, :jsonb, null: false
      add :status_code, :integer
      add :response_body, :text
      add :attempt, :integer, default: 1, null: false
      add :success, :boolean, null: false
      add :error_message, :text

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:trigger_id])
    create index(:webhook_deliveries, [:inserted_at])
  end
end
