defmodule PlausibleWeb.Api.WebhookController do
  @moduledoc """
  API controller for webhook management
  """
  use Plausible
  use PlausibleWeb, :controller
  use Plausible.Repo
  use PlausibleWeb.Plugs.ErrorHandler
  require Logger

  alias Plausible.Webhooks
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery
  alias Plausible.Site

  action_fallback(PlausibleWeb.Api.FallbackController)

  plug(:authorize_site_owner when action in [:index, :show, :create, :update, :delete, :test, :deliveries])

  def index(conn, %{"domain" => domain}) do
    site = conn.assigns[:site]
    webhooks = Webhooks.list_webhooks(site)

    json(conn, %{
      webhooks: Enum.map(webhooks, &webhook_to_json/1)
    })
  end

  def show(conn, %{"id" => id}) do
    site = conn.assigns[:site]

    case Webhooks.get_webhook!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          json(conn, webhook_to_json(webhook))
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        end
    end
  end

  def create(conn, %{"domain" => _domain, "webhook" => webhook_params}) do
    site = conn.assigns[:site]

    case Webhooks.create_webhook(site, webhook_params) do
      {:ok, webhook} ->
        conn
        |> put_status(:created)
        |> json(webhook_to_json(webhook))

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: format_changeset_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id, "webhook" => webhook_params}) do
    site = conn.assigns[:site]

    case Webhooks.get_webhook!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          case Webhooks.update_webhook(webhook, webhook_params) do
            {:ok, webhook} ->
              json(conn, webhook_to_json(webhook))

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: format_changeset_errors(changeset)})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    site = conn.assigns[:site]

    case Webhooks.get_webhook!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          case Webhooks.delete_webhook(webhook) do
            {:ok, _webhook} ->
              conn
              |> put_status(:no_content)
              |> text("")

            {:error, _changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to delete webhook"})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        end
    end
  end

  def test(conn, %{"id" => id}) do
    site = conn.assigns[:site]

    case Webhooks.get_webhook!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          test_webhook(conn, webhook, site)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        end
    end
  end

  defp test_webhook(conn, webhook, site) do
    payload = Plausible.Webhooks.Payload.build_test_payload(site)

    Logger.info("Test webhook requested",
      webhook_id: webhook.id,
      site_id: site.id,
      url: webhook.url
    )

    headers = [
      {"content-type", "application/json"},
      {"x-webhook-event", "test"},
      {"x-webhook-site-id", site.id},
      {"user-agent", "Plausible-Analytics-Webhook/1.0"}
    ]

    case Plausible.HTTPClient.post(webhook.url, headers, payload, timeout: 10_000) do
      {:ok, %{status: status}} when status >= 200 and status < 300 ->
        Logger.info("Test webhook delivered successfully",
          webhook_id: webhook.id,
          site_id: site.id,
          response_code: status
        )

        conn
        |> put_status(:ok)
        |> json(%{status: "success", message: "Test webhook delivered successfully"})

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body)

        Logger.warning("Test webhook failed with non-2xx status",
          webhook_id: webhook.id,
          site_id: site.id,
          response_code: status,
          error_message: error_message
        )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "failed", message: "Webhook returned status #{status}: #{error_message}"})

      {:error, reason} ->
        error_message = format_error(reason)

        Logger.error("Test webhook failed with error",
          webhook_id: webhook.id,
          site_id: site.id,
          error: error_message
        )

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "failed", message: "Failed to deliver webhook: #{error_message}"})
    end
  end

  def deliveries(conn, %{"id" => id}) do
    site = conn.assigns[:site]

    case Webhooks.get_webhook!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Webhook not found"})

      webhook ->
        if webhook.site_id == site.id do
          deliveries = Webhooks.list_deliveries(webhook)

          json(conn, %{
            deliveries: Enum.map(deliveries, &delivery_to_json/1)
          })
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        end
    end
  end

  defp webhook_to_json(webhook) do
    %{
      id: webhook.id,
      url: webhook.url,
      enabled: webhook.enabled,
      trigger_types: webhook.trigger_types,
      site_id: webhook.site_id,
      created_at: webhook.inserted_at,
      updated_at: webhook.updated_at
    }
  end

  defp delivery_to_json(delivery) do
    %{
      id: delivery.id,
      event_type: delivery.event_type,
      payload: delivery.payload,
      status: delivery.status,
      response_code: delivery.response_code,
      error_message: delivery.error_message,
      attempted_at: delivery.attempted_at,
      completed_at: delivery.completed_at
    }
  end

  defp extract_error_message(body) when is_map(body) do
    case Jason.encode(body) do
      {:ok, json} -> json
      _ -> inspect(body)
    end
  end

  defp extract_error_message(_), do: "Unknown error"

  defp format_error(reason) when is_atom(reason) do
    Atom.to_string(reason)
  end

  defp format_error(reason) when is_exception(reason) do
    Exception.message(reason)
  end

  defp format_error(reason) do
    inspect(reason)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp authorize_site_owner(conn, _opts) do
    case conn.params do
      %{"domain" => domain} ->
        site = Repo.get_by(Site, domain: domain) |> Repo.preload(:team)

        if site && Plausible.Sites.is_owner?(conn.assigns[:current_user], site) do
          assign(conn, :site, site)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
          |> halt()
        end

      _ ->
        conn
    end
  end
end
