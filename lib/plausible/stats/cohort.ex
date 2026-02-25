defmodule Plausible.Stats.Cohort do
  @moduledoc """
  Cohort analysis - groups users by acquisition date and tracks retention over time.
  """

  use Plausible.ClickhouseRepo

  @default_cohort_periods 12

  @type cohort_row :: %{
          cohort_date: Date.t(),
          total_users: non_neg_integer(),
          retention: [float()]
        }

  @type cohort_table :: %{
          cohorts: [cohort_row()],
          period_labels: [String.t()],
          meta: %{
            cohort_periods: non_neg_integer(),
            date_range: %{from: String.t(), to: String.t()}
          }
        }

  @doc """
  Fetches cohort retention data for a site.

  ## Parameters

    * site - The site to fetch data for
    * date_range - A tuple of {from_date, to_date}
    * options - Optional keyword list with:
      * :periods - Number of cohort periods to include (default: 12)
      * :site_id - Override site_id for testing

  ## Returns

  %{cohorts: [...], period_labels: [...], meta: %{...}}
  """
  @spec fetch_cohort_data(Plausible.Site.t(), Date.Range.t(), keyword()) :: cohort_table()
  def fetch_cohort_data(site, date_range, opts \\ []) do
    periods = Keyword.get(opts, :periods, @default_cohort_periods)
    site_id = Keyword.get(opts, :site_id, site.id)

    from_date = Date.range(from: date_range)
    to_date = Date.range(to: date_range)

    cohorts = query_cohorts(site_id, date_range, periods)

    build_cohort_table(cohorts, periods, from_date, to_date)
  end

  defp query_cohorts(site_id, date_range, periods) do
    from_date = date_range.first
    to_date = date_range.last

    # Step 1: Get cohort dates (first session per user) and all session dates
    cohort_data = fetch_user_cohorts(site_id, from_date, to_date)

    # If no data, return empty cohorts
    if Enum.empty?(cohort_data) do
      generate_empty_cohorts(date_range, periods)
    else
      # Step 2: Calculate retention for each cohort
      calculate_retention(cohort_data, periods)
    end
  end

  # Fetch users with their cohort (first session) dates and subsequent sessions
  defp fetch_user_cohorts(site_id, from_date, to_date) do
    # Query all sessions within the date range, then do grouping in Elixir
    sessions_query =
      from(s in "sessions_v2",
        where: s.site_id == ^site_id,
        where: s.start >= ^from_date,
        where: s.start <= ^to_date,
        select: %{
          user_id: s.user_id,
          session_start: s.start
        }
      )

    sessions = ClickhouseRepo.all(sessions_query)

    # Group by user to find first session (cohort) and all session months
    user_sessions =
      Enum.group_by(sessions, & &1.user_id)

    Enum.map(user_sessions, fn {user_id, user_session_list} ->
      # Find the earliest session for this user (cohort)
      cohort_date =
        user_session_list
        |> Enum.map(& &1.session_start)
        |> Enum.min()
        |> then(fn dt -> %{dt | day: 1} end)

      # Get all unique session months for this user
      session_months =
        user_session_list
        |> Enum.map(fn s -> %{s.session_start | day: 1} end)
        |> Enum.uniq()

      %{
        user_id: user_id,
        cohort_date: cohort_date,
        session_months: session_months
      }
    end)
  end

  # Calculate retention rates for each cohort
  defp calculate_retention(user_cohorts, periods) do
    # Group users by their cohort month
    cohorts_by_month =
      Enum.group_by(user_cohorts, & &1.cohort_date)

    # For each cohort month, calculate retention rates
    Enum.map(cohorts_by_month, fn {cohort_date, users} ->
      total_users = length(users)

      retention =
        Enum.map(0..(periods - 1), fn period ->
          # For period 0, retention is always 100%
          if period == 0 do
            1.0
          else
            # Calculate target month for this period
            target_month = Date.add(cohort_date, period * 30)

            # Count users who had a session in this month
            retained_count =
              users
              |> Enum.filter(fn user ->
                Enum.any?(user.session_months, fn m -> m == target_month end)
              end)
              |> length()

            if total_users > 0 do
              min(1.0, retained_count / total_users)
            else
              0.0
            end
          end
        end)

      %{
        cohort_date: cohort_date,
        total_users: total_users,
        retention: retention
      }
    end)
    |> Enum.sort_by(& &1.cohort_date, {:desc, Date})
  end

  # Generate empty cohorts when no data exists
  defp generate_empty_cohorts(date_range, periods) do
    from_date = %{date_range.first | day: 1}
    to_date = %{date_range.last | day: 1}

    # Generate cohorts from to_date backwards for the number of periods
    months_in_range = ceil(Date.diff(to_date, from_date) / 30) + 1

    Enum.map(0..(months_in_range - 1), fn offset ->
      cohort_date = Date.add(to_date, -offset * 30)

      retention = Enum.map(0..(periods - 1), &if(&1 == 0, do: 1.0, else: 0.0)

      %{
        cohort_date: cohort_date,
        total_users: 0,
        retention: retention
      }
    end)
    |> Enum.sort_by(& &1.cohort_date, {:desc, Date})
  end

  defp build_cohort_table(cohorts, periods, from_date, to_date) do
    period_labels = Enum.map(0..(periods - 1), &"Month #{&1}")

    %{
      cohorts: cohorts,
      period_labels: period_labels,
      meta: %{
        cohort_periods: periods,
        date_range: %{
          from: Date.to_iso8601(from_date),
          to: Date.to_iso8601(to_date)
        }
      }
    }
  end

  @doc """
  Validates cohort query parameters.
  """
  @spec validate_params(map()) :: {:ok, keyword()} | {:error, String.t()}
  def validate_params(params) do
    periods = Map.get(params, "cohort_periods", "12") |> String.to_integer()

    cond do
      periods < 1 ->
        {:error, "cohort_periods must be at least 1"}

      periods > 24 ->
        {:error, "cohort_periods cannot exceed 24"}

      true ->
        {:ok, periods: periods}
    end
  end
end
