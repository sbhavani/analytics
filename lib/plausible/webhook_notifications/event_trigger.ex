defmodule Plausible.WebhookNotifications.EventTrigger do
  @moduledoc """
  Schema for event triggers
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  @trigger_types ["visitor_spike", "goal_completion"]
  @threshold_units ["percentage", "absolute"]

  schema "event_triggers" do
    field :trigger_type, :string
    field :is_enabled, :boolean, default: true
    field :threshold_value, :integer
    field :threshold_unit, :string

    belongs_to :webhook_config, Plausible.WebhookNotifications.WebhookConfig

    timestamps()
  end

  def changeset(event_trigger, attrs) do
    event_trigger
    |> cast(attrs, [:webhook_config_id, :trigger_type, :is_enabled, :threshold_value, :threshold_unit])
    |> validate_required([:webhook_config_id, :trigger_type])
    |> validate_inclusion(:trigger_type, @trigger_types)
    |> validate_inclusion(:threshold_unit, @threshold_units, allow_nil: true)
    |> validate_number(:threshold_value, greater_than: 0, allow_nil: true)
  end

  def trigger_types, do: @trigger_types
  def threshold_units, do: @threshold_units
end
