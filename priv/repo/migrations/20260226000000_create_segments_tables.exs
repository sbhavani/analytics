defmodule Plausible.Repo.Migrations.CreateSegmentsTables do
  use Ecto.Migration

  def change do
    # Create segments table - enhanced for advanced filter builder
    create table(:segments, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :site_id, references(:sites, on_delete: :delete_all, type: :uuid), null: false
      add :name, :string, null: false, size: 100
      add :root_group_id, references(:filter_groups, on_delete: :delete_all, type: :uuid)

      # Keep existing fields for backward compatibility
      add :type, :string, default: "site"
      add :segment_data, :map
      add :owner_id, references(:users, on_delete: :nilify_all, type: :uuid)

      timestamps()
    end

    create index(:segments, [:site_id])
    create index(:segments, [:site_id, :name], unique: true)

    # Create filter_groups table for AND/OR logic and nesting
    create table(:filter_groups, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :segment_id, references(:segments, on_delete: :delete_all, type: :uuid), null: false
      add :parent_group_id, references(:filter_groups, on_delete: :delete_all, type: :uuid)
      add :operator, :string, null: false, size: 3
      add :sort_order, :integer, default: 0

      timestamps()
    end

    create index(:filter_groups, [:segment_id])
    create index(:filter_groups, [:parent_group_id])

    # Create filter_conditions table
    create table(:filter_conditions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :group_id, references(:filter_groups, on_delete: :delete_all, type: :uuid), null: false
      add :field, :string, null: false, size: 50
      add :operator, :string, null: false, size: 20
      add :value, :text

      timestamps()
    end

    create index(:filter_conditions, [:group_id])

    # Add check constraints
    execute """
    ALTER TABLE filter_groups
    ADD CONSTRAINT filter_groups_operator_check
    CHECK (operator IN ('AND', 'OR'))
    """, """
    ALTER TABLE filter_groups
    DROP CONSTRAINT filter_groups_operator_check
    """

    execute """
    ALTER TABLE filter_conditions
    ADD CONSTRAINT filter_conditions_operator_check
    CHECK (operator IN ('equals', 'not_equals', 'greater_than', 'less_than', 'contains', 'is_empty', 'is_not_empty'))
    """, """
    ALTER TABLE filter_conditions
    DROP CONSTRAINT filter_conditions_operator_check
    """
  end
end
