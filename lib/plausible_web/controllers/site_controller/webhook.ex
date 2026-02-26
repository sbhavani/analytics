defmodule PlausibleWeb.SiteController.Webhook do
  @moduledoc """
  Controller for webhook settings
  """
  use PlausibleWeb, :controller
  use Plausible.Repo
  use Plausible

  alias Plausible.Sites
  alias Plausible.WebhookNotifications

  plug(PlausibleWeb.RequireAccountPlug)

  plug(
    PlausibleWeb.Plugs.AuthorizeSiteAccess,
    [:owner, :admin, :super_admin]
  )

  def index(conn, %{"domain" => domain}) do
    site = Sites.get_by_domain(domain)
    webhooks = WebhookNotifications.list_webhooks(site)

    render(conn, "webhook/index.html",
      site: site,
      webhooks: webhooks
    )
  end

  def new(conn, %{"domain" => domain}) do
    site = Sites.get_by_domain(domain)

    render(conn, "webhook/new.html",
      site: site,
      changeset: WebhookNotifications.WebhookConfig.changeset(%WebhookNotifications.WebhookConfig{}, %{})
    )
  end

  def create(conn, %{"domain" => domain, "webhook" => webhook_params}) do
    site = Sites.get_by_domain(domain)

    # Generate secret if not provided
    webhook_params =
      Map.put_new(webhook_params, "secret", WebhookNotifications.generate_secret())

    case WebhookNotifications.create_webhook(site, webhook_params) do
      {:ok, _webhook} ->
        conn
        |> put_flash(:success, "Webhook created successfully")
        |> redirect(to: "/#{site.domain}/settings/webhooks")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to create webhook")
        |> render("webhook/new.html", site: site, changeset: changeset)
    end
  end

  def edit(conn, %{"domain" => domain, "id" => id}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    render(conn, "webhook/edit.html",
      site: site,
      webhook: webhook,
      changeset: WebhookNotifications.WebhookConfig.changeset(webhook, %{})
    )
  end

  def update(conn, %{"domain" => domain, "id" => id, "webhook" => webhook_params}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    # Handle secret separately - don't update if empty
    webhook_params =
      case webhook_params do
        %{"secret" => ""} -> Map.delete(webhook_params, "secret")
        _ -> webhook_params
      end

    case WebhookNotifications.update_webhook(webhook, webhook_params) do
      {:ok, _webhook} ->
        conn
        |> put_flash(:success, "Webhook updated successfully")
        |> redirect(to: "/#{site.domain}/settings/webhooks")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Failed to update webhook")
        |> render("webhook/edit.html", site: site, webhook: webhook, changeset: changeset)
    end
  end

  def delete(conn, %{"domain" => domain, "id" => id}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    case WebhookNotifications.delete_webhook(webhook) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Webhook deleted successfully")
        |> redirect(to: "/#{site.domain}/settings/webhooks")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to delete webhook")
        |> redirect(to: "/#{site.domain}/settings/webhooks")
    end
  end

  def test(conn, %{"domain" => domain, "id" => id}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    case WebhookNotifications.test_webhook(webhook) do
      {:ok, _log, _payload} ->
        conn
        |> put_flash(:success, "Test webhook sent successfully")
        |> redirect(to: "/#{site.domain}/settings/webhooks")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to send test webhook")
        |> redirect(to: "/#{site.domain}/settings/webhooks")
    end
  end

  def deliveries(conn, %{"domain" => domain, "id" => id}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    page = String.to_integer(conn.params["page"] || "1")
    status = conn.params["status"] || "all"

    result = WebhookNotifications.list_deliveries(webhook, %{
      page: page,
      limit: 20,
      status: status
    })

    render(conn, "webhook/deliveries.html",
      site: site,
      webhook: webhook,
      deliveries: result.deliveries,
      page: result.page,
      total_pages: result.total_pages,
      total: result.total,
      status: status
    )
  end

  def retry_delivery(conn, %{"domain" => domain, "id" => id, "delivery_id" => delivery_id}) do
    site = Sites.get_by_domain(domain)
    webhook = WebhookNotifications.get_webhook!(site, id)

    delivery =
      Plausible.WebhookNotifications.DeliveryLog
      |> Plausible.Repo.get!(delivery_id)

    # Update to pending and increment attempt number
    WebhookNotifications.update_delivery_log(delivery, %{
      status: "pending",
      attempt_number: delivery.attempt_number + 1
    })

    # Queue the delivery worker
    %{delivery_log_id: delivery.id}
    |> Plausible.Workers.WebhookDeliveryWorker.new()
    |> Oban.insert!()

    conn
    |> put_flash(:success, "Delivery queued for retry")
    |> redirect(to: "/#{site.domain}/settings/webhooks/#{webhook.id}/deliveries")
  end
end
