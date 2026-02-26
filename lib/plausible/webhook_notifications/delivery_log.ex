defmodule Plausible.WebhookNotifications.DeliveryLog do
  @moduledoc """
  Schema for webhook delivery logs
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @statuses ["pending", "success", "failed"]

  schema "webhook_delivery_logs" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :response_body, :string
    field :attempt_number, :integer, default: 1
    field :delivered_at, :naive_datetime

    belongs_to :webhook_config, Plausible.WebhookNotifications.WebhookConfig

    timestamps()
  end

  def changeset(delivery_log, attrs) do
    delivery_log
    |> cast(attrs, [:webhook_config_id, :event_type, :payload, :status, :response_code, :response_body, :attempt_number, :delivered_at])
    |> validate_required([:webhook_config_id, :event_type, :payload, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:attempt_number, greater_than: 0)
  end

  def statuses, do: @statuses
end
