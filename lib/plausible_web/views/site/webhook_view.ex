defmodule PlausibleWeb.Site.WebhookView do
  use PlausibleWeb, :view

  def render("index.json", %{webhooks: webhooks}) do
    %{webhooks: render_many(webhooks, __MODULE__, "webhook.json", as: :webhook)}
  end

  def render("show.json", %{webhook: webhook}) do
    %{webhook: render_one(webhook, __MODULE__, "webhook.json", as: :webhook)}
  end

  def render("webhook.json", %{webhook: webhook}) do
    %{
      id: webhook.id,
      url: webhook.url,
      name: webhook.name,
      enabled: webhook.enabled,
      triggers: render_many(webhook.triggers, __MODULE__, "trigger.json", as: :trigger)
    }
  end

  def render("trigger.json", %{trigger: trigger}) do
    %{
      id: trigger.id,
      type: trigger.trigger_type,
      threshold: trigger.threshold,
      goal_id: trigger.goal_id,
      enabled: trigger.enabled
    }
  end

  def render("deliveries.json", %{deliveries: deliveries}) do
    %{deliveries: render_many(deliveries, __MODULE__, "delivery.json", as: :delivery)}
  end

  def render("delivery.json", %{delivery: delivery}) do
    base = %{
      id: delivery.id,
      event_type: delivery.event_type,
      status_code: delivery.status_code,
      attempt_number: delivery.attempt_number,
      error_message: delivery.error_message,
      inserted_at: delivery.inserted_at
    }

    if Map.has_key?(delivery, :payload) do
      Map.merge(base, %{
        payload: delivery.payload,
        response_body: delivery.response_body,
        trigger_id: delivery.trigger_id
      })
    else
      base
    end
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end
end
