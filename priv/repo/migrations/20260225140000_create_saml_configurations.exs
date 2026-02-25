defmodule Plausible.Repo.Migrations.CreateSAMLConfigurations do
  use Ecto.Migration

  import Plausible.MigrationUtils

  def change do
    if enterprise_edition?() do
      create table(:saml_configurations) do
        add :idp_entity_id, :string, null: false
        add :idp_sso_url, :string, null: false
        add :idp_certificate, :text, null: false
        add :enabled, :boolean, default: false, null: false

        add :team_id, references(:teams, on_delete: :delete_all), null: false

        timestamps()
      end

      create unique_index(:saml_configurations, [:team_id])
      create index(:saml_configurations, [:team_id])
    end
  end
end
