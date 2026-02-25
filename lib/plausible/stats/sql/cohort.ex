defmodule Plausible.Stats.SQL.Cohort do
  @moduledoc """
  SQL query builder for cohort analysis.

  Builds ClickHouse queries to calculate user retention over time,
  grouping users by their acquisition date and tracking subsequent visits.
  """

  import Ecto.Query
  alias Plausible.Stats.Query

  @doc """
  Builds a cohort query for the given period and date range.

  ## Parameters
  - site: The site to query
  - period: The cohort period - "daily", "weekly", or "monthly"
  - from: Start date for cohort analysis
  - to: End date for cohort analysis

  ## Returns
  An Ecto.Query that calculates cohort retention
  """
  def build_cohort_query(site, period, from, to) when period in ["daily", "weekly", "monthly"] do
    date_range = %{
      from: parse_date(from),
      to: parse_date(to)
    }

    # Get the first visit date for each visitor (acquisition date)
    acquisition_subquery =
      from(e in "events_v2",
        where: e.site_id == ^site.id,
        where: e.timestamp >= ^date_range.from,
        where: e.timestamp <= ^date_range.to,
        where: e.sign == 1,
        select: %{
          visitor_id: e.visitor_id,
          acquisition_date: acquisition_date(e.timestamp, period)
        },
        group_by: e.visitor_id
      )

    # Main query to calculate retention
    # Filter events to only include those within the retention window from acquisition
    from(e in "events_v2",
      join: a in subquery(acquisition_subquery),
      on: e.visitor_id == a.visitor_id,
      where: e.site_id == ^site.id,
      where: e.sign == 1,
      where: e.timestamp >= a.acquisition_date,
      where: e.timestamp <= retention_max_date(a.acquisition_date, period),
      select: %{
        cohort_date: a.acquisition_date,
        retention_period: retention_period(e.timestamp, a.acquisition_date, period),
        visitor_id: e.visitor_id
      },
      group_by: [a.acquisition_date, retention_period(e.timestamp, a.acquisition_date, period)]
    )
  end

  @doc """
  Returns the SQL fragment for extracting the acquisition date based on period.
  """
  def acquisition_date(timestamp, "daily") do
    fragment("toDate(?)", timestamp)
  end

  def acquisition_date(timestamp, "weekly") do
    # Get the Monday of the week (ClickHouse uses week Monday as start)
    fragment("toStartOfWeek(toDate(?), 1)", timestamp)
  end

  def acquisition_date(timestamp, "monthly") do
    fragment("toStartOfMonth(?)", timestamp)
  end

  @doc """
  Returns the SQL fragment for calculating the retention period number.
  The period number indicates how many periods after acquisition the visit occurred.
  """
  def retention_period(timestamp, acquisition_date, "daily") do
    fragment("dateDiff('day', ?, ?)", acquisition_date, timestamp)
  end

  def retention_period(timestamp, acquisition_date, "weekly") do
    fragment("floor(dateDiff('week', ?, ?))", acquisition_date, timestamp)
  end

  def retention_period(timestamp, acquisition_date, "monthly") do
    fragment("floor(dateDiff('month', ?, ?))", acquisition_date, timestamp)
  end

  @doc """
  Formats the cohort date for display based on period type.
  """
  def format_cohort_date(date, "daily") do
    fragment("formatDateTime(?, '%Y-%m-%d')", date)
  end

  def format_cohort_date(date, "weekly") do
    fragment("formatDateTime(?, '%Y-W%V')", date)
  end

  def format_cohort_date(date, "monthly") do
    fragment("formatDateTime(?, '%Y-%m')", date)
  end

  @doc """
  Calculates retention rate for a specific cohort and period.
  """
  def retention_rate(cohort_size, retained_count) do
    fragment("if(? > 0, round(? / ? * 100, 2), 0)", cohort_size, retained_count, cohort_size)
  end

  # Helper to parse date string or use default
  defp parse_date(nil), do: Date.add(Date.utc_today(), -90)
  defp parse_date(date) when is_binary(date), do: Date.from_iso8601!(date)
  defp parse_date(date), do: date

  @doc """
  Returns the retention window (max periods to track) for each cohort type.
  """
  def retention_window("daily"), do: 30
  def retention_window("weekly"), do: 12
  def retention_window("monthly"), do: 12

  @doc """
  Returns the SQL fragment for the maximum retention date based on period.
  """
  def retention_max_date(acquisition_date, "daily") do
    fragment("dateAdd(day, ?, ?)", ^retention_window("daily"), acquisition_date)
  end

  def retention_max_date(acquisition_date, "weekly") do
    fragment("dateAdd(week, ?, ?)", ^retention_window("weekly"), acquisition_date)
  end

  def retention_max_date(acquisition_date, "monthly") do
    fragment("dateAdd(month, ?, ?)", ^retention_window("monthly"), acquisition_date)
  end
end
