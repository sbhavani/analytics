defmodule Plausible.Site.WebhookDeliveryLog do
  @moduledoc """
  Schema for logging webhook delivery attempts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "webhook_delivery_logs" do
    field :status_code, :integer
    field :response_body, :string
    field :error_message, :string
    field :delivered_at, :naive_datetime
    belongs_to :webhook_event, Plausible.Site.WebhookEvent

    timestamps()
  end

  def changeset(delivery_log, attrs) do
    delivery_log
    |> cast(attrs, [:webhook_event_id, :status_code, :response_body, :error_message, :delivered_at])
    |> validate_required([:webhook_event_id])
  end

  def success_log(attrs) do
    %__MODULE__{}
    |> changeset(Map.put(attrs, :delivered_at, NaiveDateTime.utc_now()))
  end

  def failure_log(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end
end
