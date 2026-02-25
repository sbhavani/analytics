defmodule Plausible.Repo.Migrations.CreateTriggers do
  use Ecto.Migration

  def change do
    create table(:triggers, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :webhook_id, references(:webhooks, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :threshold, :integer
      add :goal_id, references(:goals, on_delete: :nilify_all)

      timestamps()
    end

    create index(:triggers, [:webhook_id])
    create index(:triggers, [:goal_id])
    create index(:triggers, [:type])
  end
end
