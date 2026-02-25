defmodule Plausible.Repo.Migrations.CreateWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :trigger_type, :string, null: false
      add :payload, :json, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :response_body, :string
      add :attempts, :integer, default: 0, null: false
      add :next_retry_at, :naive_datetime
      add :delivered_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:status])
    create index(:webhook_deliveries, [:created_at])
  end
end
