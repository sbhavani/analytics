defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook operations.
  """
  use Plausible
  use Plausible.Repo

  alias Plausible.Site.Webhook
  alias Plausible.Site.WebhookEvent
  alias Plausible.Site.WebhookDeliveryLog
  alias Plausible.Workers.WebhookDelivery

  @doc """
  Create a new webhook for a site.
  """
  def create_webhook(site, attrs) do
    site
    |> Ecto.build_assoc(:webhooks)
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get all webhooks for a site.
  """
  def list_webhooks(site) do
    Repo.all(from w in Webhook, where: w.site_id == ^site.id)
  end

  @doc """
  Get a webhook by ID.
  """
  def get_webhook!(id), do: Repo.get!(Webhook, id)

  @doc """
  Update a webhook.
  """
  def update_webhook(webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a webhook.
  """
  def delete_webhook(webhook) do
    Repo.delete(webhook)
  end

  @doc """
  Get webhooks for a site that have a specific event type enabled.
  """
  def webhooks_for_event(site, event_type) do
    Repo.all(
      from w in Webhook,
        where: w.site_id == ^site.id,
        where: ^event_type in w.enabled_events
    )
  end

  @doc """
  Create a webhook event and queue it for delivery.
  """
  def create_event(webhook, event_type, payload) do
    {:ok, event} =
      %WebhookEvent{webhook_id: webhook.id, event_type: event_type, payload: payload}
      |> Repo.insert()

    WebhookDelivery.new(%{webhook_event_id: event.id})
    |> Oban.insert()

    event
  end

  @doc """
  Queue a webhook event for immediate delivery.
  """
  def deliver_event(event) do
    WebhookDelivery.new(%{webhook_event_id: event.id}, schedule_in: 0)
    |> Oban.insert()
  end

  @doc """
  Send a test webhook to the given endpoint via the WebhookDelivery worker.
  """
  def send_test_webhook(webhook) do
    test_payload = Plausible.WebhookAuth.test_payload(
      webhook.site_id,
      webhook.site.domain
    )

    # Create a webhook event and queue it for delivery via worker
    event = %WebhookEvent{
      webhook_id: webhook.id,
      event_type: "test",
      payload: test_payload,
      status: "pending"
    }

    {:ok, event} = Repo.insert(event)

    # Queue for immediate delivery via the worker
    deliver_event(event)

    {:ok, %{event_id: event.id}}
  end

  @doc """
  Process the result of a webhook delivery and create a log entry.
  """
  def log_delivery_result(webhook_event_id, result) do
    case result do
      {:ok, status_code, response_body} ->
        log = WebhookDeliveryLog.success_log(%{
          webhook_event_id: webhook_event_id,
          status_code: status_code,
          response_body: response_body
        })
        Repo.insert(log)

      {:error, message, response_body} ->
        log = WebhookDeliveryLog.failure_log(%{
          webhook_event_id: webhook_event_id,
          error_message: message,
          response_body: response_body
        })
        Repo.insert(log)
    end
  end

  @doc """
  Deliver a webhook payload to the configured endpoint.
  """
  def deliver_webhook(webhook, payload) do
    headers = [
      {"content-type", "application/json"},
      {"x-plausible-signature", Plausible.WebhookAuth.sign_payload(payload, webhook.secret)},
      {"x-plausible-event", payload.event_type}
    ]

    case Plausible.HTTPClient.post(webhook.url, headers, payload) do
      {:ok, %{status: status, body: body}} when status >= 200 and status < 300 ->
        {:ok, status, inspect(body)}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}", inspect(body)}

      {:error, reason} ->
        {:error, inspect(reason), nil}
    end
  end

  @doc """
  Build spike event payload.
  """
  def spike_payload(site, current_visitors, threshold, sources \\ [], pages \\ []) do
    %{
      event_type: "spike",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      current_visitors: current_visitors,
      threshold: threshold,
      change_type: "spike",
      sources: sources,
      pages: pages
    }
  end

  @doc """
  Build drop event payload.
  """
  def drop_payload(site, current_visitors, threshold) do
    %{
      event_type: "drop",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      current_visitors: current_visitors,
      threshold: threshold,
      change_type: "drop"
    }
  end

  @doc """
  Build goal completion event payload.
  """
  def goal_payload(site, goal, count \\ 1) do
    %{
      event_type: "goal",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      goal_id: goal.id,
      goal_name: goal.display_name,
      count: count
    }
  end

  @doc """
  Trigger spike webhooks for a site.
  """
  def trigger_spike_webhooks(site, current_visitors, threshold, sources \\ [], pages \\ []) do
    payload = spike_payload(site, current_visitors, threshold, sources, pages)

    for webhook <- webhooks_for_event(site, "spike") do
      create_event(webhook, "spike", payload)
    end
  end

  @doc """
  Trigger drop webhooks for a site.
  """
  def trigger_drop_webhooks(site, current_visitors, threshold) do
    payload = drop_payload(site, current_visitors, threshold)

    for webhook <- webhooks_for_event(site, "drop") do
      create_event(webhook, "drop", payload)
    end
  end

  @doc """
  Trigger goal completion webhooks for a site.
  """
  def trigger_goal_webhooks(site, goal, count \\ 1) do
    payload = goal_payload(site, goal, count)

    for webhook <- webhooks_for_event(site, "goal") do
      create_event(webhook, "goal", payload)
    end
  end
end
