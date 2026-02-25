defmodule PlausibleWeb.API.WebhookController do
  @moduledoc """
  API controller for webhook management.
  """
  use PlausibleWeb, :controller
  use Plausible.Repo

  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Trigger
  alias Plausible.Webhooks.Delivery

  plug :verify_site when action in [:index, :create, :show, :update, :delete, :add_trigger, :remove_trigger, :deliveries]

  # List all webhooks for a site
  def index(conn, _params) do
    site = conn.assigns.site
    webhooks = Webhooks.list_webhooks_for_site(site.id)

    conn
    |> put_status(200)
    |> json(%{webhooks: Enum.map(webhooks, &webhook_json/1)})
  end

  # Create a new webhook
  def create(conn, %{"webhook" => webhook_params}) do
    site = conn.assigns.site

    # Check webhook limit
    case Webhooks.webhook_limit_for_site(site.id) do
      {:error, :limit_reached, max: max} ->
        conn
        |> put_status(422)
        |> json(%{error: "Maximum of #{max} webhooks per site exceeded"})

      {:ok, _} ->
        # Handle triggers in webhook_params
        triggers_params = Map.get(webhook_params, "triggers", [])
        webhook_params = Map.put(webhook_params, "site_id", site.id)

        case Webhooks.create_webhook(webhook_params) do
          {:ok, webhook} ->
            # Create triggers if provided
            Enum.each(triggers_params, fn trigger_params ->
              trigger_params = Map.put(trigger_params, "webhook_id", webhook.id)
              Webhooks.create_trigger(trigger_params)
            end)

            webhook = Webhooks.get_webhook!(webhook.id)

            conn
            |> put_status(201)
            |> json(%{webhook: webhook_json(webhook)})

          {:error, changeset} ->
            conn
            |> put_status(422)
            |> json(%{error: format_changeset_error(changeset)})
        end
    end
  end

  # Show a single webhook
  def show(conn, %{"id" => id}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          conn
          |> put_status(200)
          |> json(%{webhook: webhook_json(webhook)})
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # Update a webhook
  def update(conn, %{"id" => id, "webhook" => webhook_params}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          case Webhooks.update_webhook(webhook, webhook_params) do
            {:ok, webhook} ->
              conn
              |> put_status(200)
              |> json(%{webhook: webhook_json(webhook)})

            {:error, changeset} ->
              conn
              |> put_status(422)
              |> json(%{error: format_changeset_error(changeset)})
          end
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # Delete a webhook
  def delete(conn, %{"id" => id}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          Webhooks.delete_webhook(webhook)

          conn
          |> put_status(204)
          |> json(%{})
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # Add a trigger to a webhook
  def add_trigger(conn, %{"id" => id, "trigger" => trigger_params}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          trigger_params = Map.put(trigger_params, "webhook_id", webhook.id)

          case Webhooks.create_trigger(trigger_params) do
            {:ok, trigger} ->
              conn
              |> put_status(201)
              |> json(%{trigger: trigger_json(trigger)})

            {:error, changeset} ->
              conn
              |> put_status(422)
              |> json(%{error: format_changeset_error(changeset)})
          end
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # Remove a trigger from a webhook
  def remove_trigger(conn, %{"id" => id, "trigger_id" => trigger_id}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          # Find the trigger belonging to this webhook
          trigger = Repo.get_by(Trigger, id: trigger_id, webhook_id: webhook.id)

          if trigger do
            Webhooks.delete_trigger(trigger)

            conn
            |> put_status(204)
            |> json(%{})
          else
            conn
            |> put_status(404)
            |> json(%{error: "Trigger not found"})
          end
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # List delivery history for a webhook
  def deliveries(conn, %{"id" => id}) do
    site = conn.assigns.site

    case Webhooks.get_webhook(id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          page = Map.get(conn.params, "page", "1") |> String.to_integer()
          limit = Map.get(conn.params, "limit", "20") |> String.to_integer() |> min(100)

          result = Webhooks.list_deliveries_for_webhook(webhook.id, page: page, limit: limit)

          conn
          |> put_status(200)
          |> json(%{
            deliveries: Enum.map(result.deliveries, &delivery_json/1),
            pagination: result.pagination
          })
        else
          conn
          |> put_status(404)
          |> json(%{error: "Webhook not found"})
        end
    end
  end

  # Private helpers

  defp verify_site(conn, _opts) do
    site_id = conn.params["site_id"]

    case Repo.get_by(Plausible.Site, id: site_id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Site not found"})
        |> halt()

      site ->
        # Check site membership
        case Plausible.Sites.is_member?(conn.assigns.current_user.id, site) do
          true ->
            assign(conn, :site, site)

          false ->
            conn
            |> put_status(403)
            |> json(%{error: "Not authorized"})
            |> halt()
        end
    end
  end

  defp webhook_json(webhook) do
    %{
      id: webhook.id,
      url: webhook.url,
      name: webhook.name,
      active: webhook.active,
      secret: if(webhook.secret, do: false, else: nil),
      triggers: Enum.map(webhook.triggers || [], &trigger_json/1),
      inserted_at: webhook.inserted_at,
      updated_at: webhook.updated_at
    }
  end

  defp trigger_json(trigger) do
    %{
      id: trigger.id,
      type: trigger.type,
      threshold: trigger.threshold,
      goal_id: trigger.goal_id,
      inserted_at: trigger.inserted_at
    }
  end

  defp delivery_json(delivery) do
    %{
      id: delivery.id,
      event_id: delivery.event_id,
      status: delivery.status,
      response_code: delivery.response_code,
      response_body: delivery.response_body,
      error_message: delivery.error_message,
      attempt: delivery.attempt,
      inserted_at: delivery.inserted_at
    }
  end

  defp format_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "#{key}", to_string(value))
      end)
    end)
  end
end
