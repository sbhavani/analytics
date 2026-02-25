defmodule Plausible.Webhook do
  @moduledoc """
  Context module for webhook operations.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Site.Webhook
  alias Plausible.Site.WebhookTrigger
  alias Plausible.Site.WebhookDelivery

  @max_retry_attempts 3
  @retry_delays [1, 2, 4] # seconds

  # CRUD Operations

  @spec list_webhooks_for_site(Plausible.Site.t()) :: [Webhook.t()]
  def list_webhooks_for_site(site) do
    Repo.all(
      from w in Webhook,
        where: w.site_id == ^site.id,
        preload: [:triggers]
    )
  end

  @spec get_webhook(Plausible.Site.t(), String.t()) :: Webhook.t() | nil
  def get_webhook(site, webhook_id) do
    Repo.get_by(Webhook, site_id: site.id, id: webhook_id)
    |> Repo.preload(:triggers)
  end

  @spec create_webhook(Plausible.Site.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook(site, attrs \\ %{}) do
    site
    |> Ecto.build_assoc(:webhooks)
    |> Webhook.create_changeset(attrs)
    |> Repo.insert()
  end

  @spec update_webhook(Webhook.t(), map()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def update_webhook(webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_webhook(Webhook.t()) :: {:ok, Webhook.t()} | {:error, Ecto.Changeset.t()}
  def delete_webhook(webhook) do
    Repo.delete(webhook)
  end

  # Trigger Operations

  @spec add_trigger(Webhook.t(), map()) :: {:ok, WebhookTrigger.t()} | {:error, Ecto.Changeset.t()}
  def add_trigger(webhook, attrs \\ %{}) do
    webhook
    |> Ecto.build_assoc(:triggers)
    |> WebhookTrigger.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_trigger(WebhookTrigger.t(), map()) :: {:ok, WebhookTrigger.t()} | {:error, Ecto.Changeset.t()}
  def update_trigger(trigger, attrs) do
    trigger
    |> WebhookTrigger.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_trigger(WebhookTrigger.t()) :: {:ok, WebhookTrigger.t()} | {:error, Ecto.Changeset.t()}
  def delete_trigger(trigger) do
    Repo.delete(trigger)
  end

  @spec get_enabled_triggers_for_site(Plausible.Site.t()) :: [WebhookTrigger.t()]
  def get_enabled_triggers_for_site(site) do
    Repo.all(
      from t in WebhookTrigger,
        join: w in assoc(t, :webhook),
        where: w.site_id == ^site.id,
        where: w.enabled == true,
        where: t.enabled == true,
        preload: [webhook: w]
    )
  end

  # Delivery Operations

  @spec create_delivery(Webhook.t(), map()) :: {:ok, WebhookDelivery.t()} | {:error, Ecto.Changeset.t()}
  def create_delivery(webhook, attrs) do
    webhook
    |> Ecto.build_assoc(:deliveries)
    |> WebhookDelivery.changeset(attrs)
    |> Repo.insert()
  end

  @spec list_deliveries(Webhook.t(), integer()) :: [WebhookDelivery.t()]
  def list_deliveries(webhook, limit \\ 50) do
    Repo.all(
      from d in WebhookDelivery,
        where: d.webhook_id == ^webhook.id,
        order_by: [desc: :inserted_at],
        limit: ^limit
    )
  end

  # Payload Generation

  @spec build_goal_completion_payload(Plausible.Site.t(), map()) :: map()
  def build_goal_completion_payload(site, event_data) do
    %{
      event: "goal_completion",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        goal_id: event_data.goal_id,
        goal_name: event_data.goal_name,
        visitor_id: event_data.visitor_id,
        visitor_country: event_data.visitor_country,
        visitor_referrer: event_data.visitor_referrer,
        pathname: event_data.pathname,
        properties: event_data.properties
      }
    }
  end

  @spec build_visitor_spike_payload(Plausible.Site.t(), map()) :: map()
  def build_visitor_spike_payload(site, spike_data) do
    %{
      event: "visitor_spike",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        current_visitors: spike_data.current_visitors,
        previous_visitors: spike_data.previous_visitors,
        threshold: spike_data.threshold,
        percentage_increase: spike_data.percentage_increase,
        sources: spike_data.sources,
        top_pages: spike_data.top_pages
      }
    }
  end

  @spec build_test_payload(Plausible.Site.t(), Webhook.t()) :: map()
  def build_test_payload(site, webhook) do
    %{
      event: "test",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        message: "This is a test webhook from Plausible Analytics",
        webhook_id: webhook.id
      }
    }
  end

  # Signature Generation

  @spec generate_signature(String.t(), map()) :: String.t()
  def generate_signature(secret, payload) do
    payload_json = Jason.encode!(payload)
    :crypto.mac(:hmac, :sha256, secret, payload_json)
    |> Base.encode16(case: :lower)
  end

  # Queue for delivery

  @spec queue_delivery(Webhook.t(), String.t(), map()) :: {:ok, WebhookDelivery.t()}
  def queue_delivery(webhook, trigger_type, payload) do
    delivery_attrs = %{
      trigger_type: trigger_type,
      payload: payload,
      status: "pending"
    }

    case create_delivery(webhook, delivery_attrs) do
      {:ok, delivery} ->
        Plausible.Workers.DeliverWebhook.enqueue(delivery.id)
        {:ok, delivery}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Trigger functions - called when events occur

  @spec trigger_goal_completion(Plausible.Site.t(), map()) :: :ok
  def trigger_goal_completion(site, event_data) do
    triggers = get_enabled_triggers_for_site(site)
    goal_triggers = Enum.filter(triggers, &(&1.trigger_type == "goal_completion"))

    for trigger <- goal_triggers do
      payload = build_goal_completion_payload(site, %{
        goal_id: event_data.goal_id,
        goal_name: event_data.goal_name,
        visitor_id: event_data.visitor_id,
        visitor_country: event_data.visitor_country,
        visitor_referrer: event_data.visitor_referrer,
        pathname: event_data.pathname,
        properties: event_data.properties
      })

      queue_delivery(trigger.webhook, "goal_completion", payload)
    end

    :ok
  end

  @spec get_retry_delay(integer()) :: integer()
  def get_retry_delay(attempt_number) do
    Enum.at(@retry_delays, attempt_number - 1, 4)
  end

  @spec max_retry_attempts() :: integer()
  def max_retry_attempts, do: @max_retry_attempts
end
