defmodule PlausibleWeb.Site.WebhookController do
  use PlausibleWeb, :controller
  use Plausible.Repo
  use Plausible

  alias Plausible.Site

  plug(PlausibleWeb.RequireAccountPlug)

  plug(
    PlausibleWeb.Plugs.AuthorizeSiteAccess,
    [:owner, :admin, :editor, :super_admin]
  )

  def index(conn, %{"site_id" => site_id}) do
    site = Site.get(site_id) |> Repo.preload([:webhooks])

    webhooks = Site.list_webhooks(site)

    render(conn, "index.json", webhooks: webhooks)
  end

  def create(conn, %{"site_id" => site_id, "webhook" => webhook_params}) do
    site = Site.get(site_id) |> Repo.preload([:webhooks])

    case Site.create_webhook(site, webhook_params) do
      {:ok, webhook} ->
        webhook = webhook |> Repo.preload(:triggers)
        conn
        |> put_status(:created)
        |> render("show.json", webhook: webhook)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"site_id" => _site_id, "id" => webhook_id}) do
    webhook = Site.get_webhook(webhook_id)

    case Site.delete_webhook(webhook) do
      {:ok, _webhook} ->
        conn
        |> put_status(:no_content)
        |> text("")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def toggle(conn, %{"site_id" => _site_id, "id" => webhook_id}) do
    webhook = Site.get_webhook(webhook_id)

    case Site.toggle_webhook_enabled(webhook) do
      {:ok, webhook} ->
        webhook = webhook |> Repo.preload(:triggers)
        render(conn, "show.json", webhook: webhook)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def create_trigger(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id, "trigger" => trigger_params}) do
    webhook = Site.get_webhook(webhook_id)

    case Site.create_webhook_trigger(webhook, trigger_params) do
      {:ok, trigger} ->
        conn
        |> put_status(:created)
        |> render("trigger.json", trigger: trigger)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete_trigger(conn, %{"site_id" => _site_id, "webhook_id" => _webhook_id, "id" => trigger_id}) do
    trigger = Repo.get(Site.WebhookTrigger, trigger_id)

    case Site.delete_webhook_trigger(trigger) do
      {:ok, _trigger} ->
        conn
        |> put_status(:no_content)
        |> text("")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def toggle_trigger(conn, %{"site_id" => _site_id, "webhook_id" => _webhook_id, "id" => trigger_id}) do
    trigger = Repo.get(Site.WebhookTrigger, trigger_id)

    case Site.toggle_webhook_trigger_enabled(trigger) do
      {:ok, trigger} ->
        render(conn, "trigger.json", trigger: trigger)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def update_trigger(conn, %{"site_id" => _site_id, "webhook_id" => _webhook_id, "id" => trigger_id, "trigger" => trigger_params}) do
    trigger = Repo.get(Site.WebhookTrigger, trigger_id)

    case Site.update_webhook_trigger(trigger, trigger_params) do
      {:ok, trigger} ->
        render(conn, "trigger.json", trigger: trigger)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("error.json", changeset: changeset)
    end
  end

  def deliveries(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id}) do
    webhook = Site.get_webhook(webhook_id)
    filters = conn.params |> Map.take(["status", "from_date", "to_date"])

    deliveries = Site.list_webhook_deliveries(webhook, filters)

    render(conn, "deliveries.json", deliveries: deliveries)
  end

  def delivery(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id, "id" => delivery_id}) do
    delivery = Site.get_webhook_delivery(webhook_id, delivery_id)

    if delivery do
      render(conn, "delivery.json", delivery: delivery)
    else
      conn
      |> put_status(:not_found)
      |> render("error.json", changeset: %{})
    end
  end
end
