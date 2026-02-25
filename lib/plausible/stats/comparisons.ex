defmodule Plausible.Stats.Comparisons do
  @moduledoc """
  This module provides functions for comparing query periods.

  It allows you to compare a given period with a previous period or with the
  same period from the previous year. For example, you can compare this month's
  main graph with last month or with the same month from last year.
  """

  alias Plausible.Stats
  alias Plausible.Stats.{Query, DateTimeRange, Time}

  @spec get_comparison_utc_time_range(Stats.Query.t()) :: DateTimeRange.t()
  @doc """
  Generates a `DateTimeRange` representing the comparison period of a given
  `%Query{}` struct (i.e. the `source_query`).

  There are different modes and options that determine the outcome of the
  resulting DateTimeRange. Those are specified under `source_query.include`.

  Currently only historical periods are supported for comparisons (not `realtime`
  and `30m` periods).

  ## Modes (`source_query.include.compare` field)

    * `:previous_period` - shifts back the query by the same number of days the
        source query has.

    * `:year_over_year` - shifts back the query by 1 year.

    * `{:date_range, from, to}` - compares the query using a custom date range.

  ## Options

    * `source_query.include.compare_match_day_of_week`

      Determines whether the comparison query should be adjusted to match the
      day of the week of the source query. When this option is set to true, the
      comparison query is shifted to start on the same day of the week as the
      source query, rather than on the exact same date.

      Example: if the source query starts on Sunday, January 1st, 2023 and the
      `year_over_year` comparison query is configured to `match_day_of_week`, it
      will be shifted to start on Sunday, January 2nd, 2022 instead of January 1st.

      Note: this option has no effect when custom date range mode is used.

  """
  def get_comparison_utc_time_range(%Stats.Query{} = source_query) do
    datetime_range =
      case source_query.include.compare do
        {:datetime_range, from, to} ->
          DateTimeRange.new!(from, to)

        _ ->
          # For 24h period, work directly with datetime ranges to preserve time precision
          if source_query.input_date_range == :"24h" do
            get_comparison_datetime_range(source_query)
          else
            comparison_date_range = get_comparison_date_range(source_query)

            DateTimeRange.new!(
              comparison_date_range.first,
              comparison_date_range.last,
              source_query.timezone
            )
          end
      end

    DateTimeRange.to_timezone(datetime_range, "Etc/UTC")
  end

  def get_comparison_query(
        %Query{comparison_utc_time_range: %DateTimeRange{} = comparison_range} = source_query
      ) do
    source_query
    |> Query.set(utc_time_range: comparison_range)
  end

  @doc """
  Builds comparison query that specifically filters for values appearing in the main query results.

  When querying for comparisons with dimensions and pagination, extra
  filters are added to ensure comparison query returns same set of results
  as main query.
  """
  def add_comparison_filters(comparison_query, main_results_list) do
    comparison_filters =
      Enum.flat_map(main_results_list, &build_comparison_filter(&1, comparison_query))

    comparison_query
    |> add_query_filters(comparison_filters)
  end

  defp add_query_filters(query, []), do: query

  defp add_query_filters(query, [filter]) do
    query
    |> Query.add_filter([:ignore_in_totals_query, filter])
    |> Query.set(pagination: nil)
  end

  defp add_query_filters(query, filters) do
    query
    |> Query.add_filter([:ignore_in_totals_query, [:or, filters]])
    |> Query.set(pagination: nil)
  end

  defp build_comparison_filter(%{dimensions: dimension_labels}, query) do
    query_filters =
      query.dimensions
      |> Enum.zip(dimension_labels)
      |> Enum.reject(fn {dimension, _label} -> Time.time_dimension?(dimension) end)
      |> Enum.map(fn {dimension, label} -> [:is, dimension, [label]] end)

    case query_filters do
      [] -> []
      [filter] -> [filter]
      filters -> [[:and, filters]]
    end
  end

  # For 24h period, shift the datetime range directly to preserve time precision
  defp get_comparison_datetime_range(
         %Query{
           input_date_range: :"24h",
           include: %{compare: :previous_period, compare_match_day_of_week: true}
         } = source_query
       ) do
    days_back = 7
    comparison_start = DateTime.shift(source_query.utc_time_range.first, day: -days_back)
    comparison_end = DateTime.shift(source_query.utc_time_range.last, day: -days_back)

    DateTimeRange.new!(comparison_start, comparison_end)
  end

  defp get_comparison_datetime_range(
         %Query{
           input_date_range: :"24h",
           include: %{compare: :previous_period}
         } = source_query
       ) do
    comparison_start = DateTime.shift(source_query.utc_time_range.first, hour: -24)
    comparison_end = DateTime.shift(source_query.utc_time_range.last, hour: -24)

    DateTimeRange.new!(comparison_start, comparison_end)
  end

  defp get_comparison_datetime_range(
         %Query{
           input_date_range: :"24h",
           include: %{compare: :year_over_year}
         } = source_query
       ) do
    comparison_start = DateTime.shift(source_query.utc_time_range.first, year: -1)
    comparison_end = DateTime.shift(source_query.utc_time_range.last, year: -1)

    DateTimeRange.new!(comparison_start, comparison_end)
  end

  defp get_comparison_date_range(%Query{include: %{compare: :year_over_year}} = source_query) do
    source_date_range = Query.date_range(source_query, trim_trailing: true)

    start_date = source_date_range.first |> Date.shift(year: -1)
    diff_in_days = Date.diff(source_date_range.last, source_date_range.first)
    end_date = Date.add(start_date, diff_in_days)

    Date.range(start_date, end_date)
    |> maybe_match_day_of_week(source_date_range, source_query)
  end

  defp get_comparison_date_range(%Query{include: %{compare: :previous_period}} = source_query) do
    source_date_range = Query.date_range(source_query, trim_trailing: true)

    last = source_date_range.last
    diff_in_days = Date.diff(source_date_range.first, last) - 1

    new_first = Date.add(source_date_range.first, diff_in_days)
    new_last = Date.add(last, diff_in_days)

    Date.range(new_first, new_last)
    |> maybe_match_day_of_week(source_date_range, source_query)
  end

  defp get_comparison_date_range(%Query{include: %{compare: {:date_range, from_date, to_date}}}) do
    Date.range(from_date, to_date)
  end

  # Predefined comparison modes: this_week_vs_last_week
  defp get_comparison_date_range(%Query{include: %{compare: :this_week_vs_last_week}}) do
    today = Date.utc_today()
    # This week: Monday of current week to Sunday of current week
    this_week_start = Date.beginning_of_week(today, :monday)
    this_week_end = Date.end_of_week(today, :monday)
    # Last week: Monday of previous week to Sunday of previous week
    last_week_start = Date.add(this_week_start, -7)
    last_week_end = Date.add(this_week_end, -7)
    Date.range(last_week_start, last_week_end)
  end

  # Predefined comparison modes: this_month_vs_last_month
  defp get_comparison_date_range(%Query{include: %{compare: :this_month_vs_last_month}}) do
    today = Date.utc_today()
    # This month
    this_month_start = Date.beginning_of_month(today)
    this_month_end = Date.end_of_month(today)
    # Last month
    last_month_start = Date.add(this_month_start, -1)
    last_month_end = Date.end_of_month(last_month_start)
    Date.range(last_month_start, last_month_end)
  end

  # Predefined comparison modes: last_7_days_vs_previous_7_days
  defp get_comparison_date_range(%Query{include: %{compare: :last_7_days_vs_previous_7_days}}) do
    today = Date.utc_today()
    # Last 7 days: today - 6 to today (7 days including today)
    last_7_days_start = Date.add(today, -6)
    # Previous 7 days: today - 13 to today - 7
    previous_7_days_start = Date.add(today, -13)
    previous_7_days_end = Date.add(today, -7)
    Date.range(previous_7_days_start, previous_7_days_end)
  end

  defp maybe_match_day_of_week(comparison_date_range, source_date_range, source_query) do
    if source_query.include.compare_match_day_of_week do
      day_to_match = Date.day_of_week(source_date_range.first)

      new_first =
        shift_to_nearest(
          day_to_match,
          comparison_date_range.first,
          source_date_range.first
        )

      days_shifted = Date.diff(new_first, comparison_date_range.first)
      new_last = Date.add(comparison_date_range.last, days_shifted)

      Date.range(new_first, new_last)
    else
      comparison_date_range
    end
  end

  defp shift_to_nearest(day_of_week, date, reject) do
    if Date.day_of_week(date) == day_of_week do
      date
    else
      [next_occurring(day_of_week, date), previous_occurring(day_of_week, date)]
      |> Enum.sort_by(&Date.diff(date, &1))
      |> Enum.reject(&(&1 == reject))
      |> List.first()
    end
  end

  defp next_occurring(day_of_week, date) do
    days_to_add = day_of_week - Date.day_of_week(date)
    days_to_add = if days_to_add > 0, do: days_to_add, else: days_to_add + 7

    Date.add(date, days_to_add)
  end

  defp previous_occurring(day_of_week, date) do
    days_to_subtract = Date.day_of_week(date) - day_of_week
    days_to_subtract = if days_to_subtract > 0, do: days_to_subtract, else: days_to_subtract + 7

    Date.add(date, -days_to_subtract)
  end

  @doc """
  Compares the length of the main query period with the comparison period.

  Returns a map with:
    - `:same_length`: boolean - true if both periods have the same number of days
    - `:main_period_days`: integer - number of days in the main period
    - `:comparison_period_days`: integer - number of days in the comparison period

  This is used to warn users when comparing periods of different lengths (FR-009).
  """
  @spec compare_period_lengths(Stats.Query.t()) :: %{
          same_length: boolean(),
          main_period_days: non_neg_integer(),
          comparison_period_days: non_neg_integer()
        }
  def compare_period_lengths(%Stats.Query{} = source_query) do
    main_date_range = Query.date_range(source_query, trim_trailing: true)
    main_period_days = Date.diff(main_date_range.last, main_date_range.first) + 1

    # Handle both date ranges and datetime ranges (24h periods)
    comparison_period_days =
      if source_query.input_date_range == :"24h" do
        comparison_datetime_range = get_comparison_datetime_range(source_query)
        DateTime.diff(comparison_datetime_range.last, comparison_datetime_range.first, :day)
        |> Kernel.+(1)
      else
        comparison_date_range = get_comparison_date_range(source_query)
        Date.diff(comparison_date_range.last, comparison_date_range.first) + 1
      end

    %{
      same_length: main_period_days == comparison_period_days,
      main_period_days: main_period_days,
      comparison_period_days: comparison_period_days
    }
  end
end
