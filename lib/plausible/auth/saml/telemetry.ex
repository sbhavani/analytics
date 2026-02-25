defmodule Plausible.Auth.SAML.Telemetry do
  @moduledoc """
  Telemetry events for SAML authentication.
  """

  require Logger

  # Event prefixes
  @saml_auth_events [:plausible, :saml, :auth]

  @doc """
  Emit telemetry for SAML login initiation.
  """
  def emit_login_initiated(team_id) do
    :telemetry.execute(
      @saml_auth_events ++ [:login, :initiated],
      %{count: 1},
      %{team_id: team_id}
    )

    Logger.info("[Telemetry] SAML login initiated", team_id: team_id)
  end

  @doc """
  Emit telemetry for SAML login success.
  """
  def emit_login_success(team_id, email) do
    :telemetry.execute(
      @saml_auth_events ++ [:login, :success],
      %{count: 1},
      %{team_id: team_id, email: email}
    )

    Logger.info("[Telemetry] SAML login success", team_id: team_id, email: email)
  end

  @doc """
  Emit telemetry for SAML login failure.
  """
  def emit_login_failure(team_id, reason) do
    :telemetry.execute(
      @saml_auth_events ++ [:login, :failure],
      %{count: 1},
      %{team_id: team_id, reason: reason}
    )

    Logger.warning("[Telemetry] SAML login failure", team_id: team_id, reason: reason)
  end

  @doc """
  Emit telemetry for SAML configuration changes.
  """
  def emit_config_changed(team_id, action) do
    :telemetry.execute(
      @saml_auth_events ++ [:config, :changed],
      %{count: 1},
      %{team_id: team_id, action: action}
    )

    Logger.info("[Telemetry] SAML config changed", team_id: team_id, action: action)
  end

  @doc """
  Emit telemetry for SAML connection test.
  """
  def emit_connection_test(team_id, success) do
    :telemetry.execute(
      @saml_auth_events ++ [:connection_test, :total],
      %{count: 1},
      %{team_id: team_id, success: success}
    )

    Logger.info("[Telemetry] SAML connection test", team_id: team_id, success: success)
  end
end
