defmodule PlausibleWeb.SAMLConfigController do
  @moduledoc """
  API controller for SAML configuration management.
  Provides JSON API endpoints for CRUD operations on SAML IdP configurations.
  """

  use PlausibleWeb, :controller

  alias Plausible.Auth.SAML
  alias Plausible.Auth.SAML.Configuration

  action_fallback PlausibleWeb.FallbackController

  plug(PlausibleWeb.RequireAccountPlug)

  on_ee do
    @doc """
    Get SAML configuration for the current team.
    """
    def show(conn, _params) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          json(conn, %{data: nil})

        config ->
          json(conn, %{
            data: %{
              id: config.id,
              idp_entity_id: config.idp_entity_id,
              idp_sso_url: config.idp_sso_url,
              enabled: config.enabled,
              inserted_at: config.inserted_at,
              updated_at: config.updated_at
            }
          })
      end
    end

    @doc """
    Create SAML configuration for the current team.
    """
    def create(conn, %{"saml_config" => config_params}) do
      current_team = conn.assigns.current_team

      case SAML.create_saml_config(current_team, config_params) do
        {:ok, config} ->
          conn
          |> put_status(:created)
          |> json(%{
            data: %{
              id: config.id,
              idp_entity_id: config.idp_entity_id,
              idp_sso_url: config.idp_sso_url,
              enabled: config.enabled,
              inserted_at: config.inserted_at,
              updated_at: config.updated_at
            }
          })

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            error: format_changeset_errors(changeset)
          })
      end
    end

    @doc """
    Update SAML configuration for the current team.
    """
    def update(conn, %{"saml_config" => config_params}) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "SAML configuration not found"})

        config ->
          case SAML.update_saml_config(config, config_params) do
            {:ok, updated_config} ->
              json(conn, %{
                data: %{
                  id: updated_config.id,
                  idp_entity_id: updated_config.idp_entity_id,
                  idp_sso_url: updated_config.idp_sso_url,
                  enabled: updated_config.enabled,
                  inserted_at: updated_config.inserted_at,
                  updated_at: updated_config.updated_at
                }
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                error: format_changeset_errors(changeset)
              })
          end
      end
    end

    @doc """
    Delete SAML configuration for the current team.
    """
    def delete(conn, _params) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "SAML configuration not found"})

        config ->
          case SAML.delete_saml_config(config) do
            {:ok, _} ->
              send_resp(conn, :no_content, "")

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{
                error: format_changeset_errors(changeset)
              })
          end
      end
    end

    @doc """
    Test SAML connection for the current team's configuration.
    """
    def test_connection(conn, _params) do
      current_team = conn.assigns.current_team

      case SAML.get_team_saml_config(current_team) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "SAML configuration not found"})

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
    Get SP metadata for SAML configuration.
    """
    def metadata(conn, _params) do
      current_team = conn.assigns.current_team

      metadata_xml = SAML.build_sp_metadata(current_team)

      conn
      |> put_resp_content_type("application/xml")
      |> send_resp(200, metadata_xml)
    end

    defp format_changeset_errors(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
    end
  else
    # CE - SAML not available
    def show(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def create(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def update(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def delete(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def test_connection(_conn, _params), do: {:error, :saml_not_available_in_ce}
    def metadata(_conn, _params), do: {:error, :saml_not_available_in_ce}
  end
end
