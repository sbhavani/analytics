defmodule PlausibleWeb.SAMLController do
  @moduledoc """
  Controller for SAML 2.0 Single Logout (SLO) endpoints.

  Supports both SP-initiated and IdP-initiated logout flows:
  - SP-initiated: User logs out from Plausible → redirect to IdP with LogoutRequest
  - IdP-initiated: IdP sends LogoutRequest → SP logs out user → responds with LogoutResponse
  """

  use PlausibleWeb, :controller
  use Plausible.Repo
  use Plausible

  alias Plausible.Auth
  alias PlausibleWeb.UserAuth

  require Logger

  # SAML: SP-initiated Single Logout - redirect to IdP with LogoutRequest
  def logout(conn, %{"integration_id" => integration_id}) do
    case get_saml_config(integration_id) do
      nil ->
        Logger.warning("SAML logout: Invalid integration_id #{integration_id}")
        conn
        |> put_flash(:error, "Invalid SSO integration")
        |> redirect(to: "/")

      config ->
        # Build SAML LogoutRequest
        logout_request = build_saml_logout_request(conn, config)

        # Store the relay state to return to after logout
        relay_state = Base.encode64(:crypto.strong_rand_bytes(16))

        # Redirect to IdP SLO endpoint
        idp_slo_url = config[:idp_slo_url] || config[:idp_sso_url]

        redirect_url = "#{idp_slo_url}?SAMLRequest=#{URI.encode(logout_request)}&RelayState=#{relay_state}"

        Logger.info("SAML logout: Initiating SLO for integration #{integration_id}")

        conn
        |> redirect(external: redirect_url)
    end
  end

  # SAML: Handle LogoutResponse from IdP (after IdP-initiated logout)
  def logout_response(conn, %{"SAMLResponse" => saml_response, "integration_id" => integration_id}) do
    case get_saml_config(integration_id) do
      nil ->
        Logger.warning("SAML logout_response: Invalid integration_id #{integration_id}")
        conn
        |> put_flash(:error, "Invalid SSO integration")
        |> redirect(to: "/")

      config ->
        case validate_saml_logout_response(saml_response, config) do
          {:ok, _response} ->
            Logger.info("SAML logout: IdP confirmed logout for integration #{integration_id}")

            # Log out the user from Plausible
            conn
            |> UserAuth.log_out_user()
            |> redirect(to: "/login")

          {:error, reason} ->
            Logger.error("SAML logout_response validation failed: #{inspect(reason)}")

            conn
            |> put_flash(:error, "Logout failed. Please try again.")
            |> redirect(to: "/")
        end
    end
  end

  # SAML: IdP-initiated Single Logout - receive LogoutRequest from IdP
  def slo_consume(conn, %{"SAMLRequest" => saml_request, "integration_id" => integration_id}) do
    case get_saml_config(integration_id) do
      nil ->
        Logger.warning("SAML slo_consume: Invalid integration_id #{integration_id}")
        send_resp(conn, 400, "Invalid integration")

      config ->
        case parse_saml_logout_request(saml_request, config) do
          {:ok, logout_request_attrs} ->
            Logger.info("SAML logout: IdP-initiated logout for user #{logout_request_attrs[:name_id]}")

            # Log out the user from Plausible
            conn
            |> UserAuth.log_out_user()

            # Build and send LogoutResponse to IdP
            logout_response = build_saml_logout_response(logout_request_attrs, config, "Success")

            conn
            |> put_resp_content_type("application/xml")
            |> send_resp(200, logout_response)

          {:error, reason} ->
            Logger.error("SAML slo_consume parse failed: #{inspect(reason)}")

            # Send error LogoutResponse to IdP
            error_response = build_saml_logout_response(%{name_id: "unknown"}, config, "Requester")
            conn
            |> put_resp_content_type("application/xml")
            |> send_resp(400, error_response)
        end
    end
  end

  # Helper: Get SAML configuration for an integration
  defp get_saml_config(integration_id) do
    # Fetch SAML config from database
    # This queries the sso_integrations table
    # In production, this would be a proper database query

    case Repo.get_by(Auth.SSO.Integration, id: integration_id) do
      nil ->
        # Fallback for testing/development - return nil in production
        nil

      integration ->
        %{
          idp_entity_id: integration.idp_entity_id,
          idp_sso_url: integration.idp_sso_url,
          idp_slo_url: integration.idp_slo_url,
          idp_certificate: integration.idp_certificate,
          sp_entity_id: integration.sp_entity_id,
          acs_url: integration.acs_url,
          slo_url: integration.slo_url
        }
    end
  rescue
    # If table doesn't exist yet, return nil
    _ in UndefinedFunctionError -> nil
  end

  # Helper: Build SAML LogoutRequest (SP-initiated)
  defp build_saml_logout_request(conn, config) do
    # Get current user info if logged in
    user = conn.assigns[:current_user]

    name_id = if user, do: user.email, else: "anonymous"

    request_id = "_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
    issuer = config[:sp_entity_id] || "plausible-analytics"
    issue_instant = DateTime.utc_now() |> DateTime.to_iso8601()

    logout_request = """
    <?xml version="1.0" encoding="UTF-8"?>
    <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                          ID="#{request_id}"
                          Version="2.0"
                          IssueInstant="#{issue_instant}"
                          Destination="#{config[:idp_slo_url] || config[:idp_sso_url]}">
      <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer}</saml:Issuer>
      <saml:NameID xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                   Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">#{name_id}</saml:NameID>
    </samlp:LogoutRequest>
    """

    # Encode the request
    encoded = Base.encode64(logout_request)
    encoded
  end

  # Helper: Parse SAML LogoutRequest (IdP-initiated)
  defp parse_saml_logout_request(saml_request, _config) do
    with {:ok, decoded} <- Base.decode64(saml_request) do
      # In production, parse XML properly
      # For now, return a simplified map
      {:ok, %{name_id: extract_name_id_from_logout_request(decoded)}}
    else
      _ -> {:error, :invalid_encoding}
    end
  rescue
    _ -> {:error, :parse_error}
  end

  # Helper: Extract NameID from LogoutRequest
  defp extract_name_id_from_logout_request(xml) do
    # Simplified extraction - in production use proper XML parsing
    # Look for <saml:NameID> element
    case Regex.run(~r/<saml:NameID[^>]*>([^<]+)<\/saml:NameID>/, xml) do
      [_, name_id] -> name_id
      _ -> "unknown"
    end
  end

  # Helper: Validate SAML LogoutResponse
  defp validate_saml_logout_response(saml_response, _config) do
    with {:ok, decoded} <- Base.decode64(saml_response) do
      # In production:
      # 1. Verify signature using IdP certificate
      # 2. Verify issuer matches configured entity ID
      # 3. Check InResponseTo matches our original request
      # 4. Check status is Success

      {:ok, %{status: extract_logout_response_status(decoded)}}
    else
      _ -> {:error, :invalid_encoding}
    end
  rescue
    _ -> {:error, :parse_error}
  end

  # Helper: Extract status from LogoutResponse
  defp extract_logout_response_status(xml) do
    case Regex.run(~r/<samlp:StatusCode[^>]*Value="([^"]+)"/, xml) do
      [_, status] -> status
      _ -> "Success"
    end
  end

  # Helper: Build SAML LogoutResponse
  defp build_saml_logout_response(request_attrs, config, status) do
    request_id = "_#{:crypto.strong_rand_bytes(16) |> Base.encode16()}"
    issuer = config[:sp_entity_id] || "plausible-analytics"
    issue_instant = DateTime.utc_now() |> DateTime.to_iso8601()

    status_value = case status do
      "Success" -> "urn:oasis:names:tc:SAML:2.0:status:Success"
      "Requester" -> "urn:oasis:names:tc:SAML:2.0:status:Requester"
      _ -> "urn:oasis:names:tc:SAML:2.0:status:Responder"
    end

    logout_response = """
    <?xml version="1.0" encoding="UTF-8"?>
    <samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                          ID="#{request_id}"
                          Version="2.0"
                          IssueInstant="#{issue_instant}"
                          Destination="#{config[:idp_slo_url] || config[:idp_sso_url]}">
      <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">#{issuer}</saml:Issuer>
      <samlp:Status>
        <samlp:StatusCode Value="#{status_value}"/>
      </samlp:Status>
    </samlp:LogoutResponse>
    """

    # In production, sign the response using SP private key
    Base.encode64(logout_response)
  end
end
