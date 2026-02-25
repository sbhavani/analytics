defmodule Plausible.Funnel.Step do
  @moduledoc """
  This module defines the database schema for a single Funnel step.
  See: `Plausible.Funnel` for more information.

  Each step can reference either a Goal (goal_id) or use a custom event name (event_name).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{}
  schema "funnel_steps" do
    field :step_order, :integer
    field :event_name, :string
    belongs_to :funnel, Plausible.Funnel
    belongs_to :goal, Plausible.Goal
    timestamps()
  end

  def changeset(step, goal_or_attrs \\ %{})

  def changeset(step, %Plausible.Goal{id: goal_id}) do
    changeset(step, %{goal_id: goal_id})
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:goal_id, :event_name])
    |> cast_assoc(:goal)
    |> validate_step_source()
    |> unique_constraint(:goal,
      name: :funnel_steps_goal_id_funnel_id_index
    )
    |> unique_constraint(:event_name,
      name: :funnel_steps_event_name_funnel_id_index
    )
  end

  defp validate_step_source(changeset) do
    goal_id = get_change(changeset, :goal_id)
    event_name = get_change(changeset, :event_name)

    if is_nil(goal_id) && is_nil(event_name) do
      add_error(changeset, :base, "Please select a goal or use a custom event name")
    else
      changeset
    end
  end
end
