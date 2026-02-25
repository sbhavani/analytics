defmodule Plausible.Auth.SAML.Request do
  @moduledoc """
  Builds and encodes SAML 2.0 AuthnRequest.
  """

  alias Plausible.Auth.SAML.Configuration
  alias Plausible.Auth.SAML.Metadata

  @doc """
  Builds a SAML AuthnRequest.
  """
  def build(%Configuration{} = config) do
    request_id = "_#{:crypto.rand_uniform(1_000_000_000, 9_999_999_999)}"
    issue_instant = :os.system_time(:second)

    %{
      id: request_id,
      version: "2.0",
      issue_instant: issue_instant,
      assertion_consumer_service_url: Metadata.acs_url(),
      issuer: Metadata.sp_entity_id(),
      destination: config.idp_sso_url,
      name_id_policy: %{
        format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        allow_create: "true"
      },
      force_authn: "false",
      passive: "false"
    }
  end

  @doc """
  Encodes an AuthnRequest to a URL-encoded string for HTTP Redirect binding.
  """
  def encode(%{} = request) do
    authn_request_xml = to_xml(request)

    # Deflate and base64 encode
    compressed =
      :zlib.compress(authn_request_xml)
      |> Base.encode64()

    # URL encode
    URI.encode_query(%{SAMLRequest: compressed})
  end

  @doc """
  Builds a redirect URL to the IdP with the AuthnRequest.
  """
  def build_redirect_url(%Configuration{} = config, encoded_request, relay_state) do
    base_url = config.idp_sso_url

    query_string = encoded_request

    query_string =
      if relay_state do
        "#{query_string}&RelayState=#{URI.encode(relay_state)}"
      else
        query_string
      end

    "#{base_url}?#{query_string}"
  end

  defp to_xml(request) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                       ID="#{request.id}"
                       Version="#{request.version}"
                       IssueInstant="#{format_time(request.issue_instant)}"
                       AssertionConsumerServiceURL="#{request.assertion_consumer_service_url}"
                       Destination="#{request.destination}"
                       ForceAuthn="#{request.force_authn}"
                       IsPassive="#{request.passive}">
      <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{request.issuer}</saml:Issuer>
      <samlp:NameIDPolicy Format="#{request.name_id_policy.format}"
                          AllowCreate="#{request.name_id_policy.allow_create}"/>
    </samlp:AuthnRequest>
    """
  end

  defp format_time(seconds) do
    seconds
    |> DateTime.from_unix!()
    |> DateTime.to_iso8601()
  end
end
