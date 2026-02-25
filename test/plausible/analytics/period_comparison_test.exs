defmodule Plausible.Analytics.PeriodComparisonTest do
  use ExUnit.Case, async: true

  alias Plausible.Analytics.PeriodComparison
  alias Plausible.Analytics.PeriodComparison.ComparisonResult

  describe "calculate_comparison/3" do
    test "calculates positive change correctly" do
      result = PeriodComparison.calculate_comparison(1250, 1000, "visitors")

      assert result.metric_name == "visitors"
      assert result.current_value == Decimal.new(1250)
      assert result.previous_value == Decimal.new(1000)
      assert result.absolute_change == Decimal.new(250)
      assert result.percentage_change == Decimal.new(25)
      assert result.change_direction == :positive
    end

    test "calculates negative change correctly" do
      result = PeriodComparison.calculate_comparison(800, 1000, "visitors")

      assert result.current_value == Decimal.new(800)
      assert result.previous_value == Decimal.new(1000)
      assert result.absolute_change == Decimal.new(-200)
      assert result.percentage_change == Decimal.new(-20)
      assert result.change_direction == :negative
    end

    test "calculates no change (neutral) correctly" do
      result = PeriodComparison.calculate_comparison(1000, 1000, "visitors")

      assert result.current_value == Decimal.new(1000)
      assert result.previous_value == Decimal.new(1000)
      assert result.absolute_change == Decimal.new(0)
      assert result.percentage_change == Decimal.new(0)
      assert result.change_direction == :neutral
    end

    test "handles previous value of zero with positive current value" do
      result = PeriodComparison.calculate_comparison(100, 0, "visitors")

      assert result.current_value == Decimal.new(100)
      assert result.previous_value == Decimal.new(0)
      assert result.percentage_change == nil
      assert result.change_direction == :positive
    end

    test "handles both values being zero" do
      result = PeriodComparison.calculate_comparison(0, 0, "visitors")

      assert result.current_value == Decimal.new(0)
      assert result.previous_value == Decimal.new(0)
      assert result.absolute_change == Decimal.new(0)
      assert result.percentage_change == Decimal.new(0)
      assert result.change_direction == :neutral
    end

    test "handles decimal values correctly" do
      result = PeriodComparison.calculate_comparison(1500.5, 1200.3, "revenue")

      assert result.current_value == Decimal.new("1500.5")
      assert result.previous_value == Decimal.new("1200.3")
      assert result.absolute_change == Decimal.new("300.2")
      assert result.change_direction == :positive
    end

    test "calculates large percentage changes correctly" do
      # 10 to 100 is 900% increase
      result = PeriodComparison.calculate_comparison(100, 10, "visitors")

      assert result.percentage_change == Decimal.new(900)
      assert result.change_direction == :positive
    end
  end

  describe "validate_date_range/1" do
    test "returns ok for valid date range" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        ~D[2026-01-31],
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == :ok
    end

    test "returns error when start_date is after end_date" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-31],
        ~D[2026-01-01],
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == {:error, :start_after_end}
    end

    test "returns error when date range exceeds 2 years" do
      period = PeriodComparison.new_time_period(
        ~D[2024-01-01],
        ~D[2026-02-01],
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == {:error, :exceeds_max_duration}
    end

    test "returns error when end date is in the future" do
      future_date = Date.add(Date.utc_today(), 1)
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        future_date,
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == {:error, :future_date}
    end

    test "allows end date equal to today" do
      today = Date.utc_today()
      period = PeriodComparison.new_time_period(
        Date.add(today, -30),
        today,
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == :ok
    end

    test "allows exactly 2 year range" do
      today = Date.utc_today()
      two_years_ago = Date.add(today, -730)

      period = PeriodComparison.new_time_period(
        two_years_ago,
        today,
        period_type: :custom
      )

      assert PeriodComparison.validate_date_range(period) == :ok
    end
  end

  describe "new_time_period/3" do
    test "creates a time period with required fields" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        ~D[2026-01-31]
      )

      assert period.start_date == ~D[2026-01-01]
      assert period.end_date == ~D[2026-01-31]
      assert period.period_type == :custom
      assert period.label == nil
    end

    test "creates a time period with optional label" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        ~D[2026-01-31],
        label: "This Month"
      )

      assert period.label == "This Month"
    end

    test "creates a time period with predefined type" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        ~D[2026-01-31],
        period_type: :predefined
      )

      assert period.period_type == :predefined
    end
  end

  describe "to_map/1" do
    test "converts ComparisonResult to map" do
      result = PeriodComparison.calculate_comparison(1250, 1000, "visitors")
      map = PeriodComparison.to_map(result)

      assert map.name == "visitors"
      assert map.current_value == 1250.0
      assert map.comparison_value == 1000.0
      assert map.absolute_change == 250.0
      assert map.percentage_change == 25.0
      assert map.change_direction == :positive
    end

    test "converts TimePeriod to map" do
      period = PeriodComparison.new_time_period(
        ~D[2026-01-01],
        ~D[2026-01-31],
        label: "This Month"
      )

      map = PeriodComparison.to_map(period)

      assert map.start == "2026-01-01"
      assert map.end == "2026-01-31"
      assert map.label == "This Month"
    end

    test "handles nil percentage_change in to_map" do
      result = PeriodComparison.calculate_comparison(100, 0, "visitors")
      map = PeriodComparison.to_map(result)

      assert map.percentage_change == nil
    end
  end
end
