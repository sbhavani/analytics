defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook operations
  """
  alias Plausible.Repo
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.WebhookDelivery

  @max_webhooks_per_site 10

  def create_webhook(site, attrs) do
    with :ok <- check_webhook_limit(site.id) do
      changeset = Webhook.changeset(%Webhook{}, Map.put(attrs, :site_id, site.id))
      Repo.insert(changeset)
    end
  end

  def get_webhook(webhook_id) do
    Repo.get(Webhook, webhook_id)
  end

  def get_webhook!(webhook_id) do
    Repo.get!(Webhook, webhook_id)
  end

  def list_webhooks_for_site(site_id) do
    Webhook
    |> Webhook.for_site(site_id)
    |> Repo.all()
  end

  def update_webhook(webhook, attrs) do
    changeset = Webhook.update_changeset(webhook, attrs)
    Repo.update(changeset)
  end

  def delete_webhook(webhook) do
    Repo.delete(webhook)
  end

  def get_webhooks_for_trigger(site_id, trigger) do
    Webhook
    |> Webhook.for_site(site_id)
    |> Webhook.active()
    |> Webhook.with_trigger(trigger)
    |> Repo.all()
  end

  def create_delivery(webhook, event_type, payload) do
    delivery = %WebhookDelivery{
      webhook_id: webhook.id,
      event_type: event_type,
      payload: payload,
      status: :pending
    }

    Repo.insert(delivery)
  end

  def update_delivery_status(delivery, status, response_code \\ nil, response_body \\ nil) do
    attrs = %{
      status: status,
      response_code: response_code,
      response_body: String.slice(response_body || "", 0, 1000)
    }

    delivery
    |> Ecto.Changeset.change(attrs)
    |> Repo.update()
  end

  def increment_retry_count(delivery) do
    delivery
    |> Ecto.Changeset.change(update: [retry_count: delivery.retry_count + 1])
    |> Repo.update()
  end

  def check_webhook_limit(site_id) do
    count = Webhook |> Webhook.for_site(site_id) |> Repo.aggregate(:count)

    if count >= @max_webhooks_per_site do
      {:error, :webhook_limit_reached}
    else
      :ok
    end
  end

  def webhook_limit, do: @max_webhooks_per_site

  def get_site_with_webhook(webhook_id, site_id) do
    Webhook
    |> where(id: ^webhook_id, site_id: ^site_id)
    |> Repo.one()
  end
end
