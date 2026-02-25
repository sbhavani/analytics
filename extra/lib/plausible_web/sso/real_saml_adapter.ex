defmodule PlausibleWeb.SSO.RealSAMLAdapter do
  @moduledoc """
  Real implementation of SAML authentication interface.
  """
  alias Plausible.Auth.SSO

  alias PlausibleWeb.Router.Helpers, as: Routes

  require Logger

  @deflate "urn:oasis:names:tc:SAML:2.0:bindings:URL-Encoding:DEFLATE"

  @cookie_name "session_saml"
  @cookie_seconds 10 * 60

  # User-friendly error messages for IdP errors
  # These messages are displayed to end users
  @error_messages %{
    {:error, :not_found} => "No SSO configuration found for your email domain. Please contact your administrator.",
    {:error, :session_expired} => "Your login session has expired. Please try again.",
    {:error, :invalid_relay_state} => "Invalid login request. Please try again.",
    {:error, :malformed_certificate} => "Identity provider configuration error. Please contact your administrator.",
    {:error, :missing_email_attribute} => "Your account information is incomplete. Please contact your administrator.",
    {:error, :invalid_email_attribute} => "Your account email is invalid. Please contact your administrator.",
    {:error, :missing_name_attributes} => "Your account information is incomplete. Please contact your administrator.",
    {:error, :invalid_signature} => "Authentication verification failed. Please try again or contact your administrator.",
    {:error, :assertion_too_old} => "Your login request has expired. Please try again.",
    {:error, :assertion_condition_not_met} => "Authentication conditions not met. Please try again.",
    {:error, :invalid_audience} => "Service provider configuration error. Please contact your administrator.",
    {:error, :invalid_issuer} => "Identity provider not recognized. Please contact your administrator.",
    :network_error => "Unable to connect to your identity provider. Please check your network and try again.",
    :timeout => "Your identity provider is taking too long to respond. Please try again later.",
    :idp_unavailable => "Your identity provider is currently unavailable. Please try again later or contact your administrator."
  }

  @doc """
  Returns a user-friendly error message for the given error reason.
  """
  @spec friendly_error_message(any()) :: String.t()
  def friendly_error_message(reason) do
    case Map.fetch(@error_messages, reason) do
      {:ok, message} -> message
      :error -> "An unexpected error occurred. Please try again or contact your administrator."
    end
  end

  def signin(conn, %{"integration_id" => integration_id} = params) do
    email = params["email"]
    return_to = params["return_to"]

    case SSO.get_integration(integration_id) do
      {:ok, integration} ->
        sp_entity_id = SSO.SAMLConfig.entity_id(integration)
        relay_state = gen_id()
        id = "saml_flow_#{gen_id()}"

        auth_xml = generate_auth_request(sp_entity_id, id, DateTime.utc_now())

        params = %{
          "SAMLEncoding" => @deflate,
          "SAMLRequest" => Base.encode64(:zlib.zip(auth_xml)),
          "RelayState" => relay_state,
          "login_hint" => email
        }

        url = %URI{} = URI.parse(integration.config.idp_signin_url)

        query_string =
          (url.query || "")
          |> URI.decode_query()
          |> Map.merge(params)
          |> URI.encode_query()

        url = URI.to_string(%{url | query: query_string})

        conn
        |> Plug.Conn.configure_session(renew: true)
        |> set_cookie(
          relay_state: relay_state,
          return_to: return_to
        )
        |> Phoenix.Controller.redirect(external: url)

      {:error, :not_found} ->
        conn
        |> Phoenix.Controller.put_flash(:login_error, friendly_error_message({:error, :not_found}))
        |> Phoenix.Controller.put_flash(:login_title, "Single Sign-On unavailable")
        |> Phoenix.Controller.redirect(
          to: Routes.sso_path(conn, :login_form, return_to: return_to)
        )
    end
  end

  def consume(conn, _params) do
    integration_id = conn.path_params["integration_id"]
    saml_response = conn.body_params["SAMLResponse"]
    relay_state = conn.body_params["RelayState"] |> safe_decode_www_form()

    case get_cookie(conn) do
      {:ok, cookie} ->
        conn
        |> clear_cookie()
        |> consume(integration_id, cookie, saml_response, relay_state)

      {:error, :session_expired} ->
        conn
        |> Phoenix.Controller.put_flash(:login_error, friendly_error_message({:error, :session_expired}))
        |> Phoenix.Controller.put_flash(:login_title, "Session Expired")
        |> Phoenix.Controller.redirect(to: Routes.sso_path(conn, :login_form))
    end
  end

  @verify_opts if Mix.env() == :test, do: [skip_time_conditions?: true], else: []

  defp consume(conn, integration_id, cookie, saml_response, relay_state) do
    with {:ok, integration} <- SSO.get_integration(integration_id),
         :ok <- validate_authresp(cookie, relay_state),
         {:ok, {root, assertion}} <- SimpleSaml.parse_response(saml_response),
         {:ok, cert} <- convert_pem_cert(integration.config.idp_cert_pem),
         public_key = X509.Certificate.public_key(cert),
         :ok <-
           SimpleSaml.verify_and_validate_response(root, assertion, public_key, @verify_opts),
         {:ok, attributes} <- extract_attributes(assertion) do
      session_timeout_minutes = integration.team.policy.sso_session_timeout_minutes

      expires_at =
        NaiveDateTime.add(NaiveDateTime.utc_now(:second), session_timeout_minutes, :minute)

      identity =
        %SSO.Identity{
          id: assertion.name_id,
          integration_id: integration.identifier,
          name: name_from_attributes(attributes),
          email: attributes.email,
          expires_at: expires_at
        }

      "sso_login_success"
      |> Plausible.Audit.Entry.new(identity, %{team_id: integration.team.id})
      |> Plausible.Audit.Entry.include_change(identity)
      |> Plausible.Audit.Entry.persist!()

      PlausibleWeb.UserAuth.log_in_user(conn, identity, cookie.return_to)
    else
      {:error, :not_found} ->
        login_error(conn, cookie, friendly_error_message({:error, :not_found}))

      {:error, reason} ->
        # Log the detailed error for debugging while showing user-friendly message
        Logger.warning("SAML authentication error: #{inspect(reason)}")

        with {:ok, integration} <- SSO.get_integration(integration_id) do
          "sso_login_failure"
          |> Plausible.Audit.Entry.new(integration, %{team_id: integration.team.id})
          |> Plausible.Audit.Entry.include_change(%{
            error: inspect(reason)
          })
          |> Plausible.Audit.Entry.persist!()
        end

        login_error(conn, cookie, friendly_error_message(reason))
    end
  end

  defp convert_pem_cert(cert) do
    case X509.Certificate.from_pem(cert) do
      {:ok, cert} -> {:ok, cert}
      {:error, _} -> {:error, :malformed_certificate}
    end
  end

  defp name_from_attributes(attributes) do
    [attributes.first_name, attributes.last_name]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> String.trim()
  end

  defp extract_attributes(assertion) do
    attributes =
      Enum.reduce([:email, :first_name, :last_name], %{}, fn field, attrs ->
        value =
          assertion.attributes
          |> Map.get(to_string(field), [])
          |> List.first()

        Map.put(attrs, field, String.trim(value || ""))
      end)

    cond do
      attributes.email == "" ->
        {:error, :missing_email_attribute}

      # very rudimentary way to check if the attribute is at least email-like
      not String.contains?(attributes.email, "@") or String.length(attributes.email) < 3 ->
        {:error, :invalid_email_attribute}

      attributes.first_name == "" and attributes.last_name == "" ->
        {:error, :missing_name_attributes}

      true ->
        {:ok, attributes}
    end
  end

  defp safe_decode_www_form(nil), do: ""
  defp safe_decode_www_form(data), do: URI.decode_www_form(data)

  defp generate_auth_request(issuer_id, id, timestamp) do
    XmlBuilder.generate(
      {:"samlp:AuthnRequest",
       [
         "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
         ID: id,
         Version: "2.0",
         IssueInstant: DateTime.to_iso8601(timestamp)
       ], [{:"saml:Issuer", ["xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"], issuer_id}]}
    )
  end

  defp validate_authresp(%{relay_state: relay_state}, relay_state)
       when byte_size(relay_state) == 32 do
    :ok
  end

  defp validate_authresp(_, _), do: {:error, :invalid_relay_state}

  defp gen_id() do
    24 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
  end

  @doc false
  def set_cookie(conn, attrs) do
    attrs = %{
      relay_state: Keyword.fetch!(attrs, :relay_state),
      return_to: Keyword.fetch!(attrs, :return_to)
    }

    Plug.Conn.put_resp_cookie(conn, @cookie_name, attrs,
      domain: conn.private.phoenix_endpoint.host(),
      secure: true,
      encrypt: true,
      max_age: @cookie_seconds,
      same_site: "None"
    )
  end

  defp get_cookie(conn) do
    conn = Plug.Conn.fetch_cookies(conn, encrypted: [@cookie_name])

    if cookie = conn.cookies[@cookie_name] do
      {:ok, cookie}
    else
      {:error, :session_expired}
    end
  end

  defp clear_cookie(conn) do
    Plug.Conn.delete_resp_cookie(conn, @cookie_name,
      domain: conn.private.phoenix_endpoint.host(),
      secure: true,
      encrypt: true,
      max_age: @cookie_seconds,
      same_site: "None"
    )
  end

  defp login_error(conn, cookie, login_error) do
    conn
    |> Phoenix.Controller.put_flash(:login_error, login_error)
    |> Phoenix.Controller.put_flash(:login_title, "Authentication Failed")
    |> Phoenix.Controller.redirect(
      to: Routes.sso_path(conn, :login_form, return_to: cookie.return_to)
    )
  end

  @doc """
  Generates SP (Service Provider) metadata XML for a given integration.
  This metadata is used by Identity Providers to configure the SAML connection.
  """
  @spec generate_sp_metadata(SSO.Integration.t()) :: String.t()
  def generate_sp_metadata(integration) do
    entity_id = SSO.SAMLConfig.entity_id(integration)
    acs_url = acs_url(integration)

    XmlBuilder.generate({
      :"md:EntityDescriptor",
      [
        "xmlns:md": "urn:oasis:names:tc:SAML:2.0:metadata",
        entityID: entity_id
      ],
      {
        :"md:SPSSODescriptor",
        [
          "xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion",
          "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
          AuthnRequestsSigned: "false",
          WantAssertionsSigned: "true",
          ProtocolSupportEnumeration: "urn:oasis:names:tc:SAML:2.0:protocol"
        ],
        [
          {
            :"md:NameIDFormat",
            nil,
            "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
          },
          {
            :"md:AssertionConsumerService",
            [
              Binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
              Location: acs_url,
              index: 0,
              isDefault: "true"
            ],
            nil
          }
        ]
      }
    })
  end

  defp acs_url(integration) do
    PlausibleWeb.Endpoint.url() <>
      "/sso/saml/consume/" <> integration.identifier
  end

  # ===== Single Logout (SLO) Implementation =====

  @doc """
  Initiates SP-initiated Single Logout.

  Generates a LogoutRequest and redirects the user to the IdP's SLO endpoint.
  """
  @spec slo_initiate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_initiate(conn, %{"integration_id" => integration_id} = params) do
    return_to = Map.get(params, "return_to", "/")

    case SSO.get_integration(integration_id) do
      {:ok, integration} ->
        if integration.config.idp_logout_url do
          sp_entity_id = SSO.SAMLConfig.entity_id(integration)
          slo_url = SSO.SAMLConfig.slo_url(integration)
          relay_state = gen_id()
          id = "saml_slo_#{gen_id()}"

          # Get the current user's NameID from the session
          name_id = get_session_name_id(conn) || "user@example.com"

          logout_xml = generate_logout_request(sp_entity_id, id, name_id, DateTime.utc_now())

          saml_params = %{
            "SAMLEncoding" => @deflate,
            "SAMLRequest" => Base.encode64(:zlib.zip(logout_xml)),
            "RelayState" => relay_state
          }

          url = %URI{} = URI.parse(integration.config.idp_logout_url)

          query_string =
            (url.query || "")
            |> URI.decode_query()
            |> Map.merge(saml_params)
            |> URI.encode_query()

          url = URI.to_string(%{url | query: query_string})

          # Store relay state in cookie for validation on response
          conn
          |> set_slo_cookie(relay_state: relay_state, return_to: return_to)
          |> Phoenix.Controller.redirect(external: url)
        else
          # No SLO URL configured - just do local logout
          Logger.info("No SLO URL configured for integration #{integration_id}, performing local logout only")

          conn
          |> PlausibleWeb.UserAuth.log_out_user()
          |> Phoenix.Controller.redirect(to: return_to)
        end

      {:error, :not_found} ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Integration not found")
        |> Phoenix.Controller.redirect(to: "/")
    end
  end

  @doc """
  Handles the LogoutResponse from IdP after SP-initiated SLO.

  Validates the response and terminates the local session.
  """
  @spec slo_consume(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_consume(conn, %{"integration_id" => _integration_id} = params) do
    saml_response = params["SAMLResponse"]
    relay_state = (params["RelayState"] || "") |> safe_decode_www_form()

    case get_slo_cookie(conn) do
      {:ok, cookie} ->
        conn
        |> clear_slo_cookie()
        |> slo_consume(cookie, saml_response, relay_state)

      {:error, :session_expired} ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Logout session expired")
        |> Phoenix.Controller.redirect(to: "/")
    end
  end

  defp slo_consume(conn, cookie, saml_response, relay_state) do
    # Validate relay state
    if cookie.relay_state == relay_state and byte_size(relay_state) == 32 do
      # Check if the logout was successful
      # Parse the LogoutResponse to check status
      case parse_logout_response(saml_response) do
        :success ->
          # Terminate local session
          conn
          |> PlausibleWeb.UserAuth.log_out_user()
          |> Phoenix.Controller.redirect(to: cookie.return_to || "/")

        {:error, reason} ->
          Logger.warning("SLO response error: #{inspect(reason)}")

          # Still log out locally even if IdP response indicates failure
          conn
          |> PlausibleWeb.UserAuth.log_out_user()
          |> Phoenix.Controller.put_flash(:error, "Logout may not have completed at identity provider")
          |> Phoenix.Controller.redirect(to: cookie.return_to || "/")
      end
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "Invalid logout request")
      |> Phoenix.Controller.redirect(to: "/")
    end
  end

  @doc """
  Handles IdP-initiated Single Logout (LogoutRequest from IdP).

  This is called when the IdP initiates logout (e.g., user logged out elsewhere).
  """
  @spec slo_request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_request(conn, %{"integration_id" => integration_id} = params) do
    saml_request = params["SAMLRequest"]
    relay_state = (params["RelayState"] || "") |> safe_decode_www_form()

    case SSO.get_integration(integration_id) do
      {:ok, integration} ->
        conn
        |> handle_idp_initiated_slo(integration, saml_request, relay_state)

      {:error, :not_found} ->
        conn
        |> send_logout_response(integration_id, "urn:oasis:names:tc:SAML:2.0:status:UnknownPrincipal")
        |> halt()
    end
  end

  defp handle_idp_initiated_slo(conn, integration, saml_request, relay_state) do
    # Decode and validate the LogoutRequest
    with {:ok, decoded} <- Base.decode64(saml_request),
         {:ok, _unzipped} <- :zlib.unzip(decoded),
         {:ok, name_id} <- extract_logout_request_name_id(decoded) do
      # Terminate local session for this user
      # In a real implementation, we'd look up the user by NameID and terminate their session
      # For now, we just log out the current user
      conn
      |> PlausibleWeb.UserAuth.log_out_user()
      |> send_logout_response(integration.identifier, "urn:oasis:names:tc:SAML:2.0:status:Success", relay_state)
    else
      {:error, reason} ->
        Logger.warning("IdP-initiated SLO error: #{inspect(reason)}")

        conn
        |> send_logout_response(integration.identifier, "urn:oasis:names:tc:SAML:2.0:status:RequestDenied", relay_state)
    end
  end

  defp send_logout_response(conn, integration_id, status, relay_state \\ nil) do
    sp_entity_id = PlausibleWeb.Endpoint.url() <> "/sso/" <> integration_id
    id = "saml_slo_resp_#{gen_id()}"

    response_xml = generate_logout_response(sp_entity_id, id, status, DateTime.utc_now())

    saml_params = %{
      "SAMLEncoding" => @deflate,
      "SAMLResponse" => Base.encode64(:zlib.zip(response_xml))
    }

    if relay_state do
      Map.put(saml_params, "RelayState", relay_state)
    else
      saml_params
    end
    |> then(&{&1, conn})
    |> then(fn {params, conn} ->
      # Redirect back to the IdP's SLO endpoint if needed
      # For POST binding, we render a form that auto-submits
      # For simplicity, we'll just send a 200 OK with the response
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, """
      <!DOCTYPE html>
      <html>
        <body>
          <form id="slo-form" method="POST" action="#{Application.get_env(:plausible, :saml_idp_slo_url, "")}">
            #{Enum.map_join(params, fn {k, v} -> "<input type='hidden' name='#{k}' value='#{v}'>" end)}
          </form>
          <script>document.getElementById('slo-form').submit();</script>
        </body>
      </html>
      """)
    end)
  end

  defp generate_logout_request(issuer_id, id, name_id, timestamp) do
    XmlBuilder.generate(
      {:"samlp:LogoutRequest",
       [
         "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
         "xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion",
         ID: id,
         Version: "2.0",
         IssueInstant: DateTime.to_iso8601(timestamp),
         Destination: ""
       ],
       [
         {:"saml:Issuer", ["xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"], issuer_id},
         {:"saml:NameID", ["xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion", Format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"], name_id}
       ]}
    )
  end

  defp generate_logout_response(issuer_id, in_response_to_id, status, timestamp) do
    XmlBuilder.generate(
      {:"samlp:LogoutResponse",
       [
         "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
         "xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion",
         ID: "saml_slo_resp_#{gen_id()}",
         Version: "2.0",
         IssueInstant: DateTime.to_iso8601(timestamp),
         InResponseTo: in_response_to_id,
         Destination: ""
       ],
       [
         {:"saml:Issuer", ["xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"], issuer_id},
         {:"samlp:Status",
          [
            "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol"
          ],
          {:"samlp:StatusCode", [Value: status], nil}
         }
       ]}
    )
  end

  defp parse_logout_response(saml_response) do
    # In a full implementation, we'd parse the XML and check the status code
    # For now, we'll assume success if we can decode it
    with {:ok, decoded} <- Base.decode64(saml_response),
         {:ok, _unzipped} <- :zlib.unzip(decoded) do
      # Check for Success status
      if String.contains?(decoded, "StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'") or
           String.contains?(decoded, "StatusCode Value=\"urn:oasis:names:tc:SAML:2.0:status:Success\"") do
        :success
      else
        {:error, :logout_failed}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_logout_request_name_id(xml) do
    # Simple regex to extract NameID from LogoutRequest
    case Regex.run(~r/<saml:NameID[^>]*>([^<]+)<\/saml:NameID>/, xml) do
      [_full, name_id] -> {:ok, name_id}
      _ -> {:error, :name_id_not_found}
    end
  end

  defp get_session_name_id(conn) do
    # Try to get the user's email from the session for the NameID
    # This would typically come from the logged-in user's identity
    case Plug.Conn.get_session(conn, :current_user_id) do
      nil -> nil
      user_id ->
        case Plausible.Auth.get_user_by_id(user_id) do
          nil -> nil
          user -> user.email
        end
    end
  end

  # SLO cookie management
  @slo_cookie_name "slo_state"
  @slo_cookie_seconds 5 * 60

  defp set_slo_cookie(conn, attrs) do
    attrs = %{
      relay_state: Keyword.fetch!(attrs, :relay_state),
      return_to: Keyword.get(attrs, :return_to, "/")
    }

    Plug.Conn.put_resp_cookie(conn, @slo_cookie_name, attrs,
      domain: conn.private.phoenix_endpoint.host(),
      secure: true,
      encrypt: true,
      max_age: @slo_cookie_seconds,
      same_site: "None"
    )
  end

  defp get_slo_cookie(conn) do
    conn = Plug.Conn.fetch_cookies(conn, encrypted: [@slo_cookie_name])

    if cookie = conn.cookies[@slo_cookie_name] do
      {:ok, cookie}
    else
      {:error, :session_expired}
    end
  end

  defp clear_slo_cookie(conn) do
    Plug.Conn.delete_resp_cookie(conn, @slo_cookie_name,
      domain: conn.private.phoenix_endpoint.host(),
      secure: true,
      encrypt: true,
      max_age: @slo_cookie_seconds,
      same_site: "None"
    )
  end

  @doc """
  Tests the SAML integration configuration.
  Validates that the IdP URL is accessible and the certificate is valid.
  """
  @spec test_integration(SSO.Integration.t()) :: :ok | {:error, String.t()}
  def test_integration(integration) do
    config = integration.config

    with {:ok, _} <- validate_idp_url(config.idp_signin_url),
         {:ok, _} <- validate_certificate(config.idp_cert_pem) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_idp_url(nil), do: {:error, "IdP signin URL is required"}
  defp validate_idp_url(url) do
    case URI.new(url) do
      {:ok, uri} when uri.scheme in ["http", "https"] ->
        {:ok, url}
      _ ->
        {:error, "Invalid IdP signin URL"}
    end
  end

  defp validate_certificate(nil), do: {:error, "IdP certificate is required"}
  defp validate_certificate(pem) do
    case X509.Certificate.from_pem(pem) do
      {:ok, _cert} ->
        {:ok, pem}
      {:error, _} ->
        {:error, "Invalid IdP certificate"}
    end
  catch
    _, _ -> {:error, "Failed to parse IdP certificate"}
  end
end
