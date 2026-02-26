defmodule Plausible.Site.WebhookEvent do
  @moduledoc """
  Schema for webhook events to be delivered.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "webhook_events" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :attempts, :integer, default: 0
    field :last_attempt_at, :naive_datetime
    belongs_to :webhook, Plausible.Site.Webhook

    timestamps()
  end

  def changeset(webhook_event, attrs) do
    webhook_event
    |> cast(attrs, [:webhook_id, :event_type, :payload, :status, :attempts, :last_attempt_at])
    |> validate_required([:webhook_id, :event_type, :payload])
    |> validate_inclusion(:event_type, ["spike", "drop", "goal", "test"])
    |> validate_inclusion(:status, ["pending", "delivering", "delivered", "failed"])
  end

  def mark_delivering(webhook_event) do
    webhook_event
    |> change(status: "delivering", attempts: webhook_event.attempts + 1, last_attempt_at: NaiveDateTime.utc_now())
  end

  def mark_delivered(webhook_event) do
    webhook_event
    |> change(status: "delivered")
  end

  def mark_failed(webhook_event) do
    webhook_event
    |> change(status: "failed")
  end
end
