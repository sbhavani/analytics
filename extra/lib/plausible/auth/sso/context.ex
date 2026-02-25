defmodule Plausible.Auth.SSO.Context do
  @moduledoc """
  SSO Context module - provides identity management and attribute mapping
  for SAML authentication flows.
  """

  alias Plausible.Auth
  alias Plausible.Auth.SSO
  alias Plausible.Auth.SSO.Identity

  @type attribute_map() :: %{
          optional(:email) => String.t(),
          optional(:name) => String.t(),
          optional(:id) => String.t()
        }

  @doc """
  Creates an SSO.Identity struct from SAML attributes.

  ## Parameters
    - attributes: Map containing email, name, and id from SAML assertion
    - integration_id: The SSO integration identifier
    - expires_at: NaiveDateTime when the identity session expires

  ## Returns
    %SSO.Identity{}
  """
  @spec create_identity(attribute_map(), String.t(), NaiveDateTime.t()) :: Identity.t()
  def create_identity(attributes, integration_id, expires_at) do
    %Identity{
      id: Map.get(attributes, :id, ""),
      integration_id: integration_id,
      name: Map.get(attributes, :name),
      email: Map.get(attributes, :email),
      expires_at: expires_at
    }
  end

  @doc """
  Maps SAML attributes to user-friendly format.
  Handles common SAML attribute names.
  """
  @spec map_attributes(map()) :: attribute_map()
  def map_attributes(saml_attributes) do
    # Common SAML attribute names for email
    email =
      get_first_value(saml_attributes, [
        "email",
        "Email",
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
        "urn:oid:0.9.2342.19200300.100.1.3"
      ])

    # Common SAML attribute names for name
    name =
      get_first_value(saml_attributes, [
        "name",
        "displayName",
        "displayname",
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name",
        "urn:oid:2.16.840.1.113730.3.1.241"
      ])

    # Common SAML attribute names for NameID (unique identifier)
    id =
      get_first_value(saml_attributes, [
        "nameID",
        "NameID",
        "subject",
        "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
      ])

    %{
      email: email,
      name: name,
      id: id
    }
    |> Enum.reject(fn {_k, v} -> v == nil or v == "" end)
    |> Map.new()
  end

  @doc """
  Extracts email from SAML attributes, required for user provisioning.
  Returns {:ok, email} or {:error, :missing_email}
  """
  @spec extract_email(attribute_map()) :: {:ok, String.t()} | {:error, :missing_email}
  def extract_email(attributes) do
    case Map.fetch(attributes, :email) do
      {:ok, email} when is_binary(email) and email != "" ->
        {:ok, email}

      _ ->
        {:error, :missing_email}
    end
  end

  @doc """
  Validates that an identity has all required fields for provisioning.
  """
  @spec valid_identity?(Identity.t()) :: boolean()
  def valid_identity?(%Identity{email: email, integration_id: integration_id})
      when is_binary(email) and email != "" and is_binary(integration_id) and integration_id != "",
      do: true

  def valid_identity?(_), do: false

  @doc """
  Gets the first non-empty value from a list of keys in a map.
  """
  @spec get_first_value(map(), [String.t()]) :: String.t() | nil
  def get_first_value(attrs, keys) do
    Enum.find_value(keys, &Map.get(attrs, &1))
  end

  @doc """
  Determines the user type based on existing user and identity.
  Returns :standard, :sso, or :integration.
  """
  @spec determine_user_type(Auth.User.t() | nil, SSO.Integration.t() | nil) ::
          :standard | :sso | :integration
  def determine_user_type(nil, _integration), do: :integration

  def determine_user_type(%{type: type}, _integration) when type == :sso, do: :sso

  def determine_user_type(%{type: :standard}, _integration), do: :standard

  def determine_user_type(_user, _integration), do: :integration
end
