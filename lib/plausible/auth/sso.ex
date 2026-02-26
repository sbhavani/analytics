defmodule Plausible.Auth.SSO do
  @moduledoc """
  SSO authentication logic using SAML 2.0
  """

  use Plausible
  import Ecto.Query

  alias Plausible.Auth.User
  alias Plausible.Teams
  alias Plausible.Repo

  require Logger

  defmodule Identity do
    @moduledoc """
    SSO Identity - represents an authenticated user from an IdP
    """
    defstruct [:email, :name, :integration_id, :expires_at, :sso_identity_id]

    @type t :: %__MODULE__{
            email: String.t(),
            name: String.t() | nil,
            integration_id: String.t(),
            expires_at: DateTime.t() | nil,
            sso_identity_id: String.t() | nil
          }
  end

  @doc """
  Find or create a user from SAML assertion attributes.
  """
  def find_or_create_user_from_saml_attrs(attrs) do
    email = attrs["email"]
    name = attrs["name"] || "SSO User"
    sso_identity_id = attrs["sso_identity_id"]
    integration_id = attrs["integration_id"]

    if user = Repo.get_by(User, email: email) do
      # Update existing user with SSO info
      user
      |> Ecto.Changeset.change(%{
        type: :sso,
        sso_identity_id: sso_identity_id,
        last_sso_login: NaiveDateTime.utc_now()
      })
      |> Repo.update!()
    else
      # Create new SSO user
      team = get_or_create_team_for_sso(integration_id)

      Repo.insert!(%User{
        email: email,
        name: name,
        type: :sso,
        sso_identity_id: sso_identity_id,
        last_sso_login: NaiveDateTime.utc_now(),
        email_verified: true,
        password: :crypto.strong_rand_bytes(32) |> Base.encode16(),
        password_hash: Plausible.Auth.Password.hash(""),
        email_verified: true
      })
    end
  end

  defp get_or_create_team_for_sso(nil) do
    # If no integration_id, use a default team or the user's first team
    nil
  end

  defp get_or_create_team_for_sso(integration_id) do
    # Get team from integration - to be implemented based on integration lookup
    nil
  end

  @doc """
  Check if an organization has SSO configured and enabled.
  """
  def sso_enabled_for_team?(team_id) do
    # Check if team has an active SSO integration
    # This is a placeholder - actual implementation would query sso_integrations table
    false
  end

  @doc """
  Get the SSO configuration for a team.
  """
  def get_sso_config(team_id) do
    # Fetch SSO config from database
    # This is a placeholder - actual implementation would query sso_integrations table
    nil
  end

  @doc """
  Validate SAML configuration.
  """
  def validate_config(config) do
    errors = []

    errors =
      if config[:idp_entity_id] in [nil, ""] do
        [{:idp_entity_id, "must be present"} | errors]
      else
        errors
      end

    errors =
      if config[:idp_sso_url] in [nil, ""] do
        [{:idp_sso_url, "must be present"} | errors]
      else
        errors
      end

    errors =
      if config[:idp_certificate] in [nil, ""] do
        [{:idp_certificate, "must be present"} | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, errors}
  end

  @doc """
  Test the SSO configuration by validating the IdP metadata.
  """
  def test_connection(config) do
    # In a real implementation, this would:
    # 1. Fetch the IdP metadata if URL provided
    # 2. Validate the certificate format
    # 3. Test connectivity to the IdP SSO endpoint
    {:ok, :connection_successful}
  end

  @doc """
  Check if user is ready to be provisioned via SSO.
  """
  def check_ready_to_provision(user, team) do
    # Check if user has all required fields for SSO provisioning
    if user.email do
      :ok
    else
      {:error, :missing_email}
    end
  end

  @doc """
  Provision a user from an SSO identity.
  This is called after successful SAML authentication.
  """
  def provision_user(%Identity{} = identity) do
    # First, find or create the team from the integration
    case get_team_by_integration(identity.integration_id) do
      nil ->
        {:error, :integration_not_found}

      team ->
        # Find or create the user
        user = find_or_create_user_from_identity(identity, team)
        {:ok, identity, team, user}
    end
  end

  defp get_team_by_integration(integration_id) do
    # Query the sso_integrations table to find the team
    # This is a placeholder - actual implementation would query the database
    nil
  end

  defp find_or_create_user_from_identity(identity, team) do
    # Check if user already exists with this email
    case Repo.get_by(User, email: identity.email) do
      nil ->
        # Create new user
        Repo.insert!(%User{
          email: identity.email,
          name: identity.name || "SSO User",
          type: :sso,
          sso_identity_id: identity.sso_identity_id,
          last_sso_login: NaiveDateTime.utc_now(),
          email_verified: true,
          password: :crypto.strong_rand_bytes(32) |> Base.encode16(),
          password_hash: Plausible.Auth.Password.hash("")
        })

      user ->
        # Update existing user with SSO info
        user
        |> Ecto.Changeset.change(%{
          type: :sso,
          sso_identity_id: identity.sso_identity_id,
          last_sso_login: NaiveDateTime.utc_now()
        })
        |> Repo.update!()
    end
  end
end
