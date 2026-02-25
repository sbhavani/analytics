defmodule Plausible.Webhooks.Triggers.GoalCompletion do
  @moduledoc """
  Evaluates goal completion triggers.
  """

  alias Plausible.ClickhouseRepo
  alias Plausible.Repo
  alias Plausible.Goal

  @doc """
  Checks if a goal completion trigger should fire for a site.

  ## Parameters
  - site: The site to check
  - goal_id: Optional goal ID to filter by (nil means all goals)

  ## Returns
  - {:ok, event_data} if trigger should fire
  - {:ok, nil} if no goals completed
  - {:error, reason} on error
  """
  def evaluate(site, goal_id \\ nil) do
    with {:ok, goals} <- get_completed_goals(site, goal_id),
         {:ok, goals} <- filter_recent_goals(goals) do
      if Enum.empty?(goals) do
        {:ok, nil}
      else
        # Group by goal and count
        event_data = %{
          event_id: UUID.uuid4(),
          site_id: site.id,
          site_domain: site.domain,
          goals: Enum.map(goals, &%{goal_id: &1.goal_id, goal_name: &1.goal_name, count: &1.count})
        }

        {:ok, event_data}
      end
    end
  end

  defp get_completed_goals(site, nil) do
    # Get all goals for the site
    goals = Repo.all(from g in Goal, where: g.site_id == ^site.id)

    if Enum.empty?(goals) do
      {:ok, []}
    else
      goal_ids = Enum.map(goals, & &1.id)

      query = """
      SELECT goal_id, count(*) as count
      FROM events
      WHERE site_id = toUUID($1)
      AND goal_id IN (?)
      AND timestamp >= now() - INTERVAL '1 minute'
      GROUP BY goal_id
      """

      # Convert goal IDs to strings for the query
      goal_id_strings = Enum.map(goal_ids, &to_string/1)

      result = ClickhouseRepo.query_row(query, [site.id, goal_id_strings])

      case result do
        {:ok, %{num_rows: 1, rows: rows}} when rows != [] ->
          completed = Enum.map(rows, fn [goal_id, count] ->
            goal = Enum.find(goals, fn g -> to_string(g.id) == goal_id end)
            %{goal_id: goal_id, goal_name: goal && goal.name, count: count}
          end)
          {:ok, completed}

        _ ->
          {:ok, []}
      end
    end
  end

  defp get_completed_goals(site, goal_id) do
    goal = Repo.get(Goal, goal_id)

    if is_nil(goal) or goal.site_id != site.id do
      {:ok, []}
    else
      query = """
      SELECT count(*) as count
      FROM events
      WHERE site_id = toUUID($1)
      AND goal_id = $2
      AND timestamp >= now() - INTERVAL '1 minute'
      """

      result = ClickhouseRepo.query_row(query, [site.id, to_string(goal_id)])

      case result do
        {:ok, %{num_rows: 1, rows: [[count]]}} when count > 0 ->
          {:ok, [%{goal_id: to_string(goal_id), goal_name: goal.name, count: count}]}

        _ ->
          {:ok, []}
      end
    end
  end

  defp filter_recent_goals(goals) do
    # For now, just return all goals
    # Could add logic to track last triggered time per webhook
    {:ok, goals}
  end
end
