defmodule Plausible.Repo.Migrations.AddTriggerTypeToDeliveries do
  use Ecto.Migration

  def change do
    alter table(:deliveries) do
      add :trigger_type, :string
      add :event_data, :jsonb
    end

    create index(:deliveries, [:trigger_type])
  end
end
