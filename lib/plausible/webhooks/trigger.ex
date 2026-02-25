defmodule Plausible.Webhooks.Trigger do
  @moduledoc """
  Schema for webhook triggers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @trigger_types [:visitor_spike, :goal_completion]

  schema "triggers" do
    field :type, :string
    field :threshold, :integer
    field :goal_id, :binary_id

    belongs_to :webhook, Plausible.Webhooks.Webhook
    belongs_to :goal, Plausible.Goal

    timestamps()
  end

  def create_changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:webhook_id, :type, :threshold, :goal_id])
    |> validate_required([:webhook_id, :type])
    |> validate_inclusion(:type, @trigger_types)
    |> validate_threshold()
    |> validate_goal_requirement()
    |> foreign_key_constraint(:webhook_id)
    |> foreign_key_constraint(:goal_id)
  end

  defp validate_threshold(changeset) do
    type = get_change(changeset, :type) || get_field(changeset, :type)

    if type == :visitor_spike || type == "visitor_spike" do
      changeset
      |> validate_required([:threshold])
      |> validate_number(:threshold, greater_than: 0, less_than_or_equal_to: 10000)
    else
      changeset
    end
  end

  defp validate_goal_requirement(changeset) do
    # goal_id is optional - if not provided, fires for all goals
    # This validation could be extended to require goal_id for goal_completion type
    changeset
  end
end
