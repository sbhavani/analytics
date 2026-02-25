defmodule Plausible.Repo.Migrations.CreateWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_type, :string, null: false, size: 50
      add :event_id, :string
      add :payload, :jsonb, null: false
      add :status, :string, null: false, default: "pending", size: 20
      add :response_code, :integer
      add :response_body, :string
      add :attempts, :integer, default: 0, null: false
      add :last_attempt_at, :naive_datetime
      add :next_retry_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_id, :status])
    create index(:webhook_deliveries, [:next_retry_at], where: "status = 'retrying'")
  end
end
