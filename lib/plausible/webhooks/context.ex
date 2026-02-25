defmodule Plausible.Webhooks.Context do
  @moduledoc """
  Context module for webhook CRUD operations.
  """
  import Ecto.Query

  alias Plausible.Repo
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery
  alias Plausible.Workers.DeliverWebhook

  @valid_triggers ["goal_completion", "visitor_spike"]

  def list_webhooks(site_id) do
    Webhook
    |> Webhook.for_site(site_id)
    |> Repo.all()
  end

  def get_webhook!(webhook_id, site_id) do
    Webhook
    |> Webhook.for_site(site_id)
    |> Repo.get!(webhook_id)
  end

  def create_webhook(site_id, attrs) do
    attrs = Map.put(attrs, :site_id, site_id)

    %Webhook{}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  def update_webhook(webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  def delete_webhook(webhook) do
    webhook
    |> Ecto.Changeset.change(%{deleted_at: NaiveDateTime.utc_now()})
    |> Repo.update()
  end

  def toggle_webhook(webhook) do
    new_enabled = !webhook.enabled

    webhook
    |> Ecto.Changeset.change(%{enabled: new_enabled})
    |> Repo.update()
  end

  def get_enabled_webhooks_for_trigger(site_id, trigger) do
    Webhook
    |> Webhook.for_site(site_id)
    |> where([w], w.enabled == true)
    |> where([w], ^trigger in w.triggers)
    |> Repo.all()
  end

  def create_delivery(webhook, event_type, payload) do
    %Delivery{}
    |> Delivery.changeset(%{
      webhook_configuration_id: webhook.id,
      event_type: event_type,
      payload: payload,
      status: "pending"
    })
    |> Repo.insert()
  end

  def list_deliveries(webhook_id, page \\ 1, per_page \\ 20) do
    Delivery
    |> Delivery.for_webhook(webhook_id)
    |> Repo.paginate(page: page, per_page: per_page)
  end

  def queue_delivery(delivery) do
    DeliverWebhook.new(%{delivery_id: delivery.id})
    |> Oban.insert()
  end

  def valid_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and host != "" ->
        String.length(url) <= 2048

      _ ->
        false
    end
  end

  def valid_secret?(secret) do
    String.length(secret) >= 16
  end

  def valid_triggers?(triggers) do
    Enum.all?(triggers, fn t -> t in @valid_triggers end) and length(triggers) > 0
  end

  def valid_threshold?(threshold) when is_integer(threshold) and threshold > 0 do
    threshold <= 500
  end

  def valid_threshold?(_), do: false

  def valid_trigger?(trigger), do: trigger in @valid_triggers

  def valid_triggers, do: @valid_triggers
end
