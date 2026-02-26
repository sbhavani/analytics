defmodule Plausible.Site.WebhookDelivery do
  @moduledoc """
  Schema for webhook delivery log
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "webhook_deliveries" do
    field :payload, :map
    field :status_code, :integer
    field :response_body, :string
    field :attempt, :integer, default: 1
    field :success, :boolean
    field :error_message, :string

    belongs_to :webhook, Plausible.Site.Webhook
    belongs_to :trigger, Plausible.Site.WebhookTrigger

    timestamps()
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :webhook_id,
      :trigger_id,
      :payload,
      :status_code,
      :response_body,
      :attempt,
      :success,
      :error_message
    ])
    |> validate_required([:webhook_id, :trigger_id, :payload, :success])
    |> validate_number(:attempt, greater_than: 0)
  end
end
