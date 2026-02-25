defmodule Plausible.Webhooks.Delivery do
  @moduledoc """
  Schema for tracking webhook delivery attempts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Plausible.Webhooks.Webhook

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :response_code, :integer
    field :error_message, :string
    field :attempt_number, :integer, default: 1

    belongs_to :webhook_configuration, Webhook, type: :binary_id

    timestamps()
  end

  def pending(query \\ __MODULE__) do
    from d in query, where: d.status == "pending"
  end

  def successful(query \\ __MODULE__) do
    from d in query, where: d.status == "success"
  end

  def failed(query \\ __MODULE__) do
    from d in query, where: d.status == "failed"
  end

  def for_webhook(query \\ __MODULE__, webhook_id) do
    from d in query,
      where: d.webhook_configuration_id == ^webhook_id,
      order_by: [desc: :inserted_at]
  end

  def changeset(delivery \\ %__MODULE__{}, attrs) do
    delivery
    |> cast(attrs, [:webhook_configuration_id, :event_type, :payload, :status, :response_code, :error_message, :attempt_number])
    |> validate_required([:webhook_configuration_id, :event_type, :payload])
    |> validate_inclusion(:status, ["pending", "success", "failed"])
    |> validate_inclusion(:attempt_number, 1..3)
  end
end
