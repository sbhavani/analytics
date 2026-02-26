defmodule PlausibleWeb.Live.WebhookSettingsLive do
  @moduledoc """
  LiveView for managing webhook configurations.
  """
  use PlausibleWeb, :live_view

  alias Plausible.Webhooks
  alias PlausibleWeb.Live.Components.Modal

  def mount(_params, %{"site_id" => site_id, "domain" => domain}, socket) do
    socket =
      socket
      |> assign_new(:site, fn %{current_user: current_user} ->
        Plausible.Sites.get_for_user!(current_user, domain,
          roles: [:owner, :admin, :editor, :super_admin],
          include_consolidated?: true
        )
      end)
      |> assign_new(:webhooks, fn %{site: site} ->
        Webhooks.list_webhooks(site)
      end)

    {:ok,
     assign(socket,
       site_id: site_id,
       domain: domain,
       displayed_webhooks: socket.assigns.webhooks,
       editing_webhook: nil,
       show_form: false
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="webhook-settings-main">
      <.flash_messages flash={@flash} />

      <.tile docs="webhooks" site={@site} current_user={@current_user}>
        <:title>
          Webhooks
        </:title>
        <:subtitle>
          Send HTTP POST notifications when traffic spikes, drops, or goals are completed.
        </:subtitle>

        <.live_component module={Modal} preload?={false} id="webhook-form-modal">
          <.live_component
            module={PlausibleWeb.Live.WebhookSettingsLive.Form}
            id={"webhook-form"}
            domain={@domain}
            site={@site}
            webhook={@editing_webhook}
            on_save={
              fn webhook, socket ->
                send(self(), {:webhook_saved, webhook})
                Modal.close(socket, "webhook-form-modal")
              end
            }
            on_cancel={
              fn socket ->
                Modal.close(socket, "webhook-form-modal")
              end
            }
          />
        </.live_component>

        <div class="mt-4 space-y-6">
          <%= if @displayed_webhooks == [] do %>
            <p class="text-sm text-gray-500 dark:text-gray-400">
              No webhooks configured. Add one below to get started.
            </p>
          <% else %>
            <div class="space-y-4">
              <%= for webhook <- @displayed_webhooks do %>
                <div class="border rounded-md p-4 dark:border-gray-700">
                  <div class="flex justify-between items-start">
                    <div>
                      <p class="font-medium text-gray-900 dark:text-gray-100">
                        <%= webhook.url %>
                      </p>
                      <p class="text-sm text-gray-500 mt-1">
                        Events: <%= Enum.join(webhook.enabled_events, ", ") %>
                        <%= if webhook.threshold do %>
                          | Threshold: <%= webhook.threshold %>
                        <% end %>
                      </p>
                    </div>
                    <div class="flex gap-2">
                      <button
                        type="button"
                        class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                        phx-click="test-webhook"
                        phx-value-webhook-id={webhook.id}
                      >
                        Test
                      </button>
                      <button
                        type="button"
                        class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
                        phx-click="edit-webhook"
                        phx-value-webhook-id={webhook.id}
                      >
                        Edit
                      </button>
                      <button
                        type="button"
                        class="text-sm text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
                        phx-click="delete-webhook"
                        phx-value-webhook-id={webhook.id}
                        data-confirm="Are you sure you want to delete this webhook?"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="border-t pt-6 dark:border-gray-700">
            <button
              type="button"
              class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              phx-click="add-webhook"
            >
              Add Webhook
            </button>
          </div>
        </div>
      </.tile>
    </div>
    """
  end

  def handle_event("add-webhook", _params, socket) do
    socket =
      socket
      |> assign(editing_webhook: nil)
      |> Modal.open("webhook-form-modal")

    {:noreply, socket}
  end

  def handle_event("edit-webhook", %{"webhook-id" => webhook_id}, socket) do
    webhook = Webhooks.get_webhook!(webhook_id)

    socket =
      socket
      |> assign(editing_webhook: webhook)
      |> Modal.open("webhook-form-modal")

    {:noreply, socket}
  end

  def handle_event("delete-webhook", %{"webhook-id" => webhook_id}, socket) do
    webhook = Webhooks.get_webhook!(webhook_id)

    if webhook.site_id == socket.assigns.site.id do
      case Webhooks.delete_webhook(webhook) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_live_flash(:success, "Webhook deleted successfully")
           |> assign(
             displayed_webhooks: Webhooks.list_webhooks(socket.assigns.site)
           )}

        {:error, _} ->
          {:noreply,
           socket
           |> put_live_flash(:error, "Failed to delete webhook")}
      end
    else
      {:noreply,
       socket
       |> put_live_flash(:error, "Webhook not found")}
    end
  end

  def handle_event("test-webhook", %{"webhook-id" => webhook_id}, socket) do
    webhook = Webhooks.get_webhook!(webhook_id)

    if webhook.site_id == socket.assigns.site.id do
      case Webhooks.send_test_webhook(webhook) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_live_flash(:success, "Test webhook queued! It will be delivered shortly.")}

        {:error, message} ->
          {:noreply,
           socket
           |> put_live_flash(:error, "Test failed: #{message}")}
      end
    else
      {:noreply,
       socket
       |> put_live_flash(:error, "Webhook not found")}
    end
  end

  def handle_info({:webhook_saved, _webhook}, socket) do
    socket =
      socket
      |> put_live_flash(:success, "Webhook saved successfully")
      |> assign(
        displayed_webhooks: Webhooks.list_webhooks(socket.assigns.site),
        editing_webhook: nil,
        show_form: false
      )

    {:noreply, socket}
  end
end
