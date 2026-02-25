defmodule PlausibleWeb.Api.WebhookController do
  @moduledoc """
  API controller for webhook configuration and delivery.
  """
  use PlausibleWeb, :controller
  use Plausible.Repo
  use PlausibleWeb.Plugs.ErrorHandler

  alias Plausible.Webhooks.Context
  alias Plausible.Webhooks.Triggers
  alias Plausible.Site

  plug(
    PlausibleWeb.Plugs.AuthorizeSiteAccess,
    [:owner, :admin, :super_admin]
  )

  def index(conn, _params) do
    site = conn.assigns.site
    webhooks = Context.list_webhooks(site.id)

    conn
    |> put_status(200)
    |> render("index.json", webhooks: webhooks)
  end

  def create(conn, %{"webhook" => webhook_params}) do
    site = conn.assigns.site

    case Context.create_webhook(site.id, webhook_params) do
      {:ok, webhook} ->
        conn
        |> put_status(201)
        |> render("show.json", webhook: webhook)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render("error.json", changeset: changeset)
    end
  end

  def update(conn, %{"id" => webhook_id, "webhook" => webhook_params}) do
    site = conn.assigns.site

    webhook = Context.get_webhook!(webhook_id, site.id)

    case Context.update_webhook(webhook, webhook_params) do
      {:ok, webhook} ->
        conn
        |> put_status(200)
        |> render("show.json", webhook: webhook)

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render("error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => webhook_id}) do
    site = conn.assigns.site

    webhook = Context.get_webhook!(webhook_id, site.id)

    case Context.delete_webhook(webhook) do
      {:ok, _webhook} ->
        conn
        |> put_status(204)
        |> text("")

      {:error, _changeset} ->
        conn
        |> put_status(422)
        |> json(%{error: "Failed to delete webhook"})
    end
  end

  def deliveries(conn, %{"id" => webhook_id}) do
    site = conn.assigns.site

    _webhook = Context.get_webhook!(webhook_id, site.id)

    page = String.to_integer(conn.params["page"] || "1")
    per_page = String.to_integer(conn.params["per_page"] || "20")

    deliveries = Context.list_deliveries(webhook_id, page, per_page)

    conn
    |> put_status(200)
    |> render("deliveries.json", deliveries: deliveries)
  end
end
