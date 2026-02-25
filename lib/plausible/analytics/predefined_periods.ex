defmodule Plausible.Analytics.PredefinedPeriods do
  @moduledoc """
  Provides predefined period pair calculations for quick comparison options.
  """

  alias Plausible.Analytics.PeriodComparison

  @type period_type :: :this_week | :last_week | :this_month | :last_month | :this_quarter | :last_quarter | :this_year | :last_year

  @type predefined_pair :: %{
          id: String.t(),
          name: String.t(),
          current_period_type: period_type(),
          comparison_period_type: period_type()
        }

  @doc """
  Returns all predefined period pairs.
  """
  def all_pairs do
    [
      %{
        id: "this_week_vs_last_week",
        name: "This Week vs Last Week",
        current_period_type: :this_week,
        comparison_period_type: :last_week
      },
      %{
        id: "this_month_vs_last_month",
        name: "This Month vs Last Month",
        current_period_type: :this_month,
        comparison_period_type: :last_month
      },
      %{
        id: "this_quarter_vs_last_quarter",
        name: "This Quarter vs Last Quarter",
        current_period_type: :this_quarter,
        comparison_period_type: :last_quarter
      },
      %{
        id: "this_year_vs_last_year",
        name: "This Year vs Last Year",
        current_period_type: :this_year,
        comparison_period_type: :last_year
      }
    ]
  end

  @doc """
  Gets a predefined pair by ID.
  """
  def get_pair(id) do
    Enum.find(all_pairs(), fn pair -> pair.id == id end)
  end

  @doc """
  Calculates the current and comparison periods for a given predefined pair.
  """
  def calculate_periods(pair_id) do
    case get_pair(pair_id) do
      nil ->
        {:error, :unknown_pair}

      pair ->
        current = calculate_period(pair.current_period_type)
        comparison = calculate_period(pair.comparison_period_type)
        {:ok, current, comparison}
    end
  end

  @doc """
  Calculates the period dates for a given period type.
  """
  def calculate_period(:this_week) do
    today = Date.utc_today()
    # Get the start of the current week (Monday)
    days_to_monday = Date.day_of_week(today) - 1
    week_start = Date.add(today, -days_to_monday)
    week_end = Date.add(week_start, 6)

    PeriodComparison.new_time_period(week_start, week_end,
      label: "This Week",
      period_type: :predefined
    )
  end

  def calculate_period(:last_week) do
    today = Date.utc_today()
    days_to_monday = Date.day_of_week(today) - 1
    this_week_start = Date.add(today, -days_to_monday)
    last_week_start = Date.add(this_week_start, -7)
    last_week_end = Date.add(last_week_start, 6)

    PeriodComparison.new_time_period(last_week_start, last_week_end,
      label: "Last Week",
      period_type: :predefined
    )
  end

  def calculate_period(:this_month) do
    today = Date.utc_today()
    {:ok, month_start} = Date.new(today.year, today.month, 1)

    # End of month - use the last day of the current month
    month_end = Date.end_of_month(today)

    PeriodComparison.new_time_period(month_start, month_end,
      label: "This Month",
      period_type: :predefined
    )
  end

  def calculate_period(:last_month) do
    today = Date.utc_today()

    # Go back one month
    last_month_year = if(today.month == 1, do: today.year - 1, else: today.year)
    last_month_month = if(today.month == 1, do: 12, else: today.month - 1)

    {:ok, month_start} = Date.new(last_month_year, last_month_month, 1)
    month_end = Date.end_of_month(month_start)

    PeriodComparison.new_time_period(month_start, month_end,
      label: "Last Month",
      period_type: :predefined
    )
  end

  def calculate_period(:this_quarter) do
    today = Date.utc_today()
    current_quarter = ((today.month - 1) |> div(3)) + 1
    quarter_start_month = (current_quarter - 1) * 3 + 1

    {:ok, quarter_start} = Date.new(today.year, quarter_start_month, 1)

    # End of quarter
    quarter_end_month = quarter_start_month + 2
    quarter_end_year = today.year
    {:ok, quarter_end} = Date.new(quarter_end_year, quarter_end_month, 1)
    quarter_end = Date.end_of_month(quarter_end)

    PeriodComparison.new_time_period(quarter_start, quarter_end,
      label: "This Quarter",
      period_type: :predefined
    )
  end

  def calculate_period(:last_quarter) do
    today = Date.utc_today()
    current_quarter = ((today.month - 1) |> div(3)) + 1

    # Go back one quarter
    {last_quarter_year, last_quarter_month} = if current_quarter == 1 do
      {today.year - 1, 10}
    else
      {today.year, (current_quarter - 2) * 3 + 1}
    end

    {:ok, quarter_start} = Date.new(last_quarter_year, last_quarter_month, 1)

    # End of quarter
    quarter_end_month = last_quarter_month + 2
    {:ok, quarter_end} = Date.new(last_quarter_year, quarter_end_month, 1)
    quarter_end = Date.end_of_month(quarter_end)

    PeriodComparison.new_time_period(quarter_start, quarter_end,
      label: "Last Quarter",
      period_type: :predefined
    )
  end

  def calculate_period(:this_year) do
    today = Date.utc_today()
    year_start = %{year: today.year, month: 1, day: 1}
    year_end = %{year: today.year, month: 12, day: 31}

    PeriodComparison.new_time_period(year_start, year_end,
      label: "This Year",
      period_type: :predefined
    )
  end

  def calculate_period(:last_year) do
    today = Date.utc_today()
    last_year = today.year - 1

    year_start = %{year: last_year, month: 1, day: 1}
    year_end = %{year: last_year, month: 12, day: 31}

    PeriodComparison.new_time_period(year_start, year_end,
      label: "Last Year",
      period_type: :predefined
    )
  end
end
