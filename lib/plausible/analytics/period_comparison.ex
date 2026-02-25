defmodule Plausible.Analytics.PeriodComparison do
  @moduledoc """
  Context module for period comparison calculations.
  Provides date range validation and comparison result calculations.
  """

  require Logger

  @type period_type :: :predefined | :custom

  @type t :: %__MODULE__{
          start_date: Date.t(),
          end_date: Date.t(),
          label: String.t() | nil,
          period_type: period_type()
        }

  defstruct [:start_date, :end_date, :label, :period_type]

  @type change_direction :: :positive | :negative | :neutral | :no_data

  @type t_comparison_result :: %__MODULE__.ComparisonResult{
          metric_name: String.t(),
          current_value: Decimal.t(),
          previous_value: Decimal.t(),
          absolute_change: Decimal.t() | nil,
          percentage_change: Decimal.t() | nil,
          change_direction: change_direction()
        }

  defmodule ComparisonResult do
    @moduledoc """
    Represents the calculated difference between two metric values.
    """
    defstruct [:metric_name, :current_value, :previous_value, :absolute_change, :percentage_change, :change_direction]

    @type t :: %__MODULE__{
            metric_name: String.t(),
            current_value: Decimal.t(),
            previous_value: Decimal.t(),
            absolute_change: Decimal.t() | nil,
            percentage_change: Decimal.t() | nil,
            change_direction: :positive | :negative | :neutral | :no_data
          }
  end

  @doc """
  Creates a new TimePeriod struct.
  """
  def new_time_period(start_date, end_date, opts \\ []) do
    %__MODULE__{
      start_date: start_date,
      end_date: end_date,
      label: Keyword.get(opts, :label),
      period_type: Keyword.get(opts, :period_type, :custom)
    }
  end

  @doc """
  Validates a custom date range.
  Returns :ok if valid, or {:error, reason} if invalid.

  Validation rules:
  - start_date must be <= end_date
  - Date range cannot exceed 2 years
  - Period cannot include future dates beyond today
  """
  def validate_date_range(%__MODULE__{} = period) do
    cond do
      Date.compare(period.start_date, period.end_date) == :gt ->
        Logger.warning("Period comparison: start_date is after end_date",
          start_date: period.start_date,
          end_date: period.end_date
        )
        {:errorstart_after_end}

      Date.diff(period.end_date, period.start_date) > 730 ->
        Logger.warning("Period comparison: date range exceeds 2 years",
          start_date: period.start_date,
          end_date: period.end_date,
          days: Date.diff(period.end_date, period.start_date)
        )
        {:error, :exceeds_max_duration}

      Date.compare(period.end_date, Date.utc_today()) == :gt ->
        Logger.warning("Period comparison: end date is in the future",
          end_date: period.end_date,
          today: Date.utc_today()
        )
        {:error, :future_date}

      true ->
        :ok
    end
  end

  @doc """
  Calculates the comparison result between two values.
  """
  def calculate_comparison(current_value, previous_value, metric_name) do
    current = Decimal.new(current_value)
    previous = Decimal.new(previous_value)

    {absolute_change, percentage_change, direction} = calculate_changes(current, previous)

    %ComparisonResult{
      metric_name: metric_name,
      current_value: current,
      previous_value: previous,
      absolute_change: absolute_change,
      percentage_change: percentage_change,
      change_direction: direction
    }
  end

  defp calculate_changes(current, previous) do
    cond do
      # Both values are zero
      Decimal.equal?(current, Decimal.new(0)) and Decimal.equal?(previous, Decimal.new(0)) ->
        {Decimal.new(0), Decimal.new(0), :neutral}

      # Previous is zero, current is positive - direction is positive but percentage is undefined
      Decimal.equal?(previous, Decimal.new(0)) and Decimal.compare(current, Decimal.new(0)) == :gt ->
        {current, nil, :positive}

      # Previous is zero, current is zero
      Decimal.equal?(previous, Decimal.new(0)) ->
        {Decimal.new(0), Decimal.new(0), :neutral}

      # Standard comparison
      true ->
        absolute = Decimal.sub(current, previous)

        # Calculate percentage with proper decimal handling
        percentage =
          case Decimal.div(absolute, previous) do
            %Decimal{coef: nil} -> nil
            percent -> Decimal.mult(percent, Decimal.new(100))
          end

        direction =
          case Decimal.compare(current, previous) do
            :gt -> :positive
            :lt -> :negative
            :eq -> :neutral
          end

        {absolute, percentage, direction}
    end
  end

  @doc """
  Returns a map representation of the comparison result for JSON encoding.
  """
  def to_map(%ComparisonResult{} = result) do
    %{
      name: result.metric_name,
      current_value: Decimal.to_float(result.current_value),
      comparison_value: Decimal.to_float(result.previous_value),
      absolute_change: result.absolute_change && Decimal.to_float(result.absolute_change),
      percentage_change: result.percentage_change && Decimal.to_float(result.percentage_change),
      change_direction: result.change_direction
    }
  end

  @doc """
  Returns a map representation of the time period for JSON encoding.
  """
  def to_map(%__MODULE__{} = period) do
    %{
      start: Date.to_iso8601(period.start_date),
      end: Date.to_iso8601(period.end_date),
      label: period.label
    }
  end
end
