defmodule PlausibleWeb.Live.WebhookSettingsLive.Form do
  @moduledoc """
  Form component for creating and editing webhooks.
  """
  use PlausibleWeb, :live_component

  alias Plausible.Site.Webhook
  alias Plausible.Webhooks

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    webhook = Map.get(assigns, :webhook)

    form =
      if webhook do
        to_form(Webhook.changeset(webhook, %{}))
      else
        to_form(Webhook.changeset(%Webhook{}, %{}))
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-medium mb-4">
        <%= if @webhook do %>
          Edit Webhook
        <% else %>
          Add Webhook
        <% end %>
      </h3>

      <.form
        :let={f}
        for={@form}
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Webhook URL
            </label>
            <%= text_input f, :url,
              class: "mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 dark:bg-gray-800 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              placeholder: "https://example.com/webhook",
              required: true
            %>
            <%= error_tag f, :url %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Secret (min 16 characters)
            </label>
            <%= password_input f, :secret,
              class: "mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 dark:bg-gray-800 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              placeholder: "Enter a secret for HMAC signing",
              required: true,
              minlength: 16
            %>
            <p class="mt-1 text-xs text-gray-500">
              Used to sign the webhook payload with HMAC-SHA256
            </p>
            <%= error_tag f, :secret %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Enabled Events
            </label>
            <div class="mt-2 space-y-2">
              <div class="flex items-center">
                <%= checkbox f, :enabled_events,
                  name: "webhook[enabled_events][]",
                  id: "webhook_spike",
                  value: "spike",
                  checked: Enum.member?(@webhook && @webhook.enabled_events || [], "spike"),
                  class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                %>
                <label for="webhook_spike" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                  Traffic Spike
                </label>
              </div>
              <div class="flex items-center">
                <%= checkbox f, :enabled_events,
                  name: "webhook[enabled_events][]",
                  id: "webhook_drop",
                  value: "drop",
                  checked: Enum.member?(@webhook && @webhook.enabled_events || [], "drop"),
                  class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                %>
                <label for="webhook_drop" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                  Traffic Drop
                </label>
              </div>
              <div class="flex items-center">
                <%= checkbox f, :enabled_events,
                  name: "webhook[enabled_events][]",
                  id: "webhook_goal",
                  value: "goal",
                  checked: Enum.member?(@webhook && @webhook.enabled_events || [], "goal"),
                  class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                %>
                <label for="webhook_goal" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                  Goal Completions
                </label>
              </div>
            </div>
            <%= error_tag f, :enabled_events %>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Threshold (for spike/drop)
            </label>
            <%= number_input f, :threshold,
              class: "mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 dark:bg-gray-800 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              placeholder: "e.g., 100"
            %>
            <p class="mt-1 text-xs text-gray-500">
              Number of visitors that triggers a spike or drop notification
            </p>
            <%= error_tag f, :threshold %>
          </div>

          <div class="flex gap-2">
            <button
              type="submit"
              class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              <%= if @webhook do %>
                Save Changes
              <% else %>
                Add Webhook
              <% end %>
            </button>
            <button
              type="button"
              class="inline-flex justify-center rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              phx-click="cancel"
              phx-target={@myself}
            >
              Cancel
            </button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("save", %{"webhook" => webhook_params}, %{assigns: %{site: site, webhook: existing_webhook, on_save: on_save}} = socket) do
    # Convert checkbox array - Phoenix sends arrays as lists with the [] suffix
    enabled_events = Map.get(webhook_params, "enabled_events") || []

    # Convert threshold to integer if provided
    threshold =
      case Map.get(webhook_params, "threshold") do
        "" -> nil
        val when is_binary(val) -> String.to_integer(val)
        val -> val
      end

    params = %{
      "url" => Map.get(webhook_params, "url"),
      "secret" => Map.get(webhook_params, "secret"),
      "enabled_events" => enabled_events,
      "threshold" => threshold
    }

    case existing_webhook do
      nil ->
        case Webhooks.create_webhook(site, params) do
          {:ok, webhook} ->
            socket = on_save.(webhook, socket)
            {:noreply, socket}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end

      existing ->
        case Webhooks.update_webhook(existing, params) do
          {:ok, webhook} ->
            socket = on_save.(webhook, socket)
            {:noreply, socket}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
    end
  end

  def handle_event("cancel", _params, %{assigns: %{on_cancel: on_cancel}} = socket) do
    socket = on_cancel.(socket)
    {:noreply, socket}
  end
end
