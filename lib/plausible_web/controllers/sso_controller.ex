defmodule PlausibleWeb.SSOController do
  @moduledoc """
  Controller for SSO authentication including SAML 2.0 endpoints.
  """

  use PlausibleWeb, :controller
  use Plausible.Repo
  use Plausible

  alias Plausible.Auth
  alias Plausible.Auth.SSO
  alias Plausible.Auth.SSOError
  alias PlausibleWeb.UserAuth
  alias PlausibleWeb.TwoFactor

  require Logger

  plug(
    PlausibleWeb.RequireLoggedOutPlug
    when action in [:login_form, :login]
  )

  # SSO Login Form (non-SAML)
  def login_form(conn, _params) do
    render(conn, "login_form.html")
  end

  # SSO Login (non-SAML) - initiates the SSO flow
  def login(conn, %{"email" => email}) do
    # Check if this email domain has SSO enabled
    case get_sso_config_for_email(email) do
      nil ->
        # No SSO - redirect to regular login or show error
        # Use user-friendly error message from SSOError module
        SSOError.error_tuple(:missing_idp_config, %{email: email})
        conn
        |> put_flash(:error, SSOError.user_message(:missing_idp_config))
        |> redirect(to: "/login")

      config ->
        # Initiate SSO flow
        initiate_sso_login(conn, email, config)
    end
  end

  # SAML: SP Metadata endpoint - returns XML metadata for IdP configuration
  def saml_metadata(conn, params) do
    integration_id = Map.get(params, "integration_id")
    metadata = generate_sp_metadata()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, metadata)
  end

  # SAML: SP-initiated SSO - redirect to IdP
  def saml_signin(conn, %{"integration_id" => integration_id}) do
    case get_saml_config(integration_id) do
      nil ->
        SSOError.error_tuple(:missing_idp_config, %{integration_id: integration_id})
        conn
        |> put_flash(:error, SSOError.user_message(:missing_idp_config))
        |> redirect(to: "/login")

      config ->
        # Build SAML AuthnRequest and redirect to IdP
        case build_saml_authn_request(config) do
          {:ok, authn_request} ->
            conn
            |> redirect(external: authn_request)

          {:error, error_type} ->
            SSOError.error_tuple(error_type, %{integration_id: integration_id})
            conn
            |> put_flash(:error, SSOError.user_message(error_type))
            |> redirect(to: "/login")
        end
    end
  end

  # SAML: Assertion Consumer Service - receive response from IdP
  def saml_consume(conn, %{"SAMLResponse" => saml_response, "integration_id" => integration_id}) do
    case get_saml_config(integration_id) do
      nil ->
        SSOError.error_tuple(:missing_idp_config, %{integration_id: integration_id})
        conn
        |> put_flash(:error, SSOError.user_message(:missing_idp_config))
        |> redirect(to: "/login")

      config ->
        case process_saml_response(saml_response, config) do
          {:ok, attrs} ->
            # Validate required attributes
            case validate_saml_attrs(attrs) do
              :ok ->
                # Find or create user and log them in
                case SSO.find_or_create_user_from_saml_attrs(attrs) do
                  {:ok, user} ->
                    UserAuth.log_in(conn, user, %{})

                  {:error, reason} ->
                    # Handle different user creation errors
                    handle_user_creation_error(conn, reason, attrs)
                end

              {:error, error_type} ->
                SSOError.error_tuple(error_type, %{integration_id: integration_id, email: attrs["email"]})
                conn
                |> put_flash(:error, SSOError.user_message(error_type))
                |> redirect(to: "/login")
            end

          {:error, reason} ->
            # Map the error reason to user-friendly message
            error_type = SSOError.standardize_error(reason)
            SSOError.error_tuple(error_type, %{integration_id: integration_id})
            conn
            |> put_flash(:error, SSOError.user_message(error_type))
            |> redirect(to: "/login")
        end
    end
  end

  # CSP Report endpoint (required by SAML)
  def csp_report(conn, _params) do
    conn
    |> send_resp(204, "")
  end

  # SSO Provisioning Notice
  def provision_notice(conn, _params) do
    render(conn, "provision_notice.html")
  end

  # SSO Provisioning Issue
  def provision_issue(conn, %{"issue" => issue}) do
    render(conn, "provision_issue.html", issue: issue)
  end

  # Helper functions

  defp get_sso_config_for_email(email) do
    # Extract domain from email and look up SSO config
    case String.split(email, "@") do
      [_local, domain] ->
        # Query sso_domains table for this domain
        # Return integration config if found
        nil

      _ ->
        nil
    end
  end

  defp initiate_sso_login(conn, email, config) do
    # Redirect to SAML signin with the integration ID
    redirect(conn, to: "/sso/saml/signin/#{config.integration_id}?SAMLRequest=")
  end

  defp get_saml_config(integration_id) do
    # Fetch SAML config from sso_integrations table
    # This is a placeholder - actual implementation would query the database
    nil
  end

  defp generate_sp_metadata(integration_id \\ nil) do
    base_url = PlausibleWeb.Endpoint.url()
    entity_id = "#{base_url}/sso/saml/metadata"

    # Use integration_id if provided, otherwise use placeholder
    integration_path = if integration_id do
      "/sso/saml/consume/#{integration_id}"
    else
      "/sso/saml/consume/:integration_id"
    end

    # Generate SP Metadata XML
    # This includes:
    # - Entity ID
    # - ACS URLs
    # - SLO URLs
    # - Supported NameID formats
    # - Supported SAML versions
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                        entityID="#{entity_id}">
      <md:SPSSODescriptor AuthnRequestsSigned="false"
                         WantAssertionsSigned="true"
                         protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:KeyDescriptor use="signing">
          <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
            <ds:X509Data>
              <ds:X509Certificate></ds:X509Certificate>
            </ds:X509Data>
          </ds:KeyInfo>
        </md:KeyDescriptor>
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
        <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</md:NameIDFormat>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                     Location="#{base_url}#{integration_path}"
                                     index="0"
                                     isDefault="true"/>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
                                     Location="#{base_url}#{integration_path}"
                                     index="1"/>
        <md:SingleLogoutService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                                Location="#{base_url}/sso/saml/logout"
                                ResponseLocation="#{base_url}/sso/saml/logout"/>
        <md:AttributeConsumingService index="0" isDefault="true">
          <md:ServiceName xml:lang="en">Plausible Analytics</md:ServiceName>
          <md:RequestedAttribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
          <md:RequestedAttribute Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"/>
        </md:AttributeConsumingService>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>
    """
  end

  defp build_saml_config(authn_request, config) do
    # Build the redirect URL with the AuthnRequest
    sso_url = config[:idp_sso_url]
    "#{sso_url}?SAMLRequest=#{URI.encode(authn_request)}"
  end

  defp build_saml_authn_request(config) do
    # Build SAML AuthnRequest XML
    # In production, use simple_saml library for proper XML construction
    issuer = "plausible-analytics"

    # Validate required config
    if config[:idp_sso_url] in [nil, ""] do
      {:error, :invalid_idp}
    else
      authn_request = """
      <?xml version="1.0" encoding="UTF-8"?>
      <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                          ID="_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
                          Version="2.0"
                          IssueInstant="#{DateTime.utc_now() |> DateTime.to_iso8601()}"
                          AssertionConsumerServiceURL="#{config[:acs_url]}">
        <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer}</saml:Issuer>
      </samlp:AuthnRequest>
      """

      # Encode and sign the request (simplified - real impl would use proper XML signing)
      encoded = Base.encode64(authn_request)

      # Build redirect URL
      sso_url = config[:idp_sso_url]
      {:ok, "#{sso_url}?SAMLRequest=#{URI.encode(encoded)}"}
    end
  end

  defp process_saml_response(saml_response, config) do
    # Decode and validate SAML response
    # In production, use simple_saml library for proper validation

    with {:ok, decoded} <- Base.decode64(saml_response) do
      # Parse XML and extract attributes
      # Validate signature using IdP certificate
      # Check issuer matches configured entity ID
      # Check not before / not on or after conditions

      attrs = extract_saml_attrs(decoded)
      {:ok, attrs}
    else
      _ -> {:error, :invalid_encoding}
    end
  rescue
    _ -> {:error, :parse_error}
  end

  defp extract_saml_attrs(xml) do
    # Extract user attributes from SAML response
    # This is a simplified version - real implementation would parse XML properly

    # Return a map with expected attributes
    # In production, parse the actual SAML response XML
    %{
      "email" => extract_xml_value(xml, "//saml:Attribute[@Name='email']/saml:AttributeValue"),
      "name" => extract_xml_value(xml, "//saml:Attribute[@Name='name']/saml:AttributeValue") || "SSO User",
      "sso_identity_id" => extract_xml_value(xml, "//saml:NameID")
    }
  end

  defp extract_xml_value(_xml, _xpath) do
    # Simplified - in production use xmerl or similar library
    nil
  end

  # Validate SAML attributes extracted from response
  defp validate_saml_attrs(attrs) do
    # Check for required email attribute
    if attrs["email"] in [nil, ""] do
      {:error, :missing_email}
    else
      :ok
    end
  end

  # Handle errors from user creation/lookup
  defp handle_user_creation_error(conn, reason, attrs) do
    error_type = handle_user_error_reason(reason)
    SSOError.error_tuple(error_type, %{email: attrs["email"]})

    conn
    |> put_flash(:error, SSOError.user_message(error_type))
    |> redirect(to: "/login")
  end

  # Map user creation reasons to error types
  defp handle_user_error_reason(:not_found), do: :user_not_found
  defp handle_user_error_reason(:disabled), do: :user_disabled
  defp handle_user_error_reason(:not_sso), do: :user_not_sso
  defp handle_user_error_reason(_), do: :session_creation_failed
end
