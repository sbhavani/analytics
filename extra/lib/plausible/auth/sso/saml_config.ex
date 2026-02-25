defmodule Plausible.Auth.SSO.SAMLConfig do
  @moduledoc """
  SAML SSO can be configured in two ways - by either providing IdP
  metadata XML or inputting required data one by one.

  If metadata is provided, the parameters are extracted but the
  original metadata is preserved as well. This might be helpful
  when updating configuration in the future to enable some other
  feature like Single Logout without having to re-fetch metadata
  from IdP again.
  """

  use Ecto.Schema

  alias Plausible.Auth.SSO

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @fields [:idp_signin_url, :idp_logout_url, :idp_entity_id, :idp_cert_pem, :idp_metadata]
  @required_fields @fields -- [:idp_metadata, :idp_logout_url]

  @derive {Plausible.Audit.Encoder,
           only: [:id, :idp_signin_url, :idp_logout_url, :idp_entity_id, :idp_cert_pem, :idp_metadata]}

  embedded_schema do
    field :idp_signin_url, :string
    field :idp_logout_url, :string
    field :idp_entity_id, :string
    field :idp_cert_pem, :string
    field :idp_metadata, :string
  end

  @spec configured?(t()) :: boolean()
  def configured?(config) do
    !!(config.idp_signin_url && config.idp_entity_id && config.idp_cert_pem)
  end

  @spec entity_id(SSO.Integration.t()) :: String.t()
  def entity_id(integration) do
    # Use configured entity ID if provided, otherwise generate from base URL
    case Application.get_env(:plausible, :saml_sp_entity_id) do
      nil ->
        PlausibleWeb.Endpoint.url() <> "/sso/" <> integration.identifier

      entity_id when is_binary(entity_id) ->
        # Allow custom entity ID with optional per-integration suffix
        if String.ends_with?(entity_id, "/") do
          entity_id <> integration.identifier
        else
          entity_id <> "/" <> integration.identifier
        end
    end
  end

  @spec acs_url(SSO.Integration.t()) :: String.t()
  def acs_url(integration) do
    # Use configured ACS URL if provided, otherwise generate from base URL
    case Application.get_env(:plausible, :saml_sp_acs_url) do
      nil ->
        PlausibleWeb.Endpoint.url() <> "/sso/" <> integration.identifier <> "/consume"

      acs_url when is_binary(acs_url) ->
        # Allow custom ACS URL with optional per-integration suffix
        if String.ends_with?(acs_url, "/") do
          acs_url <> integration.identifier <> "/consume"
        else
          acs_url <> "/" <> integration.identifier <> "/consume"
        end
    end
  end

  @spec slo_url(SSO.Integration.t()) :: String.t()
  def slo_url(integration) do
    # Use configured SLO URL if provided, otherwise generate from base URL
    case Application.get_env(:plausible, :saml_sp_slo_url) do
      nil ->
        PlausibleWeb.Endpoint.url() <> "/sso/" <> integration.identifier <> "/slo"

      slo_url when is_binary(slo_url) ->
        # Allow custom SLO URL with optional per-integration suffix
        if String.ends_with?(slo_url, "/") do
          slo_url <> integration.identifier <> "/slo"
        else
          slo_url <> "/" <> integration.identifier <> "/slo"
        end
    end
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(struct, params) do
    struct
    |> cast(params, @fields)
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(struct, params) do
    struct
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_url(:idp_signin_url)
    |> validate_url(:idp_logout_url)
    |> validate_pem(:idp_cert_pem)
    |> update_change(:idp_entity_id, &String.trim/1)
  end

  defp validate_url(changeset, field) do
    if url = get_change(changeset, field) do
      case URI.new(url) do
        {:ok, uri} when uri.scheme in ["http", "https"] -> changeset
        _ -> add_error(changeset, field, "invalid URL", validation: :url)
      end
    else
      changeset
    end
  end

  defp validate_pem(changeset, field) do
    if pem = get_change(changeset, field) do
      pem = clean_pem(pem)

      case parse_pem(pem) do
        {:ok, _cert} -> put_change(changeset, field, pem)
        {:error, _} -> add_error(changeset, field, "invalid certificate", validation: :cert_pem)
      end
    else
      changeset
    end
  end

  defp parse_pem(pem) do
    X509.Certificate.from_pem(pem)
  catch
    _, _ -> {:error, :failed_to_parse}
  end

  defp clean_pem(pem) do
    cleaned =
      pem
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")
      |> String.trim()

    # Trying to account for PEM certificates without markers
    if String.starts_with?(cleaned, "-----BEGIN CERTIFICATE-----") do
      cleaned
    else
      "-----BEGIN CERTIFICATE-----\n" <> cleaned <> "\n-----END CERTIFICATE-----"
    end
  end
end
