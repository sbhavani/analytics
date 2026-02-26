defmodule Plausible.Webhooks.WebhookDelivery do
  @moduledoc """
  Schema for webhook delivery attempts
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t() :: %__MODULE__{}

  @statuses [:pending, :delivered, :failed, :retrying]

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status, Ecto.Enum, values: @statuses
    field :response_code, :integer
    field :response_body, :string
    field :retry_count, :integer, default: 0

    belongs_to :webhook, Plausible.Webhooks.Webhook

    timestamps()
  end

  def statuses, do: @statuses

  def changeset(delivery, attrs \\ %{}) do
    delivery
    |> cast(attrs, [:webhook_id, :event_type, :payload, :status, :response_code, :response_body, :retry_count])
    |> validate_required([:webhook_id, :event_type, :payload, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:retry_count, greater_than_or_equal_to: 0, less_than: 4)
  end

  def pending(query \\ __MODULE__) do
    from d in query, where: d.status == :pending
  end

  def failed(query \\ __MODULE__) do
    from d in query, where: d.status == :failed
  end

  def for_webhook(query \\ __MODULE__, webhook_id) do
    from d in query, where: d.webhook_id == ^webhook_id
  end

  def recent(query \\ __MODULE__, limit \\ 10) do
    from d in query, order_by: [desc: :inserted_at], limit: ^limit
  end
end
