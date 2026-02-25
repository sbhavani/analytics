defmodule PlausibleWeb.SSOController do
  use PlausibleWeb, :controller

  require Logger

  alias Plausible.Auth
  alias Plausible.Auth.SSO
  alias PlausibleWeb.LoginPreference

  alias PlausibleWeb.Router.Helpers, as: Routes

  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner] when action in [:sso_settings]

  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner, :admin] when action in [:team_sessions, :delete_session]

  # API endpoints for IdP configuration (owner access required)
  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner] when action in [
         :api_list_integrations,
         :api_get_integration,
         :api_create_integration,
         :api_update_integration,
         :api_delete_integration,
         :api_test_integration
       ]

  def login_form(conn, params) do
    login_preference = LoginPreference.get(conn)
    error = Phoenix.Flash.get(conn.assigns.flash, :login_error)

    case {login_preference, params["prefer"], error} do
      {nil, nil, nil} ->
        redirect(conn, to: Routes.auth_path(conn, :login_form, return_to: params["return_to"]))

      _ ->
        render(conn, "login_form.html", autosubmit: params["autosubmit"] != nil)
    end
  end

  def login(conn, %{"email" => email} = params) do
    with :ok <- Auth.rate_limit(:login_ip, conn),
         {:ok, %{sso_integration: integration}} <- SSO.Domains.lookup(email) do
      redirect(conn,
        to:
          Routes.sso_path(
            conn,
            :saml_signin,
            integration.identifier,
            email: email,
            return_to: params["return_to"]
          )
      )
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:login_error, "No SSO configuration found for your email domain. Please contact your administrator.")
        |> put_flash(:login_title, "Single Sign-On unavailable")
        |> redirect(to: Routes.sso_path(conn, :login_form))

      {:error, {:rate_limit, _}} ->
        Auth.log_failed_login_attempt("too many login attempts for #{email}")

        render_error(
          conn,
          429,
          "Too many login attempts. Wait a minute before trying again."
        )
    end
  end

  def provision_notice(conn, _params) do
    render(conn, "provision_notice.html")
  end

  def provision_issue(conn, params) do
    issue =
      case params["issue"] do
        "not_a_member" -> :not_a_member
        "multiple_memberships" -> :multiple_memberships
        "multiple_memberships_noforce" -> :multiple_memberships_noforce
        "active_personal_team" -> :active_personal_team
        "active_personal_team_noforce" -> :active_personal_team_noforce
        _ -> :unknown
      end

    render(conn, "provision_issue.html", issue: issue)
  end

  def saml_signin(conn, params) do
    saml_adapter().signin(conn, params)
  end

  def saml_consume(conn, params) do
    saml_adapter().consume(conn, params)
  end

  # ===== Single Logout (SLO) Endpoints =====

  @doc """
  GET /sso/saml/logout/:integration_id

  Initiates SP-initiated Single Logout by redirecting to IdP.
  """
  def saml_slo(conn, params) do
    saml_adapter().slo_initiate(conn, params)
  end

  @doc """
  POST /sso/saml/slo/:integration_id

  Handles IdP-initiated SLO (LogoutResponse from IdP after SP-initiated SLO).
  """
  def saml_slo_consume(conn, params) do
    saml_adapter().slo_consume(conn, params)
  end

  @doc """
  POST /sso/saml/slo-request/:integration_id

  Handles IdP-initiated SLO (LogoutRequest from IdP).
  """
  def saml_slo_request(conn, params) do
    saml_adapter().slo_request(conn, params)
  end

  def saml_metadata(conn, %{"integration_id" => integration_id} = _params) do
    case SSO.get_integration(integration_id) do
      {:ok, integration} ->
        metadata = saml_adapter().generate_sp_metadata(integration)

        conn
        |> put_resp_content_type("application/xml", "utf-")
        |> send_resp(200, metadata)

      {:error, :not_found} ->
        conn
        |> put_flash(:login_error, "Integration not found")
        |> redirect(to: Routes.sso_path(conn, :login_form))
    end
  end

  def csp_report(conn, _params) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    Logger.error(body)
    conn |> send_resp(200, "OK")
  end

  def cta(conn, _params) do
    render(conn, :cta, layout: {PlausibleWeb.LayoutView, :settings})
  end

  def sso_settings(conn, _params) do
    if Plausible.Teams.setup?(conn.assigns.current_team) and
         Plausible.Billing.Feature.SSO.check_availability(conn.assigns.current_team) == :ok do
      render(conn, :sso_settings,
        layout: {PlausibleWeb.LayoutView, :settings},
        connect_live_socket: true
      )
    else
      conn
      |> redirect(to: Routes.site_path(conn, :index))
    end
  end

  def team_sessions(conn, _params) do
    sso_sessions = Auth.UserSessions.list_sso_for_team(conn.assigns.current_team)

    render(conn, :team_sessions,
      layout: {PlausibleWeb.LayoutView, :settings},
      sso_sessions: sso_sessions
    )
  end

  def delete_session(conn, %{"session_id" => session_id}) do
    current_team = conn.assigns.current_team
    Auth.UserSessions.revoke_sso_by_id(current_team, session_id)

    conn
    |> put_flash(:success, "Session logged out successfully")
    |> redirect(to: Routes.sso_path(conn, :team_sessions))
  end

  # ===== IdP Configuration API Endpoints =====

  @doc """
  GET /api/sso/integrations

  Lists all SSO integrations for the current team.
  """
  def api_list_integrations(conn, _params) do
    current_team = conn.assigns.current_team

    case SSO.get_integration_for(current_team) do
      {:ok, integration} ->
        json(conn, %{
          data: %{
            id: integration.id,
            identifier: integration.identifier,
            type: "saml",
            configured: SSO.Integration.configured?(integration),
            created_at: integration.inserted_at,
            updated_at: integration.updated_at
          }
        })

      {:error, :not_found} ->
        json(conn, %{data: nil})
    end
  end

  @doc """
  GET /api/sso/integrations/:id

  Gets a specific SSO integration by ID.
  """
  def api_get_integration(conn, %{"id" => id}) do
    current_team = conn.assigns.current_team

    case SSO.get_integration(id) do
      {:ok, integration} ->
        if integration.team_id == current_team.id do
          config = integration.config

          json(conn, %{
            data: %{
              id: integration.id,
              identifier: integration.identifier,
              type: "saml",
              configured: SSO.Integration.configured?(integration),
              idp_entity_id: config.idp_entity_id,
              idp_signin_url: config.idp_signin_url,
              idp_logout_url: config.idp_logout_url,
              has_certificate: not is_nil(config.idp_cert_pem),
              has_metadata: not is_nil(config.idp_metadata),
              created_at: integration.inserted_at,
              updated_at: integration.updated_at
            }
          })
        else
          conn
          |> put_status(403)
          |> json(%{error: "Forbidden"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "Integration not found"})
    end
  end

  @doc """
  POST /api/sso/integrations

  Creates a new SSO integration for the current team.
  """
  def api_create_integration(conn, params) do
    current_team = conn.assigns.current_team

    # Check if integration already exists
    case SSO.get_integration_for(current_team) do
      {:ok, _existing} ->
        conn
        |> put_status(409)
        |> json(%{error: "Integration already exists for this team"})

      {:error, :not_found} ->
        # Create new integration
        integration = SSO.initiate_saml_integration(current_team)

        # If config params provided, update immediately
        if Map.keys(params) |> Enum.any?(&(&1 in ["idp_entity_id", "idp_signin_url", "idp_cert_pem", "idp_metadata"])) do
          case SSO.update_integration(integration, params) do
            {:ok, updated} ->
              json(conn, %{
                data: %{
                  id: updated.id,
                  identifier: updated.identifier,
                  type: "saml",
                  configured: SSO.Integration.configured?(updated),
                  created_at: updated.inserted_at,
                  updated_at: updated.updated_at
                }
              })

            {:error, changeset} ->
              conn
              |> put_status(422)
              |> json(%{error: "Invalid configuration", details: format_changeset_errors(changeset)})
          end
        else
          json(conn, %{
            data: %{
              id: integration.id,
              identifier: integration.identifier,
              type: "saml",
              configured: false,
              created_at: integration.inserted_at,
              updated_at: integration.updated_at
            }
          })
        end
    end
  end

  @doc """
  PUT /api/sso/integrations/:id

  Updates an existing SSO integration.
  """
  def api_update_integration(conn, %{"id" => id} = params) do
    current_team = conn.assigns.current_team

    # Remove id from params since it's in the URL
    update_params = Map.delete(params, "id")

    case SSO.get_integration(id) do
      {:ok, integration} ->
        if integration.team_id == current_team.id do
          case SSO.update_integration(integration, update_params) do
            {:ok, updated} ->
              config = updated.config

              json(conn, %{
                data: %{
                  id: updated.id,
                  identifier: updated.identifier,
                  type: "saml",
                  configured: SSO.Integration.configured?(updated),
                  idp_entity_id: config.idp_entity_id,
                  idp_signin_url: config.idp_signin_url,
                  has_certificate: not is_nil(config.idp_cert_pem),
                  has_metadata: not is_nil(config.idp_metadata),
                  created_at: updated.inserted_at,
                  updated_at: updated.updated_at
                }
              })

            {:error, changeset} ->
              conn
              |> put_status(422)
              |> json(%{error: "Invalid configuration", details: format_changeset_errors(changeset)})
          end
        else
          conn
          |> put_status(403)
          |> json(%{error: "Forbidden"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "Integration not found"})
    end
  end

  @doc """
  DELETE /api/sso/integrations/:id

  Deletes an SSO integration.
  """
  def api_delete_integration(conn, %{"id" => id}) do
    current_team = conn.assigns.current_team

    case SSO.get_integration(id) do
      {:ok, integration} ->
        if integration.team_id == current_team.id do
          case SSO.remove_integration(integration) do
            :ok ->
              json(conn, %{data: %{success: true, message: "Integration deleted"}})

            {:error, :force_sso_enabled} ->
              conn
              |> put_status(422)
              |> json(%{error: "Cannot delete: Force SSO is enabled for this team"})

            {:error, :sso_users_present} ->
              conn
              |> put_status(422)
              |> json(%{error: "Cannot delete: SSO users exist for this integration"})
          end
        else
          conn
          |> put_status(403)
          |> json(%{error: "Forbidden"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "Integration not found"})
    end
  end

  @doc """
  POST /api/sso/integrations/:id/test

  Tests an SSO integration configuration.
  """
  def api_test_integration(conn, %{"id" => id}) do
    current_team = conn.assigns.current_team

    case SSO.get_integration(id) do
      {:ok, integration} ->
        if integration.team_id == current_team.id do
          if SSO.Integration.configured?(integration) do
            # Try to initiate SAML signin to test configuration
            # This validates that the IdP URL and certificate are valid
            case saml_adapter().test_integration(integration) do
              :ok ->
                json(conn, %{
                  data: %{
                    success: true,
                    message: "Integration test successful"
                  }
                })

              {:error, reason} ->
                json(conn, %{
                  data: %{
                    success: false,
                    message: "Integration test failed",
                    error: reason
                  }
                })
            end
          else
            conn
            |> put_status(422)
            |> json(%{error: "Integration is not fully configured"})
          end
        else
          conn
          |> put_status(403)
          |> json(%{error: "Forbidden"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> json(%{error: "Integration not found"})
    end
  end

  # Helper function to format changeset errors
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp saml_adapter() do
    Application.fetch_env!(:plausible, :sso_saml_adapter)
  end
end
