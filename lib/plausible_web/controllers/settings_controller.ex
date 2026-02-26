defmodule PlausibleWeb.SettingsController do
  use PlausibleWeb, :controller
  use Plausible
  use Plausible.Repo

  alias Plausible.Auth
  alias Plausible.Teams

  require Logger

  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner, :admin]
       when action in [:update_team_name]

  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner, :billing] when action in [:subscription]

  plug Plausible.Plugs.AuthorizeTeamAccess,
       [:owner]
       when action in [
              :team_danger_zone,
              :delete_team,
              :enable_team_force_2fa,
              :disable_team_force_2fa
            ]

  plug Plausible.Plugs.RestrictUserType,
       [deny: :sso] when action in [:update_name, :update_email, :update_password]

  def index(conn, _params) do
    redirect(conn, to: Routes.settings_path(conn, :preferences))
  end

  def team_general(conn, _params) do
    render_team_general(conn)
  end

  def update_team_name(conn, %{"team" => params}) do
    changeset = Teams.Team.name_changeset(conn.assigns.current_team, params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, "Team name changed")
        |> redirect(to: Routes.settings_path(conn, :team_general) <> "#update-name")

      {:error, changeset} ->
        render_team_general(conn, team_name_changeset: changeset)
    end
  end

  defp render_team_general(conn, opts \\ []) do
    if Teams.setup?(conn.assigns.current_team) do
      name_changeset =
        Keyword.get(
          opts,
          :team_name_changeset,
          Teams.Team.name_changeset(conn.assigns.current_team)
        )

      render(conn, :team_general,
        team_name_changeset: name_changeset,
        force_2fa_enabled?: Teams.force_2fa_enabled?(conn.assigns.current_team),
        layout: {PlausibleWeb.LayoutView, :settings},
        connect_live_socket: true
      )
    else
      conn
      |> redirect(to: Routes.site_path(conn, :index))
    end
  end

  def enable_team_force_2fa(conn, _params) do
    team = conn.assigns.current_team
    user = conn.assigns.current_user

    case Teams.enable_force_2fa(team, user) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "2FA is now required for all team members.")
        |> redirect(to: Routes.settings_path(conn, :team_general))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to enforce 2FA for all team members.")
        |> redirect(to: Routes.settings_path(conn, :team_general))
    end
  end

  def disable_team_force_2fa(conn, %{"password" => password}) do
    team = conn.assigns.current_team
    user = conn.assigns.current_user

    case Teams.disable_force_2fa(team, user, password) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "2FA is no longer enforced for team members.")
        |> redirect(to: Routes.settings_path(conn, :team_general))

      {:error, :invalid_password} ->
        conn
        |> put_flash(:error, "Incorrect password provided.")
        |> redirect(to: Routes.settings_path(conn, :team_general))

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to disable enforcing 2FA for all team members.")
        |> redirect(to: Routes.settings_path(conn, :team_general))
    end
  end

  def leave_team(conn, _params) do
    case Teams.Memberships.Leave.leave(conn.assigns.current_team, conn.assigns.current_user) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "You have left \"#{Teams.name(conn.assigns.current_team)}\"")
        |> redirect(to: Routes.site_path(conn, :index, __team: "none"))

      {:error, :only_one_owner} ->
        conn
        |> put_flash(:error, "You can't leave as you are the only Owner on the team")
        |> redirect(to: Routes.settings_path(conn, :team_general))

      {:error, :membership_not_found} ->
        redirect(conn, to: Routes.site_path(conn, :index, __team: "none"))
    end
  end

  def preferences(conn, _params) do
    render_preferences(conn)
  end

  def security(conn, _params) do
    render_security(conn)
  end

  def subscription(conn, _params) do
    team = conn.assigns.current_team
    subscription = Teams.Billing.get_subscription(team)

    invoices = Plausible.Billing.paddle_api().get_invoices(subscription)

    render(conn, :subscription,
      layout: {PlausibleWeb.LayoutView, :settings},
      subscription: subscription,
      invoices: invoices,
      pageview_limit: Teams.Billing.monthly_pageview_limit(subscription),
      pageview_usage: Teams.Billing.monthly_pageview_usage(team),
      site_usage: Teams.Billing.site_usage(team),
      site_limit: Teams.Billing.site_limit(team),
      team_member_limit: Teams.Billing.team_member_limit(team),
      team_member_usage: Teams.Billing.team_member_usage(team)
    )
  end

  def api_keys(conn, _params) do
    current_user = conn.assigns.current_user
    current_team = conn.assigns[:current_team]

    api_keys = Auth.list_api_keys(current_user, current_team)

    render(conn, :api_keys, layout: {PlausibleWeb.LayoutView, :settings}, api_keys: api_keys)
  end

  def new_api_key(conn, _params) do
    current_team = conn.assigns[:current_team]

    sites_api_enabled? =
      Plausible.Billing.Feature.SitesAPI.check_availability(current_team) == :ok

    changeset = Auth.ApiKey.changeset(%Auth.ApiKey{type: "stats_api"}, current_team, %{})

    render(conn, "new_api_key.html", changeset: changeset, sites_api_enabled?: sites_api_enabled?)
  end

  def create_api_key(conn, %{"api_key" => %{"name" => name, "key" => key, "type" => type}}) do
    current_user = conn.assigns.current_user
    current_team = conn.assigns.current_team

    sites_api_enabled? =
      Plausible.Billing.Feature.SitesAPI.check_availability(current_team) == :ok

    api_key_fn =
      if type == "sites_api" do
        &Auth.create_sites_api_key/4
      else
        &Auth.create_stats_api_key/4
      end

    case api_key_fn.(current_user, current_team, name, key) do
      {:ok, _api_key} ->
        conn
        |> put_flash(:success, "API key created successfully")
        |> redirect(to: Routes.settings_path(conn, :api_keys) <> "#api-keys")

      {:error, :upgrade_required} ->
        conn
        |> put_flash(:error, "Your current subscription plan does not include Sites API access")
        |> redirect(to: Routes.settings_path(conn, :new_api_key))

      {:error, changeset} ->
        render(conn, "new_api_key.html",
          changeset: changeset,
          sites_api_enabled?: sites_api_enabled?
        )
    end
  end

  def delete_api_key(conn, %{"id" => id}) do
    case Auth.delete_api_key(conn.assigns.current_user, id) do
      :ok ->
        conn
        |> put_flash(:success, "API key revoked successfully")
        |> redirect(to: Routes.settings_path(conn, :api_keys) <> "#api-keys")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Could not find API Key to delete")
        |> redirect(to: Routes.settings_path(conn, :api_keys) <> "#api-keys")
    end
  end

  def danger_zone(conn, _params) do
    solely_owned_teams =
      conn.assigns.current_user
      |> Teams.Users.owned_teams()
      |> Enum.filter(& &1.setup_complete)
      |> Enum.reject(fn team ->
        Teams.Memberships.owners_count(team) > 1
      end)

    render(conn, :danger_zone,
      solely_owned_teams: solely_owned_teams,
      layout: {PlausibleWeb.LayoutView, :settings}
    )
  end

  def team_danger_zone(conn, _params) do
    render(conn, :team_danger_zone, layout: {PlausibleWeb.LayoutView, :settings})
  end

  def delete_team(conn, _params) do
    team = conn.assigns.current_team

    case Plausible.Teams.delete(team) do
      {:ok, :deleted} ->
        conn
        |> put_flash(:success, ~s|Team "#{Plausible.Teams.name(team)}" deleted|)
        |> redirect(to: Routes.site_path(conn, :index, __team: "none"))

      {:error, :active_subscription} ->
        conn
        |> put_flash(
          :error,
          "Team has an active subscription. You must cancel it first."
        )
        |> redirect(to: Routes.settings_path(conn, :team_danger_zone))
    end
  end

  # Preferences actions

  def update_name(conn, %{"user" => params}) do
    changeset = Auth.User.name_changeset(conn.assigns.current_user, params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, "Name changed")
        |> redirect(to: Routes.settings_path(conn, :preferences) <> "#update-name")

      {:error, changeset} ->
        render_preferences(conn, name_changeset: changeset)
    end
  end

  def update_theme(conn, %{"user" => params}) do
    changeset = Auth.User.theme_changeset(conn.assigns.current_user, params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, "Theme changed")
        |> redirect(to: Routes.settings_path(conn, :preferences) <> "#update-theme")

      {:error, changeset} ->
        render_preferences(conn, theme_changeset: changeset)
    end
  end

  defp render_preferences(conn, opts \\ []) do
    name_changeset =
      Keyword.get(opts, :name_changeset, Auth.User.name_changeset(conn.assigns.current_user))

    theme_changeset =
      Keyword.get(opts, :theme_changeset, Auth.User.theme_changeset(conn.assigns.current_user))

    render(conn, :preferences,
      name_changeset: name_changeset,
      theme_changeset: theme_changeset,
      layout: {PlausibleWeb.LayoutView, :settings}
    )
  end

  # Security actions

  def update_email(conn, %{"user" => params}) do
    user = conn.assigns.current_user

    with :ok <- Auth.rate_limit(:email_change_user, user),
         changes = Auth.User.email_changeset(user, params),
         {:ok, user} <- Repo.update(changes) do
      if user.email_verified do
        handle_email_updated(conn)
      else
        Auth.EmailVerification.issue_code(user)
        redirect(conn, to: Routes.auth_path(conn, :activate_form))
      end
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render_security(conn, email_changeset: changeset)

      {:error, {:rate_limit, _}} ->
        changeset =
          user
          |> Auth.User.email_changeset(params)
          |> Ecto.Changeset.add_error(:email, "too many requests, try again in an hour")
          |> Map.put(:action, :validate)

        render_security(conn, email_changeset: changeset)
    end
  end

  def cancel_update_email(conn, _params) do
    changeset = Auth.User.cancel_email_changeset(conn.assigns.current_user)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "Email changed back to #{user.email}")
        |> redirect(to: Routes.settings_path(conn, :security) <> "#update-email")

      {:error, _} ->
        conn
        |> put_flash(
          :error,
          "Could not cancel email update because previous email has already been taken"
        )
        |> redirect(to: Routes.auth_path(conn, :activate_form))
    end
  end

  def update_password(conn, %{"user" => params}) do
    user = conn.assigns.current_user
    user_session = conn.assigns.current_user_session

    with :ok <- Auth.rate_limit(:password_change_user, user),
         {:ok, user} <- do_update_password(user, params) do
      Auth.UserSessions.revoke_all(user, except: user_session)

      conn
      |> put_flash(:success, "Your password is now changed")
      |> redirect(to: Routes.settings_path(conn, :security) <> "#update-password")
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render_security(conn, password_changeset: changeset)

      {:error, {:rate_limit, _}} ->
        changeset =
          user
          |> Auth.User.password_changeset(params)
          |> Ecto.Changeset.add_error(:password, "too many attempts, try again in 20 minutes")
          |> Map.put(:action, :validate)

        render_security(conn, password_changeset: changeset)
    end
  end

  defp render_security(conn, opts \\ []) do
    user_sessions = Auth.UserSessions.list_for_user(conn.assigns.current_user)

    email_changeset =
      Keyword.get(
        opts,
        :email_changeset,
        Auth.User.email_changeset(conn.assigns.current_user, %{email: ""})
      )

    password_changeset =
      Keyword.get(
        opts,
        :password_changeset,
        Auth.User.password_changeset(conn.assigns.current_user)
      )

    render(conn, :security,
      totp_enabled?: Auth.TOTP.enabled?(conn.assigns.current_user),
      user_sessions: user_sessions,
      email_changeset: email_changeset,
      password_changeset: password_changeset,
      layout: {PlausibleWeb.LayoutView, :settings}
    )
  end

  def delete_session(conn, %{"id" => session_id}) do
    current_user = conn.assigns.current_user

    :ok = Auth.UserSessions.revoke_by_id(current_user, session_id)

    conn
    |> put_flash(:success, "Session logged out successfully")
    |> redirect(to: Routes.settings_path(conn, :security) <> "#user-sessions")
  end

  defp do_update_password(user, params) do
    changes = Auth.User.password_changeset(user, params)

    Repo.transaction(fn ->
      with {:ok, user} <- Repo.update(changes),
           {:ok, user} <- validate_2fa_code(user, params["two_factor_code"]) do
        user
      else
        {:error, :invalid_2fa} ->
          changes
          |> Ecto.Changeset.add_error(:password, "invalid 2FA code")
          |> Map.put(:action, :validate)
          |> Repo.rollback()

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp validate_2fa_code(user, code) do
    if Auth.TOTP.enabled?(user) do
      case Auth.TOTP.validate_code(user, code) do
        {:ok, user} -> {:ok, user}
        {:error, :not_enabled} -> {:ok, user}
        {:error, _} -> {:error, :invalid_2fa}
      end
    else
      {:ok, user}
    end
  end

  defp handle_email_updated(conn) do
    conn
    |> put_flash(:success, "Email updated")
    |> redirect(to: Routes.settings_path(conn, :security) <> "#update-email")
  end

  # SSO/SAML Configuration
  on_ee do
    def sso(conn, _params) do
      team = conn.assigns.current_team

      # Get existing SSO integration if any
      sso_integration = get_sso_integration(team.id)

      render(conn, :sso,
        sso_integration: sso_integration,
        layout: {PlausibleWeb.LayoutView, :settings}
      )
    end

    def update_sso(conn, %{"sso" => params}) do
      team = conn.assigns.current_team

      case save_sso_integration(team.id, params) do
        {:ok, _integration} ->
          conn
          |> put_flash(:success, "SSO configuration saved")
          |> redirect(to: Routes.settings_path(conn, :sso) <> "#sso-config")

        {:error, changeset} ->
          conn
          |> put_flash(:error, "Failed to save SSO configuration")
          |> render(:sso,
            sso_integration: changeset,
            layout: {PlausibleWeb.LayoutView, :settings}
          )
      end
    end

    def test_sso(conn, %{"sso" => params}) do
      case Auth.SSO.test_connection(params) do
        {:ok, _result} ->
          json(conn, %{success: true, message: "Connection test successful"})

        {:error, error} ->
          json(conn, %{success: false, message: "Connection failed: #{inspect(error)}"})
      end
    end

    def enable_sso(conn, %{"integration_id" => integration_id}) do
      team = conn.assigns.current_team

      case enable_sso_integration(team.id, integration_id) do
        {:ok, _integration} ->
          conn
          |> put_flash(:success, "SSO enabled")
          |> redirect(to: Routes.settings_path(conn, :sso))

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to enable SSO: #{inspect(reason)}")
          |> redirect(to: Routes.settings_path(conn, :sso))
      end
    end

    def disable_sso(conn, _params) do
      team = conn.assigns.current_team

      case disable_sso_integration(team.id) do
        {:ok, _integration} ->
          conn
          |> put_flash(:success, "SSO disabled")
          |> redirect(to: Routes.settings_path(conn, :sso))

        {:error, reason} ->
          conn
          |> put_flash(:error, "Failed to disable SSO: #{inspect(reason)}")
          |> redirect(to: Routes.settings_path(conn, :sso))
      end
    end

    # Private helpers for SSO

    defp get_sso_integration(team_id) do
      # Query sso_integrations table
      import Ecto.Query
      Plausible.Repo.one(from i in Plausible.Auth.SSO.Integration, where: i.team_id == ^team_id)
    end

    defp save_sso_integration(team_id, params) do
      # Validate config first
      case Auth.SSO.validate_config(params) do
        :ok ->
          # Save to database
          integration = get_sso_integration(team_id)

          if integration do
            # Update existing
            Ecto.Changeset.change(integration, %{
              identifier: :crypto.strong_rand_bytes(16) |> Base.encode16(),
              config: %{
                idp_entity_id: params["idp_entity_id"],
                idp_sso_url: params["idp_sso_url"],
                idp_certificate: params["idp_certificate"]
              }
            })
            |> Plausible.Repo.update()
          else
            # Create new
            %Plausible.Auth.SSO.Integration{
              team_id: team_id,
              identifier: :crypto.strong_rand_bytes(16) |> Base.encode16(),
              config: %{
                idp_entity_id: params["idp_entity_id"],
                idp_sso_url: params["idp_sso_url"],
                idp_certificate: params["idp_certificate"]
              }
            }
            |> Plausible.Repo.insert()
          end

        {:error, errors} ->
          {:error, errors}
      end
    end

    defp enable_sso_integration(team_id, integration_id) do
      # Enable the SSO integration
      import Ecto.Query

      from(i in Plausible.Auth.SSO.Integration,
        where: i.id == ^integration_id and i.team_id == ^team_id
      )
      |> Plausible.Repo.update_all(set: [enabled: true])
      |> case do
        {1, _} -> {:ok, :enabled}
        _ -> {:error, :not_found}
      end
    end

    defp disable_sso_integration(team_id) do
      # Disable all SSO integrations for the team
      import Ecto.Query

      from(i in Plausible.Auth.SSO.Integration,
        where: i.team_id == ^team_id
      )
      |> Plausible.Repo.update_all(set: [enabled: false])
      |> case do
        {_count, _} -> {:ok, :disabled}
        _ -> {:error, :not_found}
      end
    end
  end
end
