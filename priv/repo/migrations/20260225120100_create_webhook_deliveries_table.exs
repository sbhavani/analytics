defmodule Plausible.Repo.Migrations.CreateWebhookDeliveriesTable do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :response_body, :string
      add :retry_count, :integer, default: 0, null: false

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:inserted_at])
    create index(:webhook_deliveries, [:status])
  end
end
