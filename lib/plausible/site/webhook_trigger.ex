defmodule Plausible.Site.WebhookTrigger do
  @moduledoc """
  Schema for webhook triggers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @trigger_types ["visitor_spike", "goal_completion"]

  schema "webhook_triggers" do
    field :trigger_type, :string
    field :threshold, :integer
    field :enabled, :boolean, default: true

    belongs_to :webhook, Plausible.Site.Webhook
    belongs_to :goal, Plausible.Goal
    has_many :deliveries, Plausible.Site.WebhookDelivery, foreign_key: :trigger_id

    timestamps()
  end

  def changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:webhook_id, :trigger_type, :goal_id, :threshold, :enabled])
    |> validate_required([:webhook_id, :trigger_type])
    |> validate_inclusion(:trigger_type, @trigger_types)
    |> validate_trigger_conditions()
  end

  def visitor_spike_changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:webhook_id, :trigger_type, :threshold, :enabled])
    |> validate_required([:webhook_id, :trigger_type, :threshold])
    |> validate_inclusion(:trigger_type, ["visitor_spike"])
    |> validate_number(:threshold, greater_than: 0)
  end

  def goal_completion_changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:webhook_id, :trigger_type, :goal_id, :enabled])
    |> validate_required([:webhook_id, :trigger_type, :goal_id])
    |> validate_inclusion(:trigger_type, ["goal_completion"])
  end

  def toggle_enabled(trigger) do
    trigger |> change(enabled: !trigger.enabled)
  end

  defp validate_trigger_conditions(changeset) do
    trigger_type = get_change(changeset, :trigger_type) || changeset.data.trigger_type

    case trigger_type do
      "visitor_spike" ->
        changeset |> validate_required([:threshold]) |> validate_number(:threshold, greater_than: 0)

      "goal_completion" ->
        changeset |> validate_required([:goal_id])

      _ ->
        changeset
    end
  end
end
