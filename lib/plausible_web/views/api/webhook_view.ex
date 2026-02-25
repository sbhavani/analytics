defmodule PlausibleWeb.Api.WebhookView do
  use PlausibleWeb, :view
  alias PlausibleWeb.Api.WebhookView

  def render("index.json", %{webhooks: webhooks}) do
    %{webhooks: render_many(webhooks, WebhookView, "webhook.json")}
  end

  def render("show.json", %{webhook: webhook}) do
    %{webhook: render_one(webhook, WebhookView, "webhook.json")}
  end

  def render("webhook.json", %{webhook: webhook}) do
    %{
      id: webhook.id,
      url: webhook.url,
      enabled: webhook.enabled,
      triggers: webhook.triggers,
      thresholds: webhook.thresholds || %{},
      created_at: webhook.inserted_at
    }
  end

  def render("deliveries.json", %{deliveries: deliveries}) do
    %{
      deliveries: render_many(deliveries.entries, WebhookView, "delivery.json"),
      pagination: %{
        page: deliveries.page_number,
        per_page: deliveries.page_size,
        total: deliveries.total_entries
      }
    }
  end

  def render("delivery.json", %{delivery: delivery}) do
    %{
      id: delivery.id,
      event_type: delivery.event_type,
      status: delivery.status,
      response_code: delivery.response_code,
      error_message: delivery.error_message,
      attempt_number: delivery.attempt_number,
      timestamp: delivery.inserted_at
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      error: "Validation failed",
      details: traverse_errors(changeset)
    }
  end

  defp traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
