defmodule Plausible.Auth.SAML.Metadata do
  @moduledoc """
  Builds SAML 2.0 Service Provider (SP) metadata XML.
  """

  alias Plausible.Auth.SAML.Configuration
  alias PlausibleWeb.Endpoint

  @sp_entity_id "plausible"
  @name_id_format "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

  @doc """
  Builds the SP metadata XML document.
  """
  def build(%Configuration{} = _config) do
    base_url = get_base_url()
    entity_id = "#{base_url}/saml/metadata"
    acs_url = "#{base_url}/saml/acs"

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                         entityID="#{entity_id}">
      <md:SPSSODescriptor AuthnRequestsSigned="false"
                          WantAssertionsSigned="true"
                          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:NameIDFormat>#{@name_id_format}</md:NameIDFormat>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                    Location="#{acs_url}"
                                    index="0"
                                    isDefault="true"/>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>
    """
    |> String.trim()
  end

  @doc """
  Returns the SP entity ID.
  """
  def sp_entity_id, do: @sp_entity_id

  @doc """
  Returns the Assertion Consumer Service URL.
  """
  def acs_url do
    "#{get_base_url()}/saml/acs"
  end

  defp get_base_url do
    # Get the base URL from the application config
    Application.get_env(:plausible, PlausibleWeb.Endpoint)[:url][:host]
    |> case do
      nil -> "https://plausible.io"
      _ -> "#{Application.get_env(:plausible, PlausibleWeb.Endpoint)[:url][:scheme]}://#{Application.get_env(:plausible, PlausibleWeb.Endpoint)[:url][:host]}"
    end
  end
end
