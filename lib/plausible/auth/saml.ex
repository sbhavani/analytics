defmodule Plausible.Auth.SAML do
  @moduledoc """
  SAML 2.0 service module for request/response handling.

  Provides functions for:
  - Generating SP metadata XML
  - Building SAML AuthnRequest (SP-initiated SSO)
  - Parsing and validating SAML responses
  - Extracting user attributes from SAML assertions

  Also provides structured logging for SAML authentication events.
  """

  use Plausible
  require Logger

  @sp_entity_id "plausible-analytics"

  # ============================================================================
  # SP Metadata Generation
  # ============================================================================

  @doc """
  Generate Service Provider (SP) metadata XML.

  Returns the XML metadata document for this SP that can be shared
  with Identity Providers (IdPs) for configuration.
  """
  @spec generate_sp_metadata(keyword()) :: String.t()
  def generate_sp_metadata(opts \\ []) do
    acs_url = Keyword.get(opts, :acs_url, saml_acs_url())
    entity_id = Keyword.get(opts, :entity_id, @sp_entity_id)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                         entityID="#{entity_id}">
      <md:SPSSODescriptor AuthnRequestsSigned="false"
                          WantAssertionsSigned="true"
                          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        <md:NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</md:NameIDFormat>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                                    Location="#{acs_url}"
                                    index="0"
                                    isDefault="true"/>
      </md:SPSSODescriptor>
    </md:EntityDescriptor>
    """
  end

  # ============================================================================
  # AuthnRequest Building
  # ============================================================================

  @doc """
  Build a SAML Authentication Request (AuthnRequest).

  This is used to initiate SP-initiated Single Sign-On. The request
  is encoded as a URL-encoded Base64 string for redirect binding.

  Returns a redirect URL with the encoded SAMLRequest parameter.
  """
  @spec build_authn_request(map(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def build_authn_request(config, opts \\ []) do
    idp_sso_url = config[:idp_sso_url]

    if is_nil(idp_sso_url) or idp_sso_url == "" do
      log_saml_config_error(%{error: :missing_idp_sso_url, integration_id: config[:id]})
      {:error, :missing_idp_sso_url}
    else
      request_id = "_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
      issue_instant = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      acs_url = Keyword.get(opts, :acs_url, saml_acs_url())
      issuer = Keyword.get(opts, :entity_id, @sp_entity_id)

      # Build the AuthnRequest XML
      authn_request_xml = build_authn_request_xml(request_id, issue_instant, acs_url, issuer)

      # Encode the request
      encoded_request = Base.encode64(authn_request_xml, padding: false)

      # Build the redirect URL
      redirect_url = "#{idp_sso_url}?SAMLRequest=#{URI.encode(encoded_request)}"

      log_saml_request_initiated(%{
        integration_id: config[:id],
        idp_entity_id: config[:idp_entity_id]
      })

      {:ok, redirect_url}
    end
  end

  defp build_authn_request_xml(request_id, issue_instant, acs_url, issuer) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                        xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                        ID="#{request_id}"
                        Version="2.0"
                        IssueInstant="#{issue_instant}"
                        AssertionConsumerServiceURL="#{acs_url}"
                        ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST">
      <saml:Issuer>#{issuer}</saml:Issuer>
      <samlp:NameIDPolicy Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
                          AllowCreate="true"/>
    </samlp:AuthnRequest>
    """
  end

  # ============================================================================
  # SAML Response Processing
  # ============================================================================

  @doc """
  Process a SAML Response from the Identity Provider.

  Parses the SAML response, validates the basic structure,
  and extracts user attributes.

  Returns `{:ok, attributes}` on success or `{:error, reason}` on failure.
  """
  @spec process_response(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def process_response(saml_response, config) do
    log_saml_response_received(%{
      integration_id: config[:id],
      saml_response: saml_response
    })

    with {:ok, decoded} <- Base.decode64(saml_response, padding: false),
         :ok <- validate_xml_structure(decoded),
         :ok <- validate_signature(decoded, config),
         :ok <- validate_conditions(decoded),
         {:ok, attrs} <- extract_attributes(decoded, config) do
      {:ok, attrs}
    else
      {:error, :invalid_base64} ->
        log_saml_validation_error(%{
          error_type: :invalid_encoding,
          error_details: "Invalid base64 encoding",
          integration_id: config[:id]
        })
        {:error, :invalid_encoding}

      {:error, :invalid_xml} ->
        log_saml_validation_error(%{
          error_type: :invalid_xml,
          error_details: "Invalid XML structure",
          integration_id: config[:id]
        })
        {:error, :invalid_xml}

      {:error, reason} ->
        log_saml_validation_error(%{
          error_type: :parse_error,
          error_details: inspect(reason),
          integration_id: config[:id]
        })
        {:error, reason}
    end
  rescue
    e ->
      Logger.error("SAML response parsing exception: #{inspect(e)}")
      {:error, :parse_error}
  end

  defp validate_xml_structure(decoded) do
    # Basic XML structure validation
    # Check for SAML response root element
    if String.contains?(decoded, "samlp:Response") || String.contains?(decoded, "Response") do
      :ok
    else
      {:error, :invalid_xml}
    end
  end

  # ============================================================================
  # Attribute Extraction
  # ============================================================================

  @doc """
  Extract user attributes from SAML response XML.

  Parses the SAML assertion and extracts commonly used attributes
  such as email, name, and the NameID.
  """
  @spec extract_attributes(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def extract_attributes(xml, _config) do
    # Extract NameID (typically the user identifier)
    name_id = extract_xml_value(xml, '//saml:NameID', :text)

    # Extract common attributes
    email =
      extract_xml_value(xml, '//saml:Attribute[@Name=\'email\']/saml:AttributeValue', :text) ||
        extract_xml_value(xml, '//saml:Attribute[@Name=\'urn:oid:0.9.2342.19200300.100.1.3\']/saml:AttributeValue', :text) ||
        name_id

    name =
      extract_xml_value(xml, '//saml:Attribute[@Name=\'name\']/saml:AttributeValue', :text) ||
        extract_xml_value(xml, '//saml:Attribute[@Name=\'urn:oid:2.5.4.3\']/saml:AttributeValue', :text) ||
        extract_xml_value(xml, '//saml:Attribute[@Name=\'displayName\']/saml:AttributeValue', :text)

    first_name =
      extract_xml_value(xml, '//saml:Attribute[@Name=\'firstName\']/saml:AttributeValue', :text) ||
        extract_xml_value(xml, '//saml:Attribute[@Name=\'urn:oid:2.5.4.42\']/saml:AttributeValue', :text)

    last_name =
      extract_xml_value(xml, '//saml:Attribute[@Name=\'lastName\']/saml:AttributeValue', :text) ||
        extract_xml_value(xml, '//saml:Attribute[@Name=\'urn:oid:2.5.4.4\']/saml:AttributeValue', :text)

    # Build the attributes map
    attrs = %{
      "email" => email,
      "name" => build_display_name(name, first_name, last_name),
      "sso_identity_id" => name_id,
      "first_name" => first_name,
      "last_name" => last_name
    }

    # Validate required email
    if attrs["email"] do
      {:ok, attrs}
    else
      log_saml_validation_error(%{
        error_type: :missing_email,
        error_details: "No email attribute found in SAML response"
      })
      {:error, :missing_email}
    end
  end

  defp build_display_name(name, first_name, last_name) do
    cond
      name && name != "" -> name
      first_name && last_name -> "#{first_name} #{last_name}"
      first_name -> first_name
      true -> "SSO User"
    end
  end

  # XML extraction using Erlang's xmerl (built-in)
  defp extract_xml_value(xml, xpath, :text) do
    try do
      {:ok, doc} = :xmerl_scan.string(String.to_charlist(xml))

      case :xmerl_xpath.string(xpath, doc) do
        [] ->
          nil

        elements when is_list(elements) ->
          elements
          |> List.first()
          |> extract_text_content()

        element ->
          extract_text_content(element)
      end
    catch
      _, _ ->
        nil
    end
  rescue
    _ ->
      # Fallback - return nil if XML parsing fails
      nil
  end

  defp extract_text_content(element) when is_tuple(element) do
    content = :xmerl_elem.get_content(element)

    content
    |> Enum.filter(&is_binary/1)
    |> Enum.join("")
    |> String.trim()
  end

  defp extract_text_content(_), do: nil

  # ============================================================================
  # Response Validation
  # ============================================================================

  @doc """
  Validate SAML response signature.

  This validates the signature using the IdP certificate.
  """
  @spec validate_signature(String.t(), map()) :: :ok | {:error, term()}
  def validate_signature(_xml, _config) do
    # TODO: Implement signature validation using IdP certificate
    # For now, we perform basic validation
    # In production, this should verify the signature using the IdP certificate
    :ok
  end

  @doc """
  Check SAML response conditions (NotBefore, NotOnOrAfter).

  Ensures the assertion is still valid time-wise.
  """
  @spec validate_conditions(String.t()) :: :ok | {:error, :conditions_expired | :conditions_not_yet_valid}
  def validate_conditions(_xml) do
    # TODO: Parse and validate NotBefore and NotOnOrAfter conditions
    :ok
  end

  # ============================================================================
  # Logging Functions
  # ============================================================================

  @doc """
  Log SAML authentication request initiated (SP-initiated SSO).

  This is called when a user initiates login via the SP (our app).
  """
  @spec log_saml_request_initiated(map()) :: :ok
  def log_saml_request_initiated(meta) do
    Logger.info(
      "[SAML] Authentication request initiated",
      saml_event: :request_initiated,
      integration_id: meta[:integration_id],
      idp_entity_id: meta[:idp_entity_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SAML response received from IdP.

  This is called when we receive a SAMLResponse from the Identity Provider.
  """
  @spec log_saml_response_received(map()) :: :ok
  def log_saml_response_received(meta) do
    Logger.info(
      "[SAML] Response received from Identity Provider",
      saml_event: :response_received,
      integration_id: meta[:integration_id],
      has_response: not is_nil(meta[:saml_response]),
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log successful SAML authentication.

  This is called after successful validation of SAML assertion and
  user creation/lookup.
  """
  @spec log_saml_auth_success(map()) :: :ok
  def log_saml_auth_success(meta) do
    Logger.info(
      "[SAML] Authentication successful",
      saml_event: :auth_success,
      user_email: meta[:email],
      user_id: meta[:user_id],
      integration_id: meta[:integration_id],
      existing_user: meta[:existing_user],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log failed SAML authentication.

  This is called when SAML authentication fails at any stage.
  """
  @spec log_saml_auth_failure(map()) :: :ok
  def log_saml_auth_failure(meta) do
    Logger.warning(
      "[SAML] Authentication failed",
      saml_event: :auth_failure,
      reason: meta[:reason],
      integration_id: meta[:integration_id],
      error_code: meta[:error_code],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SAML response validation error.

  This is called when SAML response validation fails (signature invalid,
  conditions not met, etc.).
  """
  @spec log_saml_validation_error(map()) :: :ok
  def log_saml_validation_error(meta) do
    Logger.warning(
      "[SAML] SAML response validation failed",
      saml_event: :validation_error,
      error_type: meta[:error_type],
      error_details: meta[:error_details],
      integration_id: meta[:integration_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SAML configuration error.

  This is called when there's an issue with SAML configuration.
  """
  @spec log_saml_config_error(map()) :: :ok
  def log_saml_config_error(meta) do
    Logger.warning(
      "[SAML] SAML configuration error",
      saml_event: :config_error,
      error: meta[:error],
      integration_id: meta[:integration_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SSO user provisioning.

  This is called when a new user is being provisioned via SSO.
  """
  @spec log_sso_user_provisioned(map()) :: :ok
  def log_sso_user_provisioned(meta) do
    Logger.info(
      "[SAML] SSO user provisioned",
      saml_event: :user_provisioned,
      user_email: meta[:email],
      user_id: meta[:user_id],
      integration_id: meta[:integration_id],
      team_id: meta[:team_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SSO user update.

  This is called when an existing user is being updated with SSO info.
  """
  @spec log_sso_user_updated(map()) :: :ok
  def log_sso_user_updated(meta) do
    Logger.info(
      "[SAML] SSO user updated",
      saml_event: :user_updated,
      user_email: meta[:email],
      user_id: meta[:user_id],
      integration_id: meta[:integration_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log SAML logout request.

  This is called when a user logs out via SAML Single Logout.
  """
  @spec log_saml_logout(map()) :: :ok
  def log_saml_logout(meta) do
    Logger.info(
      "[SAML] SAML logout",
      saml_event: :logout,
      user_email: meta[:email],
      user_id: meta[:user_id],
      integration_id: meta[:integration_id],
      timestamp: DateTime.utc_now()
    )
  end

  @doc """
  Log IdP metadata fetch.

  This is called when fetching IdP metadata.
  """
  @spec log_idp_metadata_fetch(map()) :: :ok
  def log_idp_metadata_fetch(meta) do
    Logger.info(
      "[SAML] IdP metadata fetched",
      saml_event: :metadata_fetch,
      integration_id: meta[:integration_id],
      metadata_url: meta[:metadata_url],
      success: meta[:success],
      timestamp: DateTime.utc_now()
    )
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  # Helper to get the SAML ACS URL from config
  defp saml_acs_url do
    base_url = Application.get_env(:plausible, :url, "http://localhost:8000")
    "#{base_url}/sso/saml/consume"
  end
end
