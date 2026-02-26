defmodule PlausibleWeb.Api.WebhookView do
  use PlausibleWeb, :view

  def render("index.json", %{webhooks: webhooks}) do
    %{webhooks: render_many(webhooks, __MODULE__, "webhook.json")}
  end

  def render("webhook.json", %{webhook: webhook}) do
    %{
      id: webhook.id,
      url: webhook.url,
      name: webhook.name,
      triggers: webhook.triggers,
      active: webhook.active,
      inserted_at: webhook.inserted_at,
      updated_at: webhook.updated_at
    }
  end

  def render("show.json", %{webhook: webhook}) do
    render(__MODULE__, "webhook.json", webhook: webhook)
  end

  def render("created.json", %{webhook: webhook}) do
    render(__MODULE__, "webhook.json", webhook: webhook)
  end

  def render("updated.json", %{webhook: webhook}) do
    render(__MODULE__, "webhook.json", webhook: webhook)
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("ping.json", %{status: status, timestamp: timestamp}) do
    %{
      status: status,
      timestamp: timestamp
    }
  end
end
