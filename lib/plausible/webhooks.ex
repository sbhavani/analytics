defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook operations
  """
  use Plausible
  use Plausible.Repo
  require Logger
  alias Plausible.Webhooks.Webhook
  alias Plausible.Webhooks.Delivery

  @spec list_webhooks(Plausible.Site.t()) :: [Webhook.t()]
  def list_webhooks(%Plausible.Site{id: site_id}) do
    Repo.all(
      from w in Webhook,
        where: w.site_id == ^site_id,
        order_by: [desc: :inserted_at]
    )
  end

  @spec get_webhook!(Ecto.UUID.t()) :: Webhook.t()
  def get_webhook!(id) do
    Repo.get!(Webhook, id)
  end

  @spec create_webhook(Plausible.Site.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook(%Plausible.Site{id: site_id}, attrs) do
    %Webhook{site_id: site_id}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, webhook} ->
        Logger.info("Webhook created",
          webhook_id: webhook.id,
          site_id: site_id,
          url: webhook.url,
          trigger_types: webhook.trigger_types
        )
        {:ok, webhook}

      {:error, changeset} ->
        Logger.warning("Failed to create webhook",
          site_id: site_id,
          errors: inspect(changeset.errors)
        )
        {:error, changeset}
    end
  end

  @spec update_webhook(Webhook.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def update_webhook(%Webhook{} = webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_webhook} ->
        Logger.info("Webhook updated",
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          url: updated_webhook.url,
          enabled: updated_webhook.enabled,
          trigger_types: updated_webhook.trigger_types
        )
        {:ok, updated_webhook}

      {:error, changeset} ->
        Logger.warning("Failed to update webhook",
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          errors: inspect(changeset.errors)
        )
        {:error, changeset}
    end
  end

  @spec delete_webhook(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def delete_webhook(%Webhook{} = webhook) do
    Repo.delete(webhook)
    |> case do
      {:ok, deleted_webhook} ->
        Logger.info("Webhook deleted",
          webhook_id: webhook.id,
          site_id: webhook.site_id
        )
        {:ok, deleted_webhook}

      {:error, changeset} ->
        Logger.warning("Failed to delete webhook",
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          errors: inspect(changeset.errors)
        )
        {:error, changeset}
    end
  end

  @spec toggle_webhook(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def toggle_webhook(%Webhook{} = webhook) do
    update_webhook(webhook, %{enabled: not webhook.enabled})
  end

  @spec list_deliveries(Webhook.t(), Keyword.t()) :: [Delivery.t()]
  def list_deliveries(%Webhook{id: webhook_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Repo.all(
      from d in Delivery,
        where: d.webhook_id == ^webhook_id,
        order_by: [desc: :attempted_at],
        limit: ^limit
    )
  end

  @spec create_delivery(Webhook.t(), map()) :: {:ok, Delivery.t()}
  def create_delivery(%Webhook{} = webhook, attrs) do
    %Delivery{webhook_id: webhook.id, attempted_at: NaiveDateTime.utc_now()}
    |> Delivery.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, delivery} ->
        Logger.info("Webhook delivery created",
          delivery_id: delivery.id,
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          event_type: delivery.event_type
        )
        {:ok, delivery}

      {:error, changeset} ->
        Logger.warning("Failed to create webhook delivery",
          webhook_id: webhook.id,
          site_id: webhook.site_id,
          errors: inspect(changeset.errors)
        )
        {:error, changeset}
    end
  end

  @spec get_enabled_webhooks_for_event(Plausible.Site.t(), String.t()) :: [Webhook.t()]
  def get_enabled_webhooks_for_event(%Plausible.Site{id: site_id}, event_type) do
    Repo.all(
      from w in Webhook,
        where: w.site_id == ^site_id,
        where: w.enabled == true,
        where: fragment("? = ANY(?)", ^event_type, w.trigger_types)
    )
  end

  @spec validate_https_url(String.t()) :: :ok | {:error, String.t()}
  def validate_https_url(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when host != "" ->
        :ok

      %URI{scheme: nil} ->
        {:error, "must be a valid URL"}

      %URI{scheme: "http"} ->
        {:error, "must use HTTPS protocol"}

      _ ->
        {:error, "must be a valid HTTPS URL"}
    end
  end
end
