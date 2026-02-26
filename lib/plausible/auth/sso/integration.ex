defmodule Plausible.Auth.SSO.Integration do
  @moduledoc """
  SSO Integration schema - represents an IdP configuration for a team.
  """

  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "sso_integrations" do
    field :identifier, :binary
    field :config, :map
    field :enabled, :boolean, default: false

    belongs_to :team, Plausible.Teams.Team

    has_many :sso_domains, Plausible.Auth.SSO.Domain

    timestamps()
  end

  def changeset(integration, attrs) do
    integration
    |> cast(attrs, [:identifier, :config, :team_id, :enabled])
    |> validate_required([:identifier, :config, :team_id])
    |> validate_config()
  end

  defp validate_config(changeset) do
    config = get_change(changeset, :config) || %{}

    errors =
      if config["idp_entity_id"] in [nil, ""] do
        [{:config, "IdP Entity ID is required"}]
      else
        []
      end

    errors =
      if config["idp_sso_url"] in [nil, ""] do
        [{:config, "IdP SSO URL is required"} | errors]
      else
        errors
      end

    errors =
      if config["idp_certificate"] in [nil, ""] do
        [{:config, "IdP Certificate is required"} | errors]
      else
        errors
      end

    if errors == [] do
      changeset
    else
      add_error(changeset, :config, errors)
    end
  end
end
