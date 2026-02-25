defmodule PlausibleWeb.SAMLController do
  @moduledoc """
  Controller for SAML authentication endpoints.
  """

  use PlausibleWeb, :controller

  alias Plausible.Auth.SAML
  alias PlausibleWeb.UserAuth
  alias Plausible.Teams

  require Logger

  plug :ensure_not_logged_in when action in [:login, :acs]

  action_fallback PlausibleWeb.FallbackController

  on_ee do
    @doc """
    SP-initiated SSO login - redirects to IdP.
    """
    def login(conn, %{"team_id" => team_id} = params) do
      relay_state = Map.get(params, "return_to")

      case Teams.get(team_id) do
        nil ->
          conn
          |> put_flash(:error, "Team not found")
          |> redirect(to: "/login")

        team ->
          case SAML.initiate_login(team, relay_state) do
            {:ok, redirect_url} ->
              redirect(conn, external: redirect_url)

            {:error, :saml_not_configured} ->
              conn
              |> put_flash(:error, "SAML is not configured for this organization")
              |> redirect(to: "/login")

            {:error, :saml_disabled} ->
              conn
              |> put_flash(:error, "SAML is disabled for this organization")
              |> redirect(to: "/login")

            {:error, reason} ->
              conn
              |> put_flash(:error, "SAML login failed: #{inspect(reason)}")
              |> redirect(to: "/login")
          end
      end
    end

    @doc """
    Assertion Consumer Service - handles SAML response from IdP.
    """
    def acs(conn, %{"SAMLResponse" => saml_response}) do
      relay_state = conn.params["RelayState"]

      # Get team from session or relay state
      team_id = get_session(conn, :saml_team_id) || relay_state

      team =
        if team_id do
          Teams.get(team_id)
        else
          nil
        end

      if team do
        case SAML.handle_response(team, saml_response, relay_state) do
          {:ok, %{email: email, name: name, session_index: session_index}} ->
            # Create or find user based on SAML assertion
            # This would integrate with existing SSO provisioning
            # For now, we redirect to a page that handles provisioning
            conn
            |> put_session(:saml_assertion, %{email: email, name: name, session_index: session_index})
            |> redirect(to: "/saml/provision")

          {:error, reason} ->
            Logger.warning("[SAML] ACS failed: #{inspect(reason)}")

            conn
            |> put_flash(:error, "SAML authentication failed")
            |> redirect(to: "/login")
        end
      else
        conn
        |> put_flash(:error, "Invalid SAML response")
        |> redirect(to: "/login")
      end
    end

    @doc """
    SP metadata endpoint.
    """
    def metadata(conn, _params) do
      metadata_xml = SAML.build_sp_metadata(nil)

      conn
      |> put_resp_content_type("application/xml")
      |> send_resp(200, metadata_xml)
    end

    @doc """
    Provision user from SAML assertion - redirects to create session.
    """
    def provision(conn, _params) do
      assertion = get_session(conn, :saml_assertion)

      if assertion do
        # TODO: Implement actual user provisioning via existing SSO infrastructure
        # For now, just show a message
        conn
        |> put_flash(:info, "SAML authentication successful. Email: #{assertion.email}")
        |> redirect(to: "/")
      else
        conn
        |> put_flash(:error, "No SAML assertion found")
        |> redirect(to: "/login")
      end
    end

    @doc """
    Render SAML settings page.
    """
    def settings(conn, _params) do
      render(conn, "settings.html")
    end

    @doc """
    Update SAML settings.
    """
    def update_settings(conn, %{"saml_config" => config_params}) do
      current_team = conn.assigns.current_team

      case SAML.create_saml_config(current_team, config_params) do
        {:ok, _config} ->
          conn
          |> put_flash(:info, "SAML configuration saved")
          |> redirect(to: Routes.saml_path(conn, :settings))

        {:error, changeset} ->
          conn
          |> put_flash(:error, "Failed to save SAML configuration: #{inspect(changeset.errors)}")
          |> render("settings.html", changeset: changeset)
      end
    end

    @doc """
    Test SAML connection.
    """
    def test_connection(conn, _params) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          json(conn, %{success: false, message: "No SAML configuration found"})

        config ->
          case SAML.test_connection(config) do
            {:ok, message} ->
              json(conn, %{success: true, message: message})

            {:error, message} ->
              json(conn, %{success: false, message: message})
          end
      end
    end

    @doc """
    Update SAML configuration via API.
    """
    def update(conn, %{"saml_config" => config_params}) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          conn
          |> put_status(404)
          |> json(%{error: "SAML configuration not found"})

        config ->
          case SAML.update_saml_config(config, config_params) do
            {:ok, updated_config} ->
              json(conn, %{
                success: true,
                message: "SAML configuration updated",
                config: %{
                  idp_entity_id: updated_config.idp_entity_id,
                  idp_sso_url: updated_config.idp_sso_url,
                  enabled: updated_config.enabled
                }
              })

            {:error, changeset} ->
              conn
              |> put_status(422)
              |> json(%{error: "Failed to update SAML configuration", details: inspect(changeset.errors)})
          end
      end
    end

    @doc """
    Delete SAML configuration via API.
    """
    def delete(conn, _params) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          conn
          |> put_status(404)
          |> json(%{error: "SAML configuration not found"})

        config ->
          case SAML.delete_saml_config(config) do
            {:ok, _} ->
              json(conn, %{success: true, message: "SAML configuration deleted"})

            {:error, reason} ->
              conn
              |> put_status(422)
              |> json(%{error: "Failed to delete SAML configuration", details: inspect(reason)})
          end
      end
    end
  else
    # CE - SAML not available
    def login(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def acs(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def metadata(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def provision(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def update(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def delete(_conn, _params), do: {:error, :saml_not_available_in_ce}
  end

  defp ensure_not_logged_in(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: "/")
      |> halt()
    else
      conn
    end
  end
end
