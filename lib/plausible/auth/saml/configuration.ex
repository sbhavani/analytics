defmodule Plausible.Auth.SAML.Configuration do
  @moduledoc """
  Schema for SAML Identity Provider configuration per team.
  """

  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  on_ee do
    schema "saml_configurations" do
      field :idp_entity_id, :string
      field :idp_sso_url, :string
      field :idp_certificate, :string
      field :enabled, :boolean, default: false

      belongs_to :team, Plausible.Teams.Team

      timestamps()
    end
  else
    # CE doesn't have SAML support - provide a stub for compilation
    def t(), do: :no_saml_in_ce
  end

  on_ee do
    @required_fields [:idp_entity_id, :idp_sso_url, :idp_certificate, :team_id]
    @optional_fields [:enabled]

    def changeset(config \\ %__MODULE__{}, attrs) do
      config
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_format(:idp_entity_id, ~r/^https?:\/\/.+/, message: "must be a valid URI")
      |> validate_format(:idp_sso_url, ~r/^https:\/\/.+/, message: "must be a valid HTTPS URL")
      |> validate_length(:idp_entity_id, max: 500)
      |> validate_length(:idp_sso_url, max: 500)
      |> unique_constraint(:team_id)
    end
  end
end
