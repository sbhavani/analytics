defmodule Plausible.Webhooks.Triggers.VisitorSpike do
  @moduledoc """
  Evaluates visitor spike triggers.
  """

  alias Plausible.ClickhouseRepo
  alias Plausible.Stats.Query

  @doc """
  Checks if a visitor spike trigger should fire for a site.

  ## Parameters
  - site: The site to check
  - threshold: The percentage increase required to trigger (e.g., 50 for 50%)

  ## Returns
  - {:ok, event_data} if trigger should fire
  - {:ok, nil} if trigger should not fire
  - {:error, reason} on error
  """
  def evaluate(site, threshold) do
    with {:ok, current_visitors} <- get_current_visitors(site),
         {:ok, previous_visitors} <- get_previous_visitors(site),
         :ok <- check_threshold(current_visitors, previous_visitors, threshold) do
      change_percent = calculate_change_percent(current_visitors, previous_visitors)

      {:ok,
       %{
         event_id: UUID.uuid4(),
         site_id: site.id,
         site_domain: site.domain,
         current_visitors: current_visitors,
         previous_visitors: previous_visitors,
         change_percent: change_percent,
         threshold: threshold
       }}
    else
      :skip -> {:ok, nil}
      error -> error
    end
  end

  defp get_current_visitors(site) do
    query = """
    SELECT count(DISTINCT session_id)
    FROM events
    WHERE site_id = toUUID($1)
    AND timestamp >= now() - INTERVAL '5 minute'
    """

    result = ClickhouseRepo.query_row(query, [site.id])

    case result do
      {:ok, %{num_rows: 1, rows: [[count]]}} ->
        {:ok, count}

      _ ->
        {:ok, 0}
    end
  end

  defp get_previous_visitors(site) do
    query = """
    SELECT count(DISTINCT session_id)
    FROM events
    WHERE site_id = toUUID($1)
    AND timestamp >= now() - INTERVAL '1 hour'
    AND timestamp < now() - INTERVAL '5 minute'
    """

    result = ClickhouseRepo.query_row(query, [site.id])

    case result do
      {:ok, %{num_rows: 1, rows: [[count]]}} ->
        {:ok, count}

      _ ->
        {:ok, 0}
    end
  end

  defp check_threshold(current, previous, threshold) do
    cond do
      previous == 0 and current > 0 ->
        # If there were no visitors before but there are now, don't trigger
        # (this is likely a new site or first visitors)
        :skip

      previous == 0 and current == 0 ->
        :skip

      true ->
        change_percent = calculate_change_percent(current, previous)

        if change_percent >= threshold do
          :ok
        else
          :skip
        end
    end
  end

  defp calculate_change_percent(current, previous) when previous > 0 do
    round((current - previous) / previous * 100)
  end

  defp calculate_change_percent(_, _), do: 0
end
