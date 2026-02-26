defmodule Plausible.Repo.Migrations.CreateWebhookEvents do
  use Ecto.Migration

  def change do
    create table(:webhook_events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false, default: "pending"
      add :attempts, :integer, null: false, default: 0
      add :last_attempt_at, :naive_datetime

      timestamps()
    end

    create index(:webhook_events, [:webhook_id])
    create index(:webhook_events, [:status])
    create index(:webhook_events, [:webhook_id, :status])
  end
end
