defmodule Plausible.Auth.SAMLConfigs do
  @moduledoc """
  Context module for SAML configuration management.

  Provides functions for CRUD operations on SAML/SSO configurations,
  working with the SSO.Integration and SSO.Domain schemas.
  """

  use Plausible
  use Plausible.Repo
  import Ecto.Query

  alias Plausible.Auth.SSO.Integration
  alias Plausible.Auth.SSO.Domain
  alias Plausible.Teams.Team

  require Logger

  @doc """
  Get the SAML configuration for a team.
  Returns nil if no SSO integration exists for the team.
  """
  @spec get_config(Team.t() | non_neg_integer()) :: Integration.t() | nil
  def get_config(%Team{id: team_id}) do
    get_config(team_id)
  end

  def get_config(team_id) when is_integer(team_id) do
    Repo.get_by(Integration, team_id: team_id)
  end

  @doc """
  Get the SAML configuration for a team, raising if not found.
  """
  @spec get_config!(Team.t() | non_neg_integer()) :: Integration.t()
  def get_config!(%Team{id: team_id}) do
    get_config!(team_id)
  end

  def get_config!(team_id) when is_integer(team_id) do
    Repo.get_by!(Integration, team_id: team_id)
  end

  @doc """
  Check if SSO/SAML is enabled for a team.
  """
  @spec sso_enabled?(Team.t() | non_neg_integer()) :: boolean()
  def sso_enabled?(team) do
    get_config(team) != nil
  end

  @doc """
  Get all SAML configurations (for super admins).
  """
  @spec list_configs() :: [Integration.t()]
  def list_configs do
    Repo.all(Integration)
  end

  @doc """
  Find SAML configuration by domain.
  """
  @spec get_config_by_domain(String.t()) :: Integration.t() | nil
  def get_config_by_domain(domain) do
    domain
    |> Repo.get_by(Domain, domain: domain)
    |> case do
      nil ->
        nil

      %Domain{} = domain_record ->
        Repo.preload(domain_record, :sso_integration).sso_integration
    end
  end

  @doc """
  Create a new SAML configuration for a team.
  """
  @spec create_config(Team.t() | non_neg_integer(), map()) ::
          {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def create_config(%Team{id: team_id}, attrs) do
    create_config(team_id, attrs)
  end

  def create_config(team_id, attrs) when is_integer(team_id) do
    %Integration{team_id: team_id}
    |> Integration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update an existing SAML configuration.
  """
  @spec update_config(Integration.t(), map()) ::
          {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def update_config(%Integration{} = integration, attrs) do
    integration
    |> Integration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update SAML configuration by team ID.
  """
  @spec update_config_by_team(Team.t() | non_neg_integer(), map()) ::
          {:ok, Integration.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def update_config_by_team(%Team{id: team_id}, attrs) do
    update_config_by_team(team_id, attrs)
  end

  def update_config_by_team(team_id, attrs) when is_integer(team_id) do
    case get_config(team_id) do
      nil ->
        {:error, :not_found}

      integration ->
        update_config(integration, attrs)
    end
  end

  @doc """
  Delete a SAML configuration.
  """
  @spec delete_config(Integration.t()) :: {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def delete_config(%Integration{} = integration) do
    Repo.delete(integration)
  end

  @doc """
  Delete SAML configuration by team ID.
  """
  @spec delete_config_by_team(Team.t() | non_neg_integer()) ::
          {:ok, Integration.t()} | {:error, :not_found}
  def delete_config_by_team(%Team{id: team_id}) do
    delete_config_by_team(team_id)
  end

  def delete_config_by_team(team_id) when is_integer(team_id) do
    case get_config(team_id) do
      nil ->
        {:error, :not_found}

      integration ->
        delete_config(integration)
    end
  end

  @doc """
  Add a domain to a SAML configuration.
  """
  @spec add_domain(Integration.t(), String.t()) :: {:ok, Domain.t()} | {:error, Ecto.Changeset.t()}
  def add_domain(%Integration{} = integration, domain) do
    %Domain{sso_integration_id: integration.id}
    |> Domain.changeset(%{domain: domain})
    |> Repo.insert()
  end

  @doc """
  Add a domain to a SAML configuration by team ID.
  """
  @spec add_domain_by_team(Team.t() | non_neg_integer(), String.t()) ::
          {:ok, Domain.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def add_domain_by_team(%Team{id: team_id}, domain) do
    add_domain_by_team(team_id, domain)
  end

  def add_domain_by_team(team_id, domain) when is_integer(team_id) do
    case get_config(team_id) do
      nil ->
        {:error, :not_found}

      integration ->
        add_domain(integration, domain)
    end
  end

  @doc """
  Remove a domain from a SAML configuration.
  """
  @spec remove_domain(Domain.t()) :: {:ok, Domain.t()} | {:error, Ecto.Changeset.t()}
  def remove_domain(%Domain{} = domain) do
    Repo.delete(domain)
  end

  @doc """
  Get all domains for a SAML configuration.
  """
  @spec get_domains(Integration.t()) :: [Domain.t()]
  def get_domains(%Integration{id: integration_id}) do
    Repo.all(from d in Domain, where: d.sso_integration_id == ^integration_id)
  end

  @doc """
  Get all domains for a team.
  """
  @spec get_domains_by_team(Team.t() | non_neg_integer()) :: [Domain.t()]
  def get_domains_by_team(%Team{id: team_id}) do
    get_domains_by_team(team_id)
  end

  def get_domains_by_team(team_id) when is_integer(team_id) do
    case get_config(team_id) do
      nil ->
        []

      integration ->
        get_domains(integration)
    end
  end

  @doc """
  Validate SAML configuration attributes.
  Returns :ok if valid, or {:error, errors} if invalid.
  """
  @spec validate_config_attrs(map()) :: :ok | {:error, [{atom(), String.t()}]}
  def validate_config_attrs(attrs) do
    errors = []

    errors =
      if attrs["idp_entity_id"] in [nil, ""] do
        [{:idp_entity_id, "IdP Entity ID is required"} | errors]
      else
        errors
      end

    errors =
      if attrs["idp_sso_url"] in [nil, ""] do
        [{:idp_sso_url, "IdP SSO URL is required"} | errors]
      else
        errors
      end

    errors =
      if attrs["idp_certificate"] in [nil, ""] do
        [{:idp_certificate, "IdP Certificate is required"} | errors]
      else
        errors
      end

    if errors == [] do
      :ok
    else
      {:error, errors}
    end
  end
end
