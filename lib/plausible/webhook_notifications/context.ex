defmodule Plausible.WebhookNotifications.Context do
  @moduledoc """
  Context module for webhook notifications
  """
  import Ecto.Query, only: [from: 1]
  alias Plausible.{Repo, WebhookNotifications}
  alias WebhookNotifications.{WebhookConfig, EventTrigger, DeliveryLog}

  @doc """
  Creates a new webhook configuration for a site
  """
  def create_webhook(site, attrs \\ %{}) do
    site
    |> Ecto.build_assoc(:webhook_configs)
    |> WebhookConfig.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing webhook configuration
  """
  def update_webhook(%WebhookConfig{} = webhook, attrs) do
    webhook
    |> WebhookConfig.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a webhook configuration
  """
  def delete_webhook(%WebhookConfig{} = webhook) do
    Repo.delete(webhook)
  end

  @doc """
  Gets all webhooks for a site
  """
  def list_webhooks(%Plausible.Site{} = site) do
    from(w in WebhookConfig,
      where: w.site_id == ^site.id,
      preload: [:event_triggers],
      order_by: [desc: :inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single webhook by ID
  """
  def get_webhook!(id) do
    Repo.get!(WebhookConfig, id)
    |> Repo.preload(:event_triggers)
  end

  @doc """
  Gets a webhook by ID for a specific site
  """
  def get_webhook!(%Plausible.Site{} = site, id) do
    from(w in WebhookConfig,
      where: w.id == ^id and w.site_id == ^site.id,
      preload: [:event_triggers]
    )
    |> Repo.one!()
  end

  @doc """
  Adds a trigger to a webhook configuration
  """
  def add_trigger(%WebhookConfig{} = webhook, attrs \\ %{}) do
    webhook
    |> Ecto.build_assoc(:event_triggers)
    |> EventTrigger.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a trigger
  """
  def update_trigger(%EventTrigger{} = trigger, attrs) do
    trigger
    |> EventTrigger.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Removes a trigger
  """
  def remove_trigger(%EventTrigger{} = trigger) do
    Repo.delete(trigger)
  end

  @doc """
  Gets all enabled triggers for a webhook
  """
  def get_enabled_triggers(%WebhookConfig{} = webhook) do
    from(t in EventTrigger,
      where: t.webhook_config_id == ^webhook.id and t.is_enabled == true
    )
    |> Repo.all()
  end

  @doc """
  Creates a delivery log entry
  """
  def create_delivery_log(webhook, event_type, payload) do
    webhook
    |> Ecto.build_assoc(:delivery_logs)
    |> DeliveryLog.changeset(%{
      event_type: event_type,
      payload: payload,
      status: "pending"
    })
    |> Repo.insert()
  end

  @doc """
  Updates a delivery log with the result
  """
  def update_delivery_log(%DeliveryLog{} = log, attrs) do
    log
    |> DeliveryLog.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a delivery as successful
  """
  def mark_delivery_success(%DeliveryLog{} = log, response_code, response_body) do
    update_delivery_log(log, %{
      status: "success",
      response_code: response_code,
      response_body: String.slice(response_body || "", 0..999),
      delivered_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Marks a delivery as failed
  """
  def mark_delivery_failure(%DeliveryLog{} = log, response_code, response_body, attempt_number) do
    update_delivery_log(log, %{
      status: "failed",
      response_code: response_code,
      response_body: String.slice(response_body || "", 0..999),
      attempt_number: attempt_number
    })
  end

  @doc """
  Gets delivery logs for a webhook
  """
  def list_deliveries(%WebhookConfig{} = webhook, opts \\ %{}) do
    page = Map.get(opts, :page, 1)
    limit = min(Map.get(opts, :limit, 20), 100)
    status = Map.get(opts, :status, "all")

    query =
      from(d in DeliveryLog,
        where: d.webhook_config_id == ^webhook.id,
        order_by: [desc: :inserted_at]
      )

    query =
      case status do
        "success" -> from(d in query, where: d.status == "success")
        "failed" -> from(d in query, where: d.status == "failed")
        _ -> query
      end

    total = Repo.aggregate(query, :count)

    deliveries =
      from(d in query,
        limit: ^limit,
        offset: ^((page - 1) * limit)
      )
      |> Repo.all()

    %{
      deliveries: deliveries,
      total: total,
      page: page,
      limit: limit,
      total_pages: ceil(total / limit)
    }
  end

  @doc """
  Retries a failed delivery by updating the status and enqueueing a new delivery job
  """
  def retry_delivery(%DeliveryLog{} = log) do
    new_attempt_number = (log.attempt_number || 0) + 1

    case update_delivery_log(log, %{
      status: "pending",
      attempt_number: new_attempt_number,
      delivered_at: nil
    }) do
      {:ok, updated_log} ->
        # Enqueue the delivery worker to retry the webhook
        %{delivery_log_id: updated_log.id}
        |> Plausible.Workers.WebhookDeliveryWorker.new()
        |> Oban.insert!()

        {:ok, updated_log}

      error ->
        error
    end
  end

  @doc """
  Validates a webhook URL
  """
  def validate_webhook_url(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host} when host != "" ->
        {:ok, url}

      %URI{scheme: "http"} ->
        {:error, "Webhook URL must use HTTPS"}

      %URI{scheme: nil} ->
        {:error, "Invalid URL format"}

      _ ->
        {:error, "Invalid URL format"}
    end
  end

  @doc """
  Validates a threshold configuration
  """
  def validate_threshold(%{"trigger_type" => trigger_type, "threshold_value" => value, "threshold_unit" => unit}) do
    cond do
      not requires_threshold?(trigger_type) ->
        {:ok, :not_required}

      is_nil(value) or value == "" ->
        {:error, "Threshold value is required for #{trigger_type} trigger"}

      not is_integer(value) or value <= 0 ->
        {:error, "Threshold value must be a positive integer"}

      is_nil(unit) or unit == "" ->
        {:error, "Threshold unit is required for #{trigger_type} trigger"}

      unit not in ["percentage", "absolute"] ->
        {:error, "Threshold unit must be 'percentage' or 'absolute'"}

      unit == "percentage" and value > 1000 ->
        {:error, "Percentage threshold cannot exceed 1000%"}

      true ->
        {:ok, :valid}
    end
  end

  def validate_threshold(%{} = attrs) do
    validate_threshold %{
      "trigger_type" => Map.get(attrs, :trigger_type) || Map.get(attrs, "trigger_type"),
      "threshold_value" => Map.get(attrs, :threshold_value) || Map.get(attrs, "threshold_value"),
      "threshold_unit" => Map.get(attrs, :threshold_unit) || Map.get(attrs, "threshold_unit")
    }
  end

  def validate_threshold(_), do: {:ok, :not_required}

  @doc """
  Checks if a trigger type requires a threshold configuration
  """
  def requires_threshold?("visitor_spike"), do: true
  def requires_threshold?("goal_completion"), do: false
  def requires_threshold?(_), do: false

  @doc """
  Validates a threshold value based on unit
  """
  def validate_threshold_value(value, "percentage") when is_integer(value) do
    if value > 0 and value <= 1000 do
      {:ok, value}
    else
      {:error, "Percentage threshold must be between 1 and 1000"}
    end
  end

  def validate_threshold_value(value, "absolute") when is_integer(value) do
    if value > 0 do
      {:ok, value}
    else
      {:error, "Absolute threshold must be a positive integer"}
    end
  end

  def validate_threshold_value(_value, _unit) do
    {:error, "Invalid threshold configuration"}
  end

  @doc """
  Validates a threshold unit
  """
  def validate_threshold_unit(unit) do
    case unit do
      "percentage" -> {:ok, unit}
      "absolute" -> {:ok, unit}
      _ -> {:error, "Threshold unit must be 'percentage' or 'absolute'"}
    end
  end

  @doc """
  Generates a random secret for webhook authentication
  """
  def generate_secret do
    :crypto.strong_rand_bytes(32) |> Base.encode64()
  end

  @doc """
  Validates a secret against the stored hash
  """
  def validate_secret(raw_secret, stored_hash) when is_binary(raw_secret) and is_binary(stored_hash) do
    hashed_secret = Base.encode64(:crypto.hash(:sha256, raw_secret))

    if Plug.Crypto.compare_secure(hashed_secret, stored_hash) do
      {:ok, true}
    else
      {:error, "Invalid secret"}
    end
  end

  def validate_secret(_raw_secret, _stored_hash) do
    {:error, "Invalid secret format"}
  end

  @doc """
  Sends a test webhook to verify the configuration
  """
  def test_webhook(%WebhookConfig{} = webhook) do
    test_payload = %{
      event: "test",
      site_id: webhook.site_id,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      data: %{
        message: "This is a test webhook from Plausible Analytics"
      }
    }

    case create_delivery_log(webhook, "test", test_payload) do
      {:ok, log} ->
        # Enqueue the delivery worker to send the webhook
        %{delivery_log_id: log.id}
        |> Plausible.Workers.WebhookDeliveryWorker.new()
        |> Oban.insert!()

        {:ok, log, test_payload}

      error ->
        error
    end
  end
end
