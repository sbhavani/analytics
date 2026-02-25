defmodule Plausible.Site.WebhookDelivery do
  @moduledoc """
  Schema for tracking webhook delivery attempts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:pending, :success, :failed, :retrying]

  schema "webhook_deliveries" do
    field :event_type, :string
    field :event_id, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :response_body, :string
    field :attempts, :integer, default: 0
    field :last_attempt_at, :naive_datetime
    field :next_retry_at, :naive_datetime

    belongs_to :webhook, Plausible.Site.Webhook

    timestamps()
  end

  def statuses, do: @statuses

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :webhook_id,
      :event_type,
      :event_id,
      :payload,
      :status,
      :response_code,
      :response_body,
      :attempts,
      :last_attempt_at,
      :next_retry_at
    ])
    |> validate_required([:webhook_id, :event_type, :payload, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:attempts, greater_than_or_equal_to: 0)
    |> validate_length(:response_body, max: 1000)
  end

  def mark_success(changeset, response_code, response_body) do
    changeset
    |> put_change(:status, "success")
    |> put_change(:response_code, response_code)
    |> put_change(:response_body, String.slice(response_body || "", 0..1000))
    |> put_change(:attempts, get_change(changeset, :attempts, 0) + 1)
    |> put_change(:last_attempt_at, NaiveDateTime.utc_now())
  end

  def mark_failed(changeset, response_code, response_body) do
    changeset
    |> put_change(:status, "failed")
    |> put_change(:response_code, response_code)
    |> put_change(:response_body, String.slice(response_body || "", 0..1000))
    |> put_change(:attempts, get_change(changeset, :attempts, 0) + 1)
    |> put_change(:last_attempt_at, NaiveDateTime.utc_now())
  end

  def mark_retrying(changeset, next_retry_at) do
    changeset
    |> put_change(:status, "retrying")
    |> put_change(:attempts, get_change(changeset, :attempts, 0) + 1)
    |> put_change(:last_attempt_at, NaiveDateTime.utc_now())
    |> put_change(:next_retry_at, next_retry_at)
  end
end
