defmodule Plausible.Site.WebhookDelivery do
  @moduledoc """
  Schema for webhook delivery records.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status_code, :integer
    field :response_body, :string
    field :error_message, :string
    field :attempt_number, :integer, default: 1

    belongs_to :webhook, Plausible.Site.Webhook
    belongs_to :trigger, Plausible.Site.WebhookTrigger

    timestamps()
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :webhook_id,
      :trigger_id,
      :event_type,
      :payload,
      :status_code,
      :response_body,
      :error_message,
      :attempt_number
    ])
    |> validate_required([:webhook_id, :trigger_id, :event_type, :payload])
  end

  def successful do
    where([d], d.status_code >= 200 and d.status_code < 300)
  end

  def failed do
    where([d], is_nil(d.status_code) or d.status_code >= 400 or not is_nil(d.error_message))
  end

  def for_webhook(query \\ __MODULE__, webhook_id) do
    where(query, [d], d.webhook_id == ^webhook_id)
  end

  def ordered_by_inserted_at(query \\ __MODULE__, order \\ :desc) do
    order_by(query, [d], {^order, d.inserted_at})
  end

  def with_status(query \\ __MODULE__, status) do
    case status do
      "success" -> query |> successful()
      "failed" -> query |> failed()
      _ -> query
    end
  end

  def within_date_range(query \\ __MODULE__, from_date, to_date) do
    where(
      query,
      [d],
      d.inserted_at >= ^from_date and d.inserted_at <= ^to_date
    )
  end
end
