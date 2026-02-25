defmodule PlausibleWeb.Live.SAMLSettings do
  @moduledoc """
  LiveView for SAML configuration settings.
  """
  use PlausibleWeb, :live_view

  alias Plausible.Auth.SAML

  def mount(_params, socket) do
    current_user = socket.assigns.current_user
    current_team = socket.assigns.current_team

    saml_config = SAML.get_team_saml_config(current_team)

    {:ok,
     assign(socket,
       saml_config: saml_config,
       form: to_form(%{})
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="saml-settings-main">
      <.flash_messages flash={@flash} />

      <div class="mt-4">
        <h2 class="text-xl font-bold">SAML Authentication</h2>
        <p class="text-gray-500 mt-1">
          Configure SAML 2.0 single sign-on for your organization.
        </p>
      </div>

      <div class="mt-6">
        <%= if @saml_config do %>
          <div class="bg-white rounded-lg border border-gray-200 p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-lg font-semibold">SAML Status</h3>
                <p class="text-sm text-gray-500">
                  <%= if @saml_config.enabled do %>
                    Enabled - Users can sign in with SSO
                  <% else %>
                    Disabled - Enable to allow SSO login
                  <% end %>
                </p>
              </div>
              <div class="flex gap-2">
                <.button phx-click="toggle_enabled" class={if @saml_config.enabled, do: "bg-red-500", else: "bg-green-500"}>
                  <%= if @saml_config.enabled, do: "Disable", else: "Enable" %>
                </.button>
              </div>
            </div>

            <div class="mt-6 border-t pt-4">
              <h4 class="font-semibold mb-2">Identity Provider Details</h4>
              <dl class="grid grid-cols-1 gap-x-4 gap-y-2 sm:grid-cols-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500">Entity ID</dt>
                  <dd class="text-sm mt-1"><%= @saml_config.idp_entity_id %></dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">SSO URL</dt>
                  <dd class="text-sm mt-1"><%= @saml_config.idp_sso_url %></dd>
                </div>
              </dl>
            </div>

            <div class="mt-6 border-t pt-4">
              <h4 class="font-semibold mb-2">Service Provider Metadata</h4>
              <p class="text-sm text-gray-500 mb-2">
                Use these values when configuring your Identity Provider:
              </p>
              <dl class="grid grid-cols-1 gap-x-4 gap-y-2 sm:grid-cols-2">
                <div>
                  <dt class="text-sm font-medium text-gray-500">SP Entity ID</dt>
                  <dd class="text-sm mt-1 font-mono bg-gray-50 p-1">/saml/metadata</dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">ACS URL</dt>
                  <dd class="text-sm mt-1 font-mono bg-gray-50 p-1">/saml/acs</dd>
                </div>
              </dl>
            </div>

            <div class="mt-6 border-t pt-4">
              <.button phx-click="test_connection" class="bg-blue-500">
                Test Connection
              </.button>
            </div>
          </div>
        <% else %>
          <div class="bg-white rounded-lg border border-gray-200 p-6">
            <p class="text-gray-500">
              SAML authentication is not configured for this organization.
            </p>
            <.button phx-click="setup_saml" class="mt-4">
              Setup SAML
            </.button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("setup_saml", _params, socket) do
    # TODO: Show setup form
    {:noreply, socket}
  end

  def handle_event("toggle_enabled", _params, socket) do
    config = socket.assigns.saml_config

    {:ok, _updated} = SAML.update_saml_config(config, %{enabled: !config.enabled})

    {:noreply, assign(socket, saml_config: SAML.get_team_saml_config(socket.assigns.current_team))}
  end

  def handle_event("test_connection", _params, socket) do
    config = socket.assigns.saml_config

    case SAML.test_connection(config) do
      {:ok, message} ->
        {:noreply, put_flash(socket, :info, message)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end
end
