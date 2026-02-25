defmodule Plausible.Webhooks.Delivery do
  @moduledoc """
  Schema for webhook delivery records.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @delivery_statuses [:pending, :success, :failed, :retrying]

  schema "deliveries" do
    field :event_id, Ecto.UUID
    field :url, :string
    field :status, :string
    field :response_code, :integer
    field :response_body, :string
    field :error_message, :string
    field :attempt, :integer, default: 1
    field :payload, :map
    field :trigger_type, :string
    field :event_data, :map

    belongs_to :webhook, Plausible.Webhooks.Webhook

    timestamps()
  end

  def create_changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:webhook_id, :event_id, :url, :status, :response_code, :response_body, :error_message, :attempt, :payload, :trigger_type, :event_data])
    |> validate_required([:webhook_id, :event_id, :url, :status, :attempt, :payload])
    |> validate_inclusion(:status, @delivery_statuses)
    |> validate_number(:attempt, greater_than: 0, less_than_or_equal_to: 3)
    |> validate_response_code()
    |> foreign_key_constraint(:webhook_id)
  end

  def status_pending, do: "pending"
  def status_success, do: "success"
  def status_failed, do: "failed"
  def status_retrying, do: "retrying"

  defp validate_response_code(changeset) do
    validate_change(changeset, :response_code, fn _, code ->
      if is_nil(code) || (code >= 100 and code < 600) do
        []
      else
        [response_code: "must be a valid HTTP status code"]
      end
    end)
  end

  def success?(%__MODULE__{status: status}), do: status == status_success()
  def failed?(%__MODULE__{status: status}), do: status == status_failed()
  def retrying?(%__MODULE__{status: status}), do: status == status_retrying()
  def pending?(%__MODULE__{status: status}), do: status == status_pending()

  def can_retry?(%__MODULE__{attempt: attempt}) when attempt < 3, do: true
  def can_retry?(_), do: false
end
