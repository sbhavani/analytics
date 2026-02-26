defmodule Plausible.Stats.PeriodComparison do
  @moduledoc """
  Context module for time period comparison functionality.

  This module handles:
  - Date range calculation for predefined periods (this week, last week, etc.)
  - Predefined period options with calculated dates
  - Date range validation
  """

  alias Plausible.Stats.DateTimeRange
  alias Plausible.Stats.Compare

  @type period_type :: :day | :week | :month | :quarter | :year
  @type predefined_period :: %{
          name: String.t(),
          period_type: period_type(),
          offset: integer(),
          date_range: %{start_date: Date.t(), end_date: Date.t()}
        }
  @type period :: :this_week | :last_week | :this_month | :last_month | :this_quarter | :last_quarter | :this_year | :last_year

  @periods [:this_week, :last_week, :this_month, :last_month, :this_quarter, :last_quarter, :this_year, :last_year]

  @max_date_range_days 366

  @doc """
  Returns the list of available predefined periods as atoms.
  """
  @spec predefined_periods() :: [period()]
  def predefined_periods, do: @periods

  @doc """
  Returns a human-readable label for a period atom.
  """
  @spec period_label(period()) :: String.t()
  def period_label(:this_week), do: "This Week"
  def period_label(:last_week), do: "Last Week"
  def period_label(:this_month), do: "This Month"
  def period_label(:last_month), do: "Last Month"
  def period_label(:this_quarter), do: "This Quarter"
  def period_label(:last_quarter), do: "Last Quarter"
  def period_label(:this_year), do: "This Year"
  def period_label(:last_year), do: "Last Year"

  @doc """
  Returns the date range for a predefined period based on a reference date.

  ## Examples

      iex> PeriodComparison.predefined_period_range(:this_week, ~D[2026-02-26])
      %{first: ~D[2026-02-23], last: ~D[2026-02-27]}

      iex> PeriodComparison.predefined_period_range(:last_week, ~D[2026-02-26])
      %{first: ~D[2026-02-16], last: ~D[2026-02-22]}
  """
  @spec predefined_period_range(period(), Date.t()) :: %{first: Date.t(), last: Date.t()} | {:error, :invalid_period}
  def predefined_period_range(period, reference_date \\ Date.utc_today())

  def predefined_period_range(:this_week, reference_date) do
    first = Date.beginning_of_week(reference_date, :monday)
    # For this_week, return up to Friday (end of work week)
    last = Date.shift(first, day: 4)
    %{first: first, last: last}
  end

  def predefined_period_range(:last_week, reference_date) do
    this_week_first = Date.beginning_of_week(reference_date, :monday)
    last_week_first = Date.shift(this_week_first, day: -7)
    last_week_last = Date.shift(this_week_first, day: -1)
    %{first: last_week_first, last: last_week_last}
  end

  def predefined_period_range(:this_month, reference_date) do
    first = Date.beginning_of_month(reference_date)
    last = Date.end_of_month(reference_date)
    %{first: first, last: last}
  end

  def predefined_period_range(:last_month, reference_date) do
    this_month_first = Date.beginning_of_month(reference_date)
    last_month_first = Date.shift(this_month_first, month: -1)
    last_month_last = Date.shift(this_month_first, day: -1)
    %{first: last_month_first, last: last_month_last}
  end

  def predefined_period_range(:this_quarter, reference_date) do
    first = quarter_beginning(reference_date)
    last = quarter_end(reference_date)
    %{first: first, last: last}
  end

  def predefined_period_range(:last_quarter, reference_date) do
    this_quarter_first = quarter_beginning(reference_date)
    last_quarter_first = Date.shift(this_quarter_first, month: -3)
    last_quarter_last = Date.shift(this_quarter_first, day: -1)
    %{first: last_quarter_first, last: last_quarter_last}
  end

  def predefined_period_range(:this_year, reference_date) do
    first = Date.new!(reference_date.year, 1, 1)
    last = Date.new!(reference_date.year, 12, 31)
    %{first: first, last: last}
  end

  def predefined_period_range(:last_year, reference_date) do
    first = Date.new!(reference_date.year - 1, 1, 1)
    last = Date.new!(reference_date.year - 1, 12, 31)
    %{first: first, last: last}
  end

  def predefined_period_range(_period, _reference_date) do
    {:error, :invalid_period}
  end

  # Helper functions for quarter calculations
  defp quarter_beginning(date) do
    month = date.month
    quarter_month = ((month - 1) |> div(3) |> Kernel.*(3)) + 1
    Date.new!(date.year, quarter_month, 1)
  end

  defp quarter_end(date) do
    month = date.month
    quarter_month = ((month - 1) |> div(3) |> Kernel.*(3)) + 1
    end_month = quarter_month + 2

    if end_month > 12 do
      Date.new!(date.year + 1, end_month - 12, 1)
      |> Date.end_of_month()
    else
      Date.new!(date.year, end_month, 1)
      |> Date.end_of_month()
    end
  end

  @doc """
  Returns a list of predefined period options with calculated date ranges.

  ## Examples

      iex> PeriodComparison.predefined_periods(~D[2026-02-26])
      [
        %{name: "This Week", period_type: :week, offset: 0, date_range: %{start_date: ~D[2026-02-23], end_date: ~D[2026-02-29]}},

        ...
      ]
  """
  @spec predefined_periods(Date.t()) :: [predefined_period()]
  def predefined_periods(for_date \\ Date.utc_today()) do
    [
      this_week(for_date),
      last_week(for_date),
      this_month(for_date),
      last_month(for_date),
      this_quarter(for_date),
      last_quarter(for_date),
      this_year(for_date),
      last_year(for_date)
    ]
  end

  @doc """
  Calculates the date range for "this week" starting from Monday.
  """
  @spec this_week(Date.t()) :: predefined_period()
  def this_week(for_date \\ Date.utc_today()) do
    start_date = Date.beginning_of_week(for_date, :monday)
    end_date = Date.end_of_week(for_date, :monday)

    %{
      name: "This Week",
      period_type: :week,
      offset: 0,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "last week" (the week before this week).
  """
  @spec last_week(Date.t()) :: predefined_period()
  def last_week(for_date \\ Date.utc_today()) do
    this_w = this_week(for_date)
    start_date = Date.shift(this_w.date_range.start_date, week: -1)
    end_date = Date.shift(this_w.date_range.end_date, week: -1)

    %{
      name: "Last Week",
      period_type: :week,
      offset: -1,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "this month".
  """
  @spec this_month(Date.t()) :: predefined_period()
  def this_month(for_date \\ Date.utc_today()) do
    start_date = Date.beginning_of_month(for_date)
    end_date = Date.end_of_month(for_date)

    %{
      name: "This Month",
      period_type: :month,
      offset: 0,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "last month" (the month before this month).
  """
  @spec last_month(Date.t()) :: predefined_period()
  def last_month(for_date \\ Date.utc_today()) do
    start_date = Date.shift(Date.beginning_of_month(for_date), month: -1)
    end_date = Date.shift(Date.end_of_month(for_date), month: -1)

    %{
      name: "Last Month",
      period_type: :month,
      offset: -1,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "this quarter".
  """
  @spec this_quarter(Date.t()) :: predefined_period()
  def this_quarter(for_date \\ Date.utc_today()) do
    quarter = (Date.month(for_date) - 1) |> div(3) |> +1
    start_date = Date.new!(for_date.year, (quarter - 1) * 3 + 1, 1)

    end_month = quarter * 3
    end_date = Date.end_of_month(Date.new!(for_date.year, end_month, 1))

    %{
      name: "This Quarter",
      period_type: :quarter,
      offset: 0,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "last quarter" (the quarter before this quarter).
  """
  @spec last_quarter(Date.t()) :: predefined_period()
  def last_quarter(for_date \\ Date.utc_today()) do
    this_q = this_quarter(for_date)
    start_date = Date.shift(this_q.date_range.start_date, month: -3)
    end_date = Date.shift(this_q.date_range.end_date, month: -3)

    %{
      name: "Last Quarter",
      period_type: :quarter,
      offset: -1,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "this year".
  """
  @spec this_year(Date.t()) :: predefined_period()
  def this_year(for_date \\ Date.utc_today()) do
    start_date = Date.new!(for_date.year, 1, 1)
    end_date = Date.new!(for_date.year, 12, 31)

    %{
      name: "This Year",
      period_type: :year,
      offset: 0,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Calculates the date range for "last year" (the year before this year).
  """
  @spec last_year(Date.t()) :: predefined_period()
  def last_year(for_date \\ Date.utc_today()) do
    start_date = Date.new!(for_date.year - 1, 1, 1)
    end_date = Date.new!(for_date.year - 1, 12, 31)

    %{
      name: "Last Year",
      period_type: :year,
      offset: -1,
      date_range: %{start_date: start_date, end_date: end_date}
    }
  end

  @doc """
  Validates a date range.

  Returns `:ok` if valid, or `{:error, reason}` if invalid.

  Validation rules:
  - start_date must be before or equal to end_date
  - Date range cannot exceed #{@max_date_range_days} days
  """
  @spec validate_date_range(Date.t(), Date.t()) :: :ok | {:error, String.t()}
  def validate_date_range(start_date, end_date) do
    cond do
      Date.compare(start_date, end_date) == :gt ->
        {:error, "Start date must be before or equal to end date"}

      Date.diff(end_date, start_date) > @max_date_range_days ->
        {:error, "Date range cannot exceed #{@max_date_range_days} days"}

      true ->
        :ok
    end
  end

  @doc """
  Calculates the comparison period for a given period type and offset.

  This is useful for generating "previous period" or "year over year" comparisons.

  ## Examples

      # Get last week from this week
      iex> PeriodComparison.comparison_period(:week, 0, -1, ~D[2026-02-26])
      %{start_date: ~D[2026-02-10], end_date: ~D[2026-02-16]}

      # Get same week last year (year over year)
      iex> PeriodComparison.comparison_period(:week, 0, -52, ~D[2026-02-26])
      %{start_date: ~D[2025-02-24], end_date: ~D[2025-03-02]}
  """
  @spec comparison_period(period_type(), integer(), integer(), Date.t()) :: %{
          start_date: Date.t(),
          end_date: Date.t()
        }
  def comparison_period(period_type, current_offset, comparison_offset, for_date \\ Date.utc_today()) do
    current = calculate_period(period_type, current_offset, for_date)
    shift = period_shift(period_type, current_offset, comparison_offset)

    %{
      start_date: Date.shift(current.start_date, shift),
      end_date: Date.shift(current.end_date, shift)
    }
  end

  defp calculate_period(:week, offset, for_date) do
    base = if offset <= 0, do: this_week(for_date), else: this_week(for_date)
    start_date = Date.shift(base.date_range.start_date, week: offset)
    end_date = Date.shift(base.date_range.end_date, week: offset)
    %{start_date: start_date, end_date: end_date}
  end

  defp calculate_period(:month, offset, for_date) do
    base = if offset <= 0, do: this_month(for_date), else: this_month(for_date)
    start_date = Date.shift(base.date_range.start_date, month: offset)
    end_date = Date.shift(base.date_range.end_date, month: offset)
    %{start_date: start_date, end_date: end_date}
  end

  defp calculate_period(:quarter, offset, for_date) do
    base = if offset <= 0, do: this_quarter(for_date), else: this_quarter(for_date)
    start_date = Date.shift(base.date_range.start_date, month: offset * 3)
    end_date = Date.shift(base.date_range.end_date, month: offset * 3)
    %{start_date: start_date, end_date: end_date}
  end

  defp calculate_period(:year, offset, for_date) do
    base = if offset <= 0, do: this_year(for_date), else: this_year(for_date)
    start_date = Date.shift(base.date_range.start_date, year: offset)
    end_date = Date.shift(base.date_range.end_date, year: offset)
    %{start_date: start_date, end_date: end_date}
  end

  defp period_shift(_period_type, current_offset, comparison_offset) do
    comparison_offset - current_offset
  end

  @doc """
  Converts a date range to a DateTimeRange struct for use with the stats query system.
  """
  @spec to_datetime_range(%{start_date: Date.t(), end_date: Date.t()}, String.t()) ::
          DateTimeRange.t()
  def to_datetime_range(%{start_date: start_date, end_date: end_date}, timezone)
      when is_binary(timezone) do
    DateTimeRange.new!(start_date, end_date, timezone)
  end

  @doc """
  Builds a comparison date range based on a primary period and comparison type.

  This function takes the primary date range and calculates what the comparison
  period should be based on the comparison type (previous_period or year_over_year).

  ## Parameters

    * `primary_date_range` - The date range of the primary period as %{first: Date.t(), last: Date.t()}
    * `comparison_type` - Either `:previous_period` or `:year_over_year`
    * `for_date` - The reference date for calculations (defaults to today)

  ## Examples

      iex> PeriodComparison.build_comparison_date_range(%{first: ~D[2026-02-23], last: ~D[2026-02-29]}, :previous_period)
      %{start_date: ~D[2026-02-16], end_date: ~D[2026-02-22]}

      iex> PeriodComparison.build_comparison_date_range(%{first: ~D[2026-01-01], last: ~D[2026-12-31]}, :year_over_year)
      %{start_date: ~D[2025-01-01], end_date: ~D[2025-12-31]}
  """
  @spec build_comparison_date_range(%{first: Date.t(), last: Date.t()}, :previous_period | :year_over_year(), Date.t()) :: %{
          start_date: Date.t(),
          end_date: Date.t()
        }
  def build_comparison_date_range(%{first: primary_start_date, last: primary_end_date}, :previous_period, _for_date) do
    # For previous period, calculate the exact same number of days before the primary period
    days_diff = Date.diff(primary_start_date, primary_end_date)

    comparison_start_date = Date.shift(primary_start_date, day: -abs(days_diff) - 1)
    comparison_end_date = Date.shift(primary_end_date, day: -abs(days_diff) - 1)

    %{start_date: comparison_start_date, end_date: comparison_end_date}
  end

  def build_comparison_date_range(%{first: primary_start_date, last: primary_end_date}, :year_over_year, _for_date) do
    comparison_start_date = Date.shift(primary_start_date, year: -1)
    comparison_end_date = Date.shift(primary_end_date, year: -1)

    %{start_date: comparison_start_date, end_date: comparison_end_date}
  end

  @doc """
  Returns a list of available comparison type options.

  ## Examples

      iex> PeriodComparison.comparison_types()
      [:previous_period, :year_over_year]
  """
  @spec comparison_types() :: [:previous_period | :year_over_year]
  def comparison_types do
    [:previous_period, :year_over_year]
  end

  @doc """
  Returns the human-readable name for a comparison type.

  ## Examples

      iex> PeriodComparison.comparison_type_name(:previous_period)
      "Previous Period"

      iex> PeriodComparison.comparison_type_name(:year_over_year)
      "Year Over Year"
  """
  @spec comparison_type_name(:previous_period | :year_over_year()) :: String.t()
  def comparison_type_name(:previous_period), do: "Previous Period"
  def comparison_type_name(:year_over_year), do: "Year Over Year"

  @doc """
  Calculates the date range for a custom period specified by the user.

  This is used when users manually enter custom start and end dates
  for comparison.

  ## Examples

      iex> PeriodComparison.custom_period(~D[2026-02-01], ~D[2026-02-15])
      %{start_date: ~D[2026-02-01], end_date: ~D[2026-02-15]}
  """
  @spec custom_period(Date.t(), Date.t()) :: %{start_date: Date.t(), end_date: Date.t()}
  def custom_period(start_date, end_date) do
    %{start_date: start_date, end_date: end_date}
  end

  # ========== Zero Value Handling ==========

  @doc """
  Calculates the percentage change between two values with zero value handling.

  When either value is zero (or nil), returns `:na` to indicate that
  a percentage change cannot be calculated (display as "N/A" in UI).

  This handles the edge case where comparing zero to zero (or zero to any value)
  doesn't make sense from a percentage perspective.

  ## Examples

      iex> PeriodComparison.calculate_change_with_zero_handling(100, 150)
      50

      iex> PeriodComparison.calculate_change_with_zero_handling(0, 0)
      :na

      iex> PeriodComparison.calculate_change_with_zero_handling(0, 10)
      :na

      iex> PeriodComparison.calculate_change_with_zero_handling(10, 0)
      -100

      iex> PeriodComparison.calculate_change_with_zero_handling(nil, 10)
      nil

      iex> PeriodComparison.calculate_change_with_zero_handling(10, nil)
      nil
  """
  @spec calculate_change_with_zero_handling(any(), any()) :: integer() | :na | nil
  def calculate_change_with_zero_handling(old_value, new_value) do
    cond do
      is_nil(old_value) or is_nil(new_value) ->
        nil

      old_value == 0 and new_value == 0 ->
        :na

      old_value == 0 ->
        :na

      true ->
        Compare.percent_change(old_value, new_value)
    end
  end

  @doc """
  Returns true if the change value represents "N/A" (cannot calculate percentage).
  """
  @spec na?(:na | integer() | nil) :: boolean()
  def na?(:na), do: true
  def na?(_), do: false

  @doc """
  Formats the change value for display.

  Returns:
  - "N/A" for :na values
  - Percentage string (e.g., "+50%", "-25%") for numbers
  - nil for nil values
  """
  @spec format_change(integer() | :na | nil) :: String.t() | nil
  def format_change(:na), do: "N/A"
  def format_change(nil), do: nil
  def format_change(value) when is_integer(value) do
    prefix = if value > 0, do: "+", else: ""
    "#{prefix}#{value}%"
  end
end
