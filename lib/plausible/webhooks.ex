defmodule Plausible.Webhooks do
  @moduledoc """
  Context module for webhook management
  """
  use Plausible
  import Ecto.Query
  alias Plausible.{Repo, Site, Auth}
  alias Site.{Webhook, WebhookTrigger, WebhookDelivery}
  alias Plausible.HTTPClient
  alias Plausible.Teams.Memberships

  # Authorization

  @doc """
  Checks if a user can manage webhooks for a site
  """
  @spec can_manage_webhooks?(Site.t(), Auth.User.t()) :: boolean()
  def can_manage_webhooks?(site, user) do
    case Memberships.site_role(site, user) do
      {:ok, {:team_member, role}} when role in [:owner, :admin, :editor] -> true
      {:ok, {:guest_member, role}} when role in [:owner, :admin, :editor] -> true
      _ -> false
    end
  end

  # Webhook CRUD

  @doc """
  Creates a new webhook for a site
  """
  def create_webhook(site, attrs) do
    site
    |> Ecto.build_assoc(:webhooks)
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a webhook by ID
  """
  def get_webhook(webhook_id) do
    Repo.get(Webhook, webhook_id)
  end

  @doc """
  Gets a webhook by ID for a specific site
  """
  def get_webhook(webhook_id, site_id) do
    Repo.get_by(Webhook, id: webhook_id, site_id: site_id)
  end

  @doc """
  Lists all webhooks for a site
  """
  def list_webhooks(site_id) do
    Repo.all(from w in Webhook, where: w.site_id == ^site_id, order_by: [desc: :inserted_at])
  end

  @doc """
  Lists all enabled webhooks for a site
  """
  def list_enabled_webhooks(site_id) do
    Repo.all(
      from w in Webhook,
        where: w.site_id == ^site_id and w.enabled == true,
        order_by: [desc: :inserted_at]
    )
  end

  @doc """
  Updates a webhook
  """
  def update_webhook(webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a webhook
  """
  def delete_webhook(webhook) do
    Repo.delete(webhook)
  end

  @doc """
  Toggles webhook enabled state
  """
  def toggle_webhook(webhook) do
    webhook
    |> Ecto.Changeset.change(enabled: !webhook.enabled)
    |> Repo.update()
  end

  # Trigger CRUD

  @doc """
  Creates a new trigger for a webhook
  """
  def create_trigger(webhook, attrs) do
    webhook
    |> Ecto.build_assoc(:triggers)
    |> WebhookTrigger.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a trigger by ID
  """
  def get_trigger(trigger_id) do
    Repo.get(WebhookTrigger, trigger_id)
  end

  @doc """
  Lists all triggers for a webhook
  """
  def list_triggers(webhook_id) do
    Repo.all(
      from t in WebhookTrigger,
        where: t.webhook_id == ^webhook_id,
        order_by: [desc: :inserted_at],
        preload: [:goal]
    )
  end

  @doc """
  Lists all enabled triggers for a webhook
  """
  def list_enabled_triggers(webhook_id) do
    Repo.all(
      from t in WebhookTrigger,
        where: t.webhook_id == ^webhook_id and t.enabled == true,
        order_by: [desc: :inserted_at],
        preload: [:goal]
    )
  end

  @doc """
  Lists all enabled triggers for a site
  """
  def list_all_enabled_triggers(site_id) do
    Repo.all(
      from t in WebhookTrigger,
        join: w in assoc(t, :webhook),
        where: w.site_id == ^site_id and w.enabled == true and t.enabled == true,
        preload: [:webhook, :goal]
    )
  end

  @doc """
  Lists all enabled triggers across all sites with preloads
  """
  def list_all_enabled_triggers_with_preloads do
    Repo.all(
      from t in WebhookTrigger,
        join: w in assoc(t, :webhook),
        join: s in assoc(w, :site),
        where: w.enabled == true and t.enabled == true,
        preload: [webhook: {w, site: s}, :goal]
    )
  end

  @doc """
  Updates a trigger
  """
  def update_trigger(trigger, attrs) do
    trigger
    |> WebhookTrigger.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a trigger
  """
  def delete_trigger(trigger) do
    Repo.delete(trigger)
  end

  @doc """
  Toggles trigger enabled state
  """
  def toggle_trigger(trigger) do
    trigger
    |> Ecto.Changeset.change(enabled: !trigger.enabled)
    |> Repo.update()
  end

  # Delivery Log

  @doc """
  Logs a webhook delivery attempt
  """
  def log_delivery(webhook_id, trigger_id, payload, result) do
    attrs = %{
      webhook_id: webhook_id,
      trigger_id: trigger_id,
      payload: payload,
      success: match?({:ok, _}, result),
      attempt: 1
    }

    attrs =
      case result do
        {:ok, %{status: status}} ->
          Map.merge(attrs, %{status_code: status})

        {:error, %{reason: %{status: status, body: body}}} ->
          Map.merge(attrs, %{
            status_code: status,
            response_body: body,
            error_message: "HTTP #{status}"
          })

        {:error, error} ->
          Map.merge(attrs, %{error_message: inspect(error)})
      end

    %WebhookDelivery{}
    |> WebhookDelivery.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists delivery history for a webhook
  """
  def list_deliveries(webhook_id, limit \\ 50) do
    Repo.all(
      from d in WebhookDelivery,
        where: d.webhook_id == ^webhook_id,
        order_by: [desc: :inserted_at],
        limit: ^limit
    )
  end

  # Test Webhook

  @doc """
  Sends a test webhook to verify configuration
  """
  def test_webhook(webhook) do
    payload = build_test_payload(webhook)

    headers = [
      {"content-type", "application/json"},
      {"user-agent", "Plausible-Webhook/1.0"},
      {"x-plausible-signature", signature(payload, webhook.secret)}
    ]

    case HTTPClient.post(webhook.url, headers, payload, receive_timeout: 10_000) do
      {:ok, %{status: status}} when status >= 200 and status < 300 ->
        {:ok, :success}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp build_test_payload(webhook) do
    %{
      event_id: "test-event-#{:rand.uniform(999_999)}",
      event_type: "test",
      site_id: webhook.site_id,
      site_domain: webhook.site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      trigger: %{
        id: "test-trigger-id",
        type: "test"
      },
      data: %{
        message: "This is a test webhook from Plausible"
      }
    }
  end

  defp signature(payload, secret) do
    payload_json = Jason.encode!(payload)
    "sha256=#{:crypto.hmac(:sha256, secret, payload_json) |> Base.encode16()}"
  end

  # Build payload for actual events

  @doc """
  Builds a webhook payload for a visitor spike event
  """
  def build_spike_payload(trigger, site, current_visitors) do
    %{
      event_id: UUID.uuid4(),
      event_type: "visitor_spike",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      trigger: %{
        id: trigger.id,
        type: "visitor_spike",
        threshold: trigger.threshold
      },
      data: %{
        current_visitors: current_visitors
      }
    }
  end

  @doc """
  Builds a webhook payload for a goal completion event
  """
  def build_goal_payload(trigger, site, completions) do
    %{
      event_id: UUID.uuid4(),
      event_type: "goal_completion",
      site_id: site.id,
      site_domain: site.domain,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      trigger: %{
        id: trigger.id,
        type: "goal_completion",
        goal_id: trigger.goal_id,
        goal_name: trigger.goal && trigger.goal.name
      },
      data: %{
        goal_completions: completions
      }
    }
  end
end
