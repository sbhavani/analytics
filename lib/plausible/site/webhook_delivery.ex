defmodule Plausible.Site.WebhookDelivery do
  @moduledoc """
  Schema for tracking webhook delivery attempts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @delivery_status [:pending, :delivering, :success, :failed, :retrying, :exhausted]

  schema "webhook_deliveries" do
    field :trigger_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :response_body, :string
    field :attempts, :integer, default: 0
    field :next_retry_at, :naive_datetime
    field :delivered_at, :naive_datetime

    belongs_to :webhook, Plausible.Site.Webhook

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(delivery, attrs) do
    delivery
      |> cast(attrs, [
        :webhook_id,
        :trigger_type,
        :payload,
        :status,
        :response_code,
        :response_body,
        :attempts,
        :next_retry_at,
        :delivered_at
      ])
      |> validate_required([:webhook_id, :trigger_type, :payload, :status])
      |> validate_inclusion(:status, @delivery_status)
  end

  @spec for_webhook(t(), map()) :: Ecto.Changeset.t()
  def for_webhook(webhook, attrs) do
    webhook
    |> Ecto.build_assoc(:deliveries)
    |> changeset(attrs)
  end

  @spec mark_success(t(), integer(), String.t()) :: Ecto.Changeset.t()
  def mark_success(delivery, response_code, response_body) do
    delivery
    |> change(status: :success, response_code: response_code, response_body: response_body, delivered_at: NaiveDateTime.utc_now())
  end

  @spec mark_failed(t(), integer(), String.t()) :: Ecto.Changeset.t()
  def mark_failed(delivery, response_code, response_body) do
    delivery
    |> change(status: :failed, response_code: response_code, response_body: response_body)
  end

  @spec increment_attempt(t()) :: Ecto.Changeset.t()
  def increment_attempt(delivery) do
    delivery
    |> change(attempts: delivery.attempts + 1)
  end

  @spec schedule_retry(t(), NaiveDateTime.t()) :: Ecto.Changeset.t()
  def schedule_retry(delivery, next_retry) do
    delivery
    |> change(status: :retrying, next_retry_at: next_retry)
  end

  @spec mark_exhausted(t()) :: Ecto.Changeset.t()
  def mark_exhausted(delivery) do
    delivery
    |> change(status: :exhausted)
  end
end
