defmodule Plausible.Repo.Migrations.CreateDeliveries do
  use Ecto.Migration

  def change do
    create table(:deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_id, :uuid, null: false
      add :url, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :response_body, :string
      add :error_message, :string
      add :attempt, :integer, default: 1, null: false
      add :payload, :jsonb, null: false
      add :trigger_type, :string
      add :event_data, :jsonb

      timestamps()
    end

    create index(:deliveries, [:webhook_id])
    create index(:deliveries, [:event_id])
    create index(:deliveries, [:status])
    create index(:deliveries, [:trigger_type])
  end
end
