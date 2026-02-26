defmodule Plausible.Repo.Migrations.CreateWebhookDeliveryLogs do
  use Ecto.Migration

  def change do
    create table(:webhook_delivery_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_event_id, references(:webhook_events, on_delete: :delete_all), null: false
      add :status_code, :integer
      add :response_body, :text
      add :error_message, :text
      add :delivered_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_delivery_logs, [:webhook_event_id])
  end
end
