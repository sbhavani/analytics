defmodule PlausibleWeb.Api.WebhookController do
  use PlausibleWeb, :controller
  use Plausible.Repo
  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.WebhookNotifier

  plug :authorize_site_access when action in [:index, :create, :show, :update, :delete, :ping]

  def index(conn, %{"site_id" => _site_id}) do
    site = conn.assigns[:site]
    webhooks = Webhooks.list_webhooks_for_site(site.id)

    conn
    |> put_status(200)
    |> render("index.json", webhooks: webhooks)
  end

  def create(conn, %{"site_id" => _site_id, "url" => url, "triggers" => triggers} = params) do
    site = conn.assigns[:site]

    attrs = %{
      url: url,
      triggers: triggers,
      name: params["name"],
      secret: params["secret"]
    }

    case Webhooks.create_webhook(site, attrs) do
      {:ok, webhook} ->
        conn
        |> put_status(201)
        |> json(webhook)

      {:error, :webhook_limit_reached} ->
        conn
        |> put_status(422)
        |> json(%{error: "Maximum number of webhooks (#{Webhooks.webhook_limit()}) reached for this site"})

      {:error, changeset} ->
        errors = changeset_errors(changeset)
        conn
        |> put_status(422)
        |> json(%{error: errors})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(422)
    |> json(%{error: "Missing required fields: url, triggers"})
  end

  def show(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id}) do
    site = conn.assigns[:site]

    case Webhooks.get_site_with_webhook(webhook_id, site.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        conn
        |> put_status(200)
        |> json(webhook)
    end
  end

  def update(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id} = params) do
    site = conn.assigns[:site]

    case Webhooks.get_site_with_webhook(webhook_id, site.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        attrs = Map.reject(params, fn {k, _v} -> k in ["site_id", "webhook_id"] end)

        case Webhooks.update_webhook(webhook, attrs) do
          {:ok, updated_webhook} ->
            conn
            |> put_status(200)
            |> json(updated_webhook)

          {:error, changeset} ->
            errors = changeset_errors(changeset)
            conn
            |> put_status(422)
            |> json(%{error: errors})
        end
    end
  end

  def delete(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id}) do
    site = conn.assigns[:site]

    case Webhooks.get_site_with_webhook(webhook_id, site.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        {:ok, _} = Webhooks.delete_webhook(webhook)

        conn
        |> put_status(204)
        |> text("")
    end
  end

  def ping(conn, %{"site_id" => _site_id, "webhook_id" => webhook_id}) do
    site = conn.assigns[:site]

    case Webhooks.get_site_with_webhook(webhook_id, site.id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Webhook not found"})

      webhook ->
        case WebhookNotifier.deliver_test(webhook) do
          {:ok, _} ->
            conn
            |> put_status(200)
            |> json(%{status: "delivered", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})

          {:retrying, _} ->
            conn
            |> put_status(200)
            |> json(%{status: "retrying", message: "Delivery attempted", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})

          {:error, reason} ->
            conn
            |> put_status(500)
            |> json(%{status: "failed", error: inspect(reason)})
        end
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
    |> Enum.join(", ")
  end
end
