defmodule Plausible.Auth.SSO.Domain do
  @moduledoc """
  SSO Domain schema - represents a domain that triggers SSO for a team.
  """

  use Plausible
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "sso_domains" do
    field :identifier, :binary
    field :domain, :string
    field :validated_via, :string
    field :last_validated_at, :naive_datetime
    field :status, :string

    belongs_to :sso_integration, Plausible.Auth.SSO.Integration

    timestamps()
  end

  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:identifier, :domain, :validated_via, :last_validated_at, :status, :sso_integration_id])
    |> validate_required([:identifier, :domain, :status, :sso_integration_id])
    |> validate_inclusion(:status, ["pending", "valid", "invalid"])
    |> unique_constraint(:domain)
    |> unique_constraint(:identifier)
  end
end
