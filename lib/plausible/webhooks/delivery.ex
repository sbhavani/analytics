defmodule Plausible.Webhooks.Delivery do
  @moduledoc """
  Schema for webhook delivery records
  """
  use Ecto.Schema
  use Plausible
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @statuses ["pending", "success", "failed"]

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :error_message, :string
    field :attempted_at, :naive_datetime
    field :completed_at, :naive_datetime

    belongs_to :webhook, Plausible.Webhooks.Webhook

    timestamps()
  end

  def statuses, do: @statuses

  def changeset(delivery, attrs \\ %{}) do
    delivery
    |> cast(attrs, [:event_type, :payload, :status, :response_code, :error_message, :webhook_id])
    |> validate_required([:event_type, :payload, :webhook_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:webhook_id)
  end

  def mark_as_success(changeset) do
    changeset
    |> put_change(:status, "success")
    |> put_change(:completed_at, NaiveDateTime.utc_now())
  end

  def mark_as_failed(changeset, response_code, error_message) do
    changeset
    |> put_change(:status, "failed")
    |> put_change(:response_code, response_code)
    |> put_change(:error_message, error_message)
    |> put_change(:completed_at, NaiveDateTime.utc_now())
  end
end
