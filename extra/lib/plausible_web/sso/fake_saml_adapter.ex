defmodule PlausibleWeb.SSO.FakeSAMLAdapter do
  @moduledoc """
  Fake implementation of SAML authentication interface.
  """

  alias Plausible.Auth
  alias Plausible.Auth.SSO
  alias Plausible.Repo

  alias PlausibleWeb.Router.Helpers, as: Routes

  def signin(conn, params) do
    conn
    |> Phoenix.Controller.put_layout(false)
    |> Phoenix.Controller.render("saml_signin.html",
      integration_id: params["integration_id"],
      email: params["email"],
      return_to: params["return_to"],
      nonce: conn.private[:sso_nonce]
    )
  end

  def consume(conn, params) do
    case SSO.get_integration(params["integration_id"]) do
      {:ok, integration} ->
        session_timeout_minutes = integration.team.policy.sso_session_timeout_minutes

        expires_at =
          NaiveDateTime.add(NaiveDateTime.utc_now(:second), session_timeout_minutes, :minute)

        identity =
          if user = Repo.get_by(Auth.User, email: params["email"]) do
            %SSO.Identity{
              id: user.sso_identity_id || Ecto.UUID.generate(),
              integration_id: integration.identifier,
              name: user.name,
              email: user.email,
              expires_at: expires_at
            }
          else
            %SSO.Identity{
              id: Ecto.UUID.generate(),
              integration_id: integration.identifier,
              name: name_from_email(params["email"]),
              email: params["email"],
              expires_at: expires_at
            }
          end

        "sso_login_success"
        |> Plausible.Audit.Entry.new(identity, %{team_id: integration.team.id})
        |> Plausible.Audit.Entry.include_change(identity)
        |> Plausible.Audit.Entry.persist!()

        PlausibleWeb.UserAuth.log_in_user(conn, identity, params["return_to"])

      {:error, :not_found} ->
        conn
        |> Phoenix.Controller.put_flash(:login_error, "Wrong email.")
        |> Phoenix.Controller.redirect(
          to: Routes.sso_path(conn, :login_form, return_to: params["return_to"])
        )
    end
  end

  defp name_from_email(email) do
    email
    |> String.split("@", parts: 2)
    |> List.first()
    |> String.split(".")
    |> Enum.take(2)
    |> Enum.map_join(" ", &String.capitalize/1)
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

  @doc """
  Tests the SAML integration configuration.
  Validates that the IdP URL and certificate are accessible.
  """
  @spec test_integration(SSO.Integration.t()) :: :ok | {:error, String.t()}
  def test_integration(integration) do
    config = integration.config

    # Check if required fields are present
    if config.idp_signin_url && config.idp_entity_id && config.idp_cert_pem do
      # For fake adapter, we just validate that fields are present
      :ok
    else
      {:error, "Missing required IdP configuration"}
    end
  end

  # ===== Single Logout (SLO) Implementation =====

  @doc """
  Initiates SP-initiated Single Logout.

  In the fake adapter, this just performs local logout.
  """
  @spec slo_initiate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_initiate(conn, %{"integration_id" => _integration_id} = params) do
    return_to = Map.get(params, "return_to", "/")

    # Fake adapter just does local logout
    conn
    |> PlausibleWeb.UserAuth.log_out_user()
    |> Phoenix.Controller.redirect(to: return_to)
  end

  @doc """
  Handles the LogoutResponse from IdP after SP-initiated SLO.
  """
  @spec slo_consume(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_consume(conn, %{"integration_id" => _integration_id} = params) do
    return_to = Map.get(params, "return_to", "/")

    conn
    |> PlausibleWeb.UserAuth.log_out_user()
    |> Phoenix.Controller.redirect(to: return_to)
  end

  @doc """
  Handles IdP-initiated Single Logout (LogoutRequest from IdP).
  """
  @spec slo_request(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def slo_request(conn, %{"integration_id" => _integration_id} = params) do
    # In fake adapter, just do local logout and redirect to /
    return_to = Map.get(params, "RelayState", "/")

    conn
    |> PlausibleWeb.UserAuth.log_out_user()
    |> Phoenix.Controller.redirect(to: return_to)
  end
end
