defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook operations.
  """
  import Ecto.Query
  require Logger
  alias Plausible.Repo
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Trigger
  alias Plausible.Webhooks.Delivery

  @max_webhooks_per_site 10

  # Webhook CRUD operations

  def list_webhooks_for_site(site_id) do
    Webhook
    |> where([w], w.site_id == ^site_id)
    |> order_by([w], asc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:triggers)
  end

  def get_webhook!(id) do
    Webhook
    |> Repo.get!(id)
    |> Repo.preload(:triggers)
  end

  def get_webhook(id) do
    Webhook
    |> Repo.get(id)
    |> Repo.preload(:triggers)
  end

  def create_webhook(attrs) do
    %Webhook{}
    |> Webhook.create_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, webhook} ->
        Logger.info("Webhook created",
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          url: webhook.url,
          active: webhook.active
        )
        {:ok, webhook}

      {:error, changeset} ->
        Logger.warning("Failed to create webhook",
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def update_webhook(%Webhook{} = webhook, attrs) do
    webhook
    |> Webhook.update_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_webhook} ->
        Logger.info("Webhook updated",
          webhook_id: updated_webhook.id,
          site_id: updated_webhook.site_id,
          active: updated_webhook.active
        )
        {:ok, updated_webhook}

      {:error, changeset} ->
        Logger.warning("Failed to update webhook",
          webhook_id: webhook.id,
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def delete_webhook(%Webhook{} = webhook) do
    webhook_id = webhook.id
    site_id = webhook.site_id

    Repo.delete(webhook)
    |> case do
      {:ok, _} ->
        Logger.info("Webhook deleted",
          webhook_id: webhook_id,
          site_id: site_id
        )
        {:ok, webhook}

      {:error, changeset} ->
        Logger.warning("Failed to delete webhook",
          webhook_id: webhook_id,
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def pause_webhook(%Webhook{} = webhook) do
    update_webhook(webhook, %{active: false})
  end

  def resume_webhook(%Webhook{} = webhook) do
    update_webhook(webhook, %{active: true})
  end

  # Trigger CRUD operations

  def create_trigger(attrs) do
    %Trigger{}
    |> Trigger.create_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, trigger} ->
        Logger.info("Trigger created",
          trigger_id: trigger.id,
          webhook_id: trigger.webhook_id,
          type: trigger.type
        )
        {:ok, trigger}

      {:error, changeset} ->
        Logger.warning("Failed to create trigger",
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def delete_trigger(%Trigger{} = trigger) do
    trigger_id = trigger.id
    webhook_id = trigger.webhook_id

    Repo.delete(trigger)
    |> case do
      {:ok, _} ->
        Logger.info("Trigger deleted",
          trigger_id: trigger_id,
          webhook_id: webhook_id
        )
        {:ok, trigger}

      {:error, changeset} ->
        Logger.warning("Failed to delete trigger",
          trigger_id: trigger_id,
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def list_triggers_for_webhook(webhook_id) do
    Trigger
    |> where([t], t.webhook_id == ^webhook_id)
    |> Repo.all()
  end

  # Delivery operations

  def list_deliveries_for_webhook(webhook_id, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    limit = Keyword.get(opts, :limit, 20)

    query =
      Delivery
      |> where([d], d.webhook_id == ^webhook_id)
      |> order_by([d], desc: :inserted_at)

    total_count = Repo.aggregate(query, :count, :id)

    deliveries =
      query
      |> offset(^((page - 1) * limit))
      |> limit(^limit)
      |> Repo.all()

    %{
      deliveries: deliveries,
      pagination: %{
        page: page,
        limit: limit,
        total_pages: ceil(total_count / limit),
        total_count: total_count
      }
    }
  end

  def create_delivery(attrs) do
    %Delivery{}
    |> Delivery.create_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, delivery} ->
        Logger.info("Delivery created - webhook queued",
          delivery_id: delivery.id,
          webhook_id: delivery.webhook_id,
          trigger_type: delivery.trigger_type,
          event_id: delivery.event_id
        )
        {:ok, delivery}

      {:error, changeset} ->
        Logger.warning("Failed to create delivery record",
          errors: changeset.errors
        )
        {:error, changeset}
    end
  end

  def update_delivery(%Delivery{} = delivery, attrs) do
    delivery
    |> Delivery.create_changeset(attrs)
    |> Repo.update()
  end

  def get_delivery_by_event_id(webhook_id, event_id) do
    Delivery
    |> where([d], d.webhook_id == ^webhook_id and d.event_id == ^event_id)
    |> Repo.one()
  end

  # Validation helpers

  def validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when host != nil ->
        {:ok, url}

      %URI{scheme: "http"} ->
        {:error, "must use HTTPS protocol"}

      _ ->
        {:error, "must be a valid URL"}
    end
  end

  def webhook_limit_for_site(site_id) do
    count = Webhook |> where([w], w.site_id == ^site_id) |> Repo.aggregate(:count, :id)

    if count >= @max_webhooks_per_site do
      {:error, :limit_reached, max: @max_webhooks_per_site}
    else
      {:ok, count}
    end
  end

  def webhooks_enabled_for_site?(site_id) do
    case webhook_limit_for_site(site_id) do
      {:ok, _} -> true
      {:error, _, _} -> false
    end
  end

  # Deduplication

  def delivery_exists?(webhook_id, event_id) do
    get_delivery_by_event_id(webhook_id, event_id) != nil
  end
end
