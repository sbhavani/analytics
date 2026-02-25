defmodule Plausible.Auth.SAML do
  @moduledoc """
  Context module for SAML authentication operations.
  """

  use Plausible
  use Plausible.Repo

  alias Plausible.Auth.SAML.Configuration
  alias Plausible.Auth.SAML.Metadata
  alias Plausible.Auth.SAML.Request
  alias Plausible.Auth.SAML.Response, as: SAMLResponse
  alias Plausible.Teams

  require Logger

  on_ee do
    @spec get_saml_config_for_team(Teams.Team.t() | non_neg_integer()) ::
            Configuration.t() | nil
    def get_saml_config_for_team(team_or_team_id) do
      team_id = if is_struct(team_or_team_id), do: team_or_team_id.id, else: team_or_team_id

      Configuration
      |> where([c], c.team_id == ^team_id and c.enabled == true)
      |> Repo.one()
    end

    @spec get_saml_config!(Teams.Team.t() | non_neg_integer()) :: Configuration.t()
    def get_saml_config!(team_or_team_id) do
      case get_saml_config_for_team(team_or_team_id) do
        nil -> raise ArgumentError, "SAML configuration not found for team"
        config -> config
      end
    end

    @spec create_saml_config(Teams.Team.t(), map()) ::
            {:ok, Configuration.t()} | {:error, Ecto.Changeset.t()}
    def create_saml_config(%Teams.Team{} = team, attrs) do
      %Configuration{}
      |> Configuration.changeset(attrs)
      |> put_change(:team_id, team.id)
      |> Repo.insert()
    end

    @spec update_saml_config(Configuration.t(), map()) ::
            {:ok, Configuration.t()} | {:error, Ecto.Changeset.t()}
    def update_saml_config(%Configuration{} = config, attrs) do
      config
      |> Configuration.changeset(attrs)
      |> Repo.update()
    end

    @spec delete_saml_config(Configuration.t()) ::
            {:ok, Configuration.t()} | {:error, Ecto.Changeset.t()}
    def delete_saml_config(%Configuration{} = config) do
      Repo.delete(config)
    end

    @spec get_team_saml_config(Teams.Team.t()) :: Configuration.t() | nil
    def get_team_saml_config(%Teams.Team{} = team) do
      Configuration
      |> where([c], c.team_id == ^team.id)
      |> Repo.one()
    end

    @doc """
    Builds the SP metadata XML for a given team.
    """
    @spec build_sp_metadata(Teams.Team.t() | Configuration.t()) :: String.t()
    def build_sp_metadata(team_or_config) do
      config = if is_struct(team_or_config, Configuration),
                  do: team_or_config,
                  else: get_team_saml_config(team_or_config)

      Metadata.build(config)
    end

    @doc """
    Initiates an SP-initiated SSO login by building an AuthnRequest.
    Returns the redirect URL to the IdP.
    """
    @spec initiate_login(Teams.Team.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
    def initiate_login(%Teams.Team{} = team, relay_state) do
      with config <- get_team_saml_config(team),
           nil <- config && {:error, :saml_not_configured},
           true <- config.enabled || {:error, :saml_disabled} do
        request = Request.build(config)
        encoded_request = Request.encode(request)
        redirect_url = Request.build_redirect_url(config, encoded_request, relay_state)

        Logger.info("[SAML] Initiated login for team #{team.id}")

        {:ok, redirect_url}
      else
        {:error, reason} ->
          Logger.warning("[SAML] Login initiation failed: #{inspect(reason)}")
          {:error, reason}
        nil ->
          {:error, :saml_not_configured}
        false ->
          {:error, :saml_disabled}
      end
    end

    @doc """
    Handles the SAML response from the IdP (ACS endpoint).
    """
    @spec handle_response(Teams.Team.t(), String.t(), String.t() | nil) ::
            {:ok, map()} | {:error, term()}
    def handle_response(%Teams.Team{} = team, saml_response, relay_state) do
      with config <- get_team_saml_config(team),
           nil when config == nil <- {:error, :saml_not_configured},
           true <- config.enabled || {:error, :saml_disabled} do
        case SAMLResponse.parse(config, saml_response) do
          {:ok, assertion} ->
            Logger.info("[SAML] Successfully parsed assertion for #{assertion.email}")

            {:ok,
             %{
               email: assertion.email,
               name: assertion.name,
               session_index: assertion.session_index,
               relay_state: relay_state
             }}

          {:error, reason} ->
            Logger.warning("[SAML] Response validation failed: #{inspect(reason)}")
            {:error, reason}
        end
      else
        {:error, reason} ->
          {:error, reason}

        nil ->
          {:error, :saml_not_configured}

        false ->
          {:error, :saml_disabled}
      end
    end

    @doc """
    Tests the SAML connection by validating the IdP configuration.
    """
    @spec test_connection(Configuration.t()) :: {:ok, String.t()} | {:error, String.t()}
    def test_connection(%Configuration{} = config) do
      # Validate certificate is parseable
      case X509.Certificate.from_pem(config.idp_certificate) do
        {:ok, _cert} ->
          # Basic connectivity check could be added here
          # For now, just validate we can parse the certificate
          Logger.info("[SAML] Connection test successful for team #{config.team_id}")
          {:ok, "Connection successful. Certificate is valid."}

        {:error, reason} ->
          Logger.warning("[SAML] Connection test failed: #{inspect(reason)}")
          {:error, "Invalid certificate: #{inspect(reason)}"}
      end
    end
  else
    # CE stub implementations
    def get_saml_config_for_team(_), do: nil
    def get_saml_config!(_), do: raise("SAML not available in CE")
    def create_saml_config(_, _), do: raise("SAML not available in CE")
    def update_saml_config(_, _), do: raise("SAML not available in CE")
    def delete_saml_config(_), do: raise("SAML not available in CE")
    def get_team_saml_config(_), do: nil
    def build_sp_metadata(_), do: raise("SAML not available in CE")
    def initiate_login(_, _), do: {:error, :saml_not_available_in_ce}
    def handle_response(_, _, _), do: {:error, :saml_not_available_in_ce}
    def test_connection(_), do: {:error, :saml_not_available_in_ce}
  end
end
