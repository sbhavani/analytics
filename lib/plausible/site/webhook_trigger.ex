defmodule Plausible.Site.WebhookTrigger do
  @moduledoc """
  Schema for webhook trigger configuration
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @trigger_types [:visitor_spike, :goal_completion]

  schema "webhook_triggers" do
    field :trigger_type, Ecto.Enum, values: @trigger_types
    field :threshold, :integer
    field :enabled, :boolean, default: true

    belongs_to :webhook, Plausible.Site.Webhook
    belongs_to :goal, Plausible.Goal
    has_many :deliveries, Plausible.Site.WebhookDelivery

    timestamps()
  end

  def changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:webhook_id, :trigger_type, :threshold, :goal_id, :enabled])
    |> validate_required([:webhook_id, :trigger_type, :enabled])
    |> validate_trigger_requirements()
  end

  defp validate_trigger_requirements(changeset) do
    trigger_type = get_change(changeset, :trigger_type) || get_field(changeset, :trigger_type)

    case trigger_type do
      :visitor_spike ->
        changeset
        |> validate_required([:threshold])
        |> validate_number(:threshold, greater_than: 0)

      :goal_completion ->
        changeset
        |> validate_required([:goal_id])

      _ ->
        changeset
    end
  end
end
