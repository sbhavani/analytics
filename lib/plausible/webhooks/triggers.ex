defmodule Plausible.Webhooks.Triggers do
  @moduledoc """
  Helper module for webhook trigger types and event detection.
  """

  @goal_completion "goal_completion"
  @visitor_spike "visitor_spike"

  def goal_completion, do: @goal_completion
  def visitor_spike, do: @visitor_spike

  def all, do: [@goal_completion, @visitor_spike]

  def valid?(trigger), do: trigger in all()

  defimpl String.Chars, for: [:atom, :binary] do
    def to_string("goal_completion"), do: "Goal Completion"
    def to_string("visitor_spike"), do: "Visitor Spike"
  end

  @doc """
  Check if a webhook should trigger for goal completion.
  """
  def should_trigger_for_goal?(%{triggers: triggers}) do
    @goal_completion in triggers
  end

  @doc """
  Check if a webhook should trigger for visitor spike based on threshold.
  """
  def should_trigger_for_visitor_spike?(%{triggers: triggers, thresholds: thresholds}, current, previous) do
    unless @visitor_spike in triggers, do: false

    threshold = Map.get(thresholds, "visitor_spike", 50)

    if previous > 0 do
      percentage_increase = ((current - previous) / previous) * 100
      percentage_increase >= threshold
    else
      false
    end
  end

  @doc """
  Build goal completion payload data.
  """
  def build_goal_completion_data(goal, site, attrs \\ %{}) do
    %{
      goal_id: goal.id,
      goal_name: goal.name,
      goal_type: goal.page_path && "page" || "custom_event",
      path: goal.page_path,
      visitor_id: attrs[:visitor_id]
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  @doc """
  Build visitor spike payload data.
  """
  def build_visitor_spike_data(current_visitors, previous_visitors, threshold) do
    percentage_increase = if previous_visitors > 0, do: ((current_visitors - previous_visitors) / previous_visitors) * 100, else: 0

    %{
      current_visitors: current_visitors,
      previous_visitors: previous_visitors,
      percentage_increase: Float.round(percentage_increase, 1),
      threshold_configured: threshold,
      triggered: percentage_increase >= threshold
    }
  end
end
