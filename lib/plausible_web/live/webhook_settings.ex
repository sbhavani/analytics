defmodule PlausibleWeb.Live.WebhookSettings do
  @moduledoc """
  LiveView for webhook configuration.
  """
  use PlausibleWeb, :live_view

  alias Plausible.Webhooks.Context

  def mount(
        _params,
        %{"site_id" => site_id, "domain" => domain, "webhooks" => webhooks_json},
        socket
      ) do
    webhooks = Jason.decode!(webhooks_json)

    socket =
      socket
      |> assign_new(:site, fn %{current_user: current_user} ->
        Plausible.Sites.get_for_user!(current_user, domain,
          roles: [:owner, :admin, :super_admin]
        )
      end)

    {:ok,
     assign(socket,
       site_id: site_id,
       domain: domain,
       webhooks: webhooks,
       form: nil,
       editing_webhook: nil
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="webhook-settings-main">
      <.flash_messages flash={@flash} />

      <div :if={!@form} class="mb-6">
        <.button phoenix-click="new-webhook">
          + Add Webhook
        </.button>
      </div>

      <div :if={@form} class="mb-6 p-4 border rounded bg-gray-50">
        <.form :let={f} for={@form} phoenix-submit="save-webhook">
          <div class="space-y-4">
            <.input
              field={f[:url]}
              label="Endpoint URL"
              placeholder="https://example.com/webhook"
              required
            />

            <.input
              field={f[:secret]}
              label="Shared Secret (min 16 characters)"
              placeholder="Enter a secret for HMAC signing"
              required
            />

            <div>
              <label class="block text-sm font-medium mb-1">Triggers</label>
              <div class="space-y-2">
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="webhook[triggers][]"
                    value="goal_completion"
                    checked={Enum.member?(@form.params["triggers"] || [], "goal_completion")}
                    class="mr-2"
                  />
                  Goal Completion
                </label>
                <label class="flex items-center">
                  <input
                    type="checkbox"
                    name="webhook[triggers][]"
                    value="visitor_spike"
                    checked={Enum.member?(@form.params["triggers"] || [], "visitor_spike")}
                    class="mr-2"
                  />
                  Visitor Spike
                </label>
              </div>
            </div>

            <div :if={Enum.member?(@form.params["triggers"] || [], "visitor_spike")}>
              <.input
                field={f[:threshold]}
                type="number"
                label="Visitor Spike Threshold (%)"
                placeholder="50"
                value={@form.params["threshold"] || "50"}
              />
            </div>

            <div class="flex space-x-2">
              <.button type="submit">
                <%= if @editing_webhook, do: "Update", else: "Create" %>
              </.button>
              <.button type="button" theme="secondary" phoenix-click="cancel-form">
                Cancel
              </.button>
            </div>
          </div>
        </.form>
      </div>

      <div class="space-y-4">
        <%= for webhook <- @webhooks do %>
          <div class="border rounded p-4 flex items-center justify-between">
            <div>
              <div class="font-medium"><%= webhook["url"] %></div>
              <div class="text-sm text-gray-500">
                <%= if webhook["enabled"], do: "Active", else: "Disabled" %> |
                <%= Enum.join(webhook["triggers"], ", ") %>
              </div>
            </div>
            <div class="flex space-x-2">
              <.button size="sm" theme="secondary" phoenix-click="toggle-webhook" phoenix-value={webhook["id"]}>
                <%= if webhook["enabled"], do: "Disable", else: "Enable" %>
              </.button>
              <.button size="sm" theme="secondary" phoenix-click="edit-webhook" phoenix-value={webhook["id"]}>
                Edit
              </.button>
              <.button size="sm" theme="danger" phoenix-click="delete-webhook" phoenix-value={webhook["id"]}>
                Delete
              </.button>
            </div>
          </div>
        <% end %>
      </div>

      <div :if={Enum.empty?(@webhooks)} class="text-gray-500 text-center py-8">
        No webhooks configured. Add a webhook to receive notifications.
      </div>
    </div>
    """
  end

  def handle_event("new-webhook", _params, socket) do
    form = %{"url" => "", "secret" => "", "triggers" => [], "threshold" => "50"}
             |> Phoenix.Component.to_form()

    {:noreply, assign(socket, form: form, editing_webhook: nil)}
  end

  def handle_event("edit-webhook", %{"value" => webhook_id}, socket) do
    webhook = Enum.find(socket.assigns.webhooks, fn w -> w["id"] == webhook_id end)

    form = %{"url" => webhook["url"], "secret" => webhook["secret"], "triggers" => webhook["triggers"] || [], "threshold" => Map.get(webhook["thresholds"], "visitor_spike", 50) |> to_string()}
           |> Phoenix.Component.to_form()

    {:noreply, assign(socket, form: form, editing_webhook: webhook_id)}
  end

  def handle_event("cancel-form", _params, socket) do
    {:noreply, assign(socket, form: nil, editing_webhook: nil)}
  end

  def handle_event("save-webhook", %{"webhook" => params}, socket) do
    site = socket.assigns.site
    thresholds = if params["triggers"] && "visitor_spike" in params["triggers"] do
      %{"visitor_spike" => String.to_integer(params["threshold"] || "50")}
    else
      %{}
    end

    webhook_params = %{
      "url" => params["url"],
      "secret" => params["secret"],
      "enabled" => true,
      "triggers" => params["triggers"] || [],
      "thresholds" => thresholds
    }

    case socket.assigns.editing_webhook do
      nil ->
        case Context.create_webhook(site.id, webhook_params) do
          {:ok, _webhook} ->
            webhooks = Context.list_webhooks(site.id)
            {:noreply, assign(socket, webhooks: webhooks, form: nil, editing_webhook: nil) |> put_flash(:info, "Webhook created")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to create webhook")}
        end

      webhook_id ->
        webhook = Context.get_webhook!(webhook_id, site.id)
        case Context.update_webhook(webhook, webhook_params) do
          {:ok, _webhook} ->
            webhooks = Context.list_webhooks(site.id)
            {:noreply, assign(socket, webhooks: webhooks, form: nil, editing_webhook: nil) |> put_flash(:info, "Webhook updated")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update webhook")}
        end
    end
  end

  def handle_event("toggle-webhook", %{"value" => webhook_id}, socket) do
    site = socket.assigns.site

    webhook = Context.get_webhook!(webhook_id, site.id)

    case Context.toggle_webhook(webhook) do
      {:ok, _webhook} ->
        webhooks = Context.list_webhooks(site.id)
        {:noreply, assign(socket, webhooks: webhooks)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to toggle webhook")}
    end
  end

  def handle_event("delete-webhook", %{"value" => webhook_id}, socket) do
    site = socket.assigns.site

    webhook = Context.get_webhook!(webhook_id, site.id)

    case Context.delete_webhook(webhook) do
      {:ok, _webhook} ->
        webhooks = Context.list_webhooks(site.id)
        {:noreply, assign(socket, webhooks: webhooks) |> put_flash(:info, "Webhook deleted")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete webhook")}
    end
  end
end
