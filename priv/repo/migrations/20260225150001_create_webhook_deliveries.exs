defmodule Plausible.Repo.Migrations.CreateWebhookDeliveries do
  use Ecto.Migration

  def change do
    create table(:webhook_deliveries, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_configuration_id, references(:webhook_configurations, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false, default: "pending"
      add :response_code, :integer
      add :error_message, :text
      add :attempt_number, :integer, null: false, default: 1

      timestamps()
    end

    create index(:webhook_deliveries, [:webhook_configuration_id])
    create index(:webhook_deliveries, [:webhook_configuration_id, :inserted_at])
  end
end
