defmodule Plausible.Repo.Migrations.CreateWebhookTriggers do
  use Ecto.Migration

  def change do
    create table(:webhook_triggers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :trigger_type, :string, null: false
      add :threshold, :integer
      add :goal_id, references(:goals, on_delete: :nilify_all)
      add :enabled, :boolean, default: true, null: false

      timestamps()
    end

    create index(:webhook_triggers, [:webhook_id])
    create index(:webhook_triggers, [:goal_id])
  end
end
