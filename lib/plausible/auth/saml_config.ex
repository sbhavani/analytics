defmodule Plausible.Auth.SAML.Config do
  @moduledoc """
  SAML Configuration - provides a structured interface for SAML IdP settings.

  This module wraps the existing SSO Integration schema and provides
  SAML-specific helpers and validation for IdP configuration.
  """

  use Plausible
  import Ecto.Changeset

  @type t :: %__MODULE__{
          idp_entity_id: String.t() | nil,
          idp_sso_url: String.t() | nil,
          idp_certificate: String.t() | nil,
          attribute_mapping: map() | nil,
          enabled: boolean()
        }

  @enforce_keys [:idp_entity_id, :idp_sso_url, :idp_certificate]
  defstruct [
    :idp_entity_id,
    :idp_sso_url,
    :idp_certificate,
    :attribute_mapping,
    :enabled
  ]

  @doc """
  Creates a SAML Config struct from a map of attributes.
  """
  def new(attrs) do
    %__MODULE__{
      idp_entity_id: attrs["idp_entity_id"] || attrs[:idp_entity_id],
      idp_sso_url: attrs["idp_sso_url"] || attrs[:idp_sso_url],
      idp_certificate: attrs["idp_certificate"] || attrs[:idp_certificate],
      attribute_mapping: attrs["attribute_mapping"] || attrs[:attribute_mapping] || %{},
      enabled: Map.get(attrs, "enabled", false) || Map.get(attrs, :enabled, false)
    }
  end

  @doc """
  Validates the SAML configuration.
  """
  def validate(%__MODULE__{} = config) do
    errors = []

    errors =
      if config.idp_entity_id in [nil, ""] do
        [{:idp_entity_id, "IdP Entity ID is required"} | errors]
      else
        errors
      end

    errors =
      if config.idp_sso_url in [nil, ""] do
        [{:idp_sso_url, "IdP SSO URL is required"} | errors]
      else
        errors
      end

    errors =
      if config.idp_certificate in [nil, ""] do
        [{:idp_certificate, "IdP Certificate is required"} | errors]
      else
        errors
      end

    errors =
      if config.idp_sso_url && not valid_url?(config.idp_sso_url) do
        [{:idp_sso_url, "IdP SSO URL must be a valid HTTPS URL"} | errors]
      else
        errors
      end

    if errors == [] do
      :ok
    else
      {:error, errors}
    end
  end

  @doc """
  Converts a SAML Config struct to a map suitable for storage in the JSONB config column.
  """
  def to_map(%__MODULE__{} = config) do
    %{
      "idp_entity_id" => config.idp_entity_id,
      "idp_sso_url" => config.idp_sso_url,
      "idp_certificate" => config.idp_certificate,
      "attribute_mapping" => config.attribute_mapping,
      "enabled" => config.enabled
    }
  end

  @doc """
  Extracts SAML configuration from an SSO Integration's config JSONB column.
  """
  def from_integration_config(config) when is_map(config) do
    new(config)
  end

  @doc """
  Returns the attribute mapping with defaults applied.
  """
  def default_attribute_mapping do
    %{
      "email" => "email",
      "name" => "name",
      "id" => "id"
    }
  end

  @doc """
  Extracts the user email from SAML assertion attributes using the configured mapping.
  """
  def extract_email(attrs, %__MODULE__{} = config) do
    mapping = config.attribute_mapping || default_attribute_mapping()
    email_attr = Map.get(mapping, "email", "email")
    Map.get(attrs, email_attr)
  end

  @doc """
  Extracts the user name from SAML assertion attributes using the configured mapping.
  """
  def extract_name(attrs, %__MODULE__{} = config) do
    mapping = config.attribute_mapping || default_attribute_mapping()
    name_attr = Map.get(mapping, "name", "name")
    Map.get(attrs, name_attr)
  end

  @doc """
  Extracts the user ID from SAML assertion attributes using the configured mapping.
  """
  def extract_user_id(attrs, %__MODULE__{} = config) do
    mapping = config.attribute_mapping || default_attribute_mapping()
    id_attr = Map.get(mapping, "id", "id")
    Map.get(attrs, id_attr)
  end

  defp valid_url?("https://" <> _ = url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when host != "" -> true
      _ -> false
    end
  end

  defp valid_url?(_), do: false
end

defmodule Plausible.Auth.SAML.Config.Changeset do
  @moduledoc """
  Ecto Changeset helpers for SAML Configuration with SSO Integration.
  """

  use Plausible
  import Ecto.Changeset

  alias Plausible.Auth.SSO.Integration
  alias Plausible.Auth.SAML.Config

  @doc """
  Creates a changeset for a SAML Configuration (stored in SSO Integration).
  """
  def create_integration_changeset(team_id, attrs) do
    config = Config.new(attrs)

    Integration.changeset(%Integration{}, %{
      identifier: generate_identifier(),
      config: Config.to_map(config),
      team_id: team_id
    })
  end

  @doc """
  Updates an existing SSO Integration with new SAML configuration.
  """
  def update_integration_changeset(%Integration{} = integration, attrs) do
    config = Config.new(attrs)

    integration
    |> cast(%{config: Config.to_map(config)}, [:config])
    |> validate_config()
  end

  @doc """
  Enables SSO for a team.
  """
  def enable_integration(%Integration{} = integration) do
    current_config = integration.config || %{}
    updated_config = Map.put(current_config, "enabled", true)

    integration
    |> cast(%{config: updated_config}, [:config])
    |> validate_config()
  end

  @doc """
  Disables SSO for a team.
  """
  def disable_integration(%Integration{} = integration) do
    current_config = integration.config || %{}
    updated_config = Map.put(current_config, "enabled", false)

    integration
    |> cast(%{config: updated_config}, [:config])
  end

  @doc """
  Gets the SAML config from an SSO Integration.
  """
  def get_saml_config(%Integration{} = integration) do
    Config.from_integration_config(integration.config || %{})
  end

  defp generate_identifier do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end

  defp validate_config(changeset) do
    config = get_change(changeset, :config) || %{}
    saml_config = Config.new(config)

    case Config.validate(saml_config) do
      :ok ->
        changeset

      {:error, errors} ->
        add_error(changeset, :config, errors)
    end
  end
end
