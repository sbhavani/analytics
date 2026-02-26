defmodule Plausible.Stats.PeriodComparisonTest do
  use Plausible.DataCase, async: true

  alias Plausible.Stats.PeriodComparison

  describe "predefined_period_range/2" do
    test "returns correct date range for this_week" do
      # Testing with a known date (Thursday, Feb 26, 2026)
      # This week means: from Monday to Friday (work week)
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:this_week, reference_date) == %{
               first: ~D[2026-02-23],
               last: ~D[2026-02-27]
             }
    end

    test "returns correct date range for last_week" do
      # Last week is the week before this week
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:last_week, reference_date) == %{
               first: ~D[2026-02-16],
               last: ~D[2026-02-22]
             }
    end

    test "returns correct date range for this_month" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:this_month, reference_date) == %{
               first: ~D[2026-02-01],
               last: ~D[2026-02-28]
             }
    end

    test "returns correct date range for last_month" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:last_month, reference_date) == %{
               first: ~D[2026-01-01],
               last: ~D[2026-01-31]
             }
    end

    test "returns correct date range for this_quarter" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:this_quarter, reference_date) == %{
               first: ~D[2026-01-01],
               last: ~D[2026-03-31]
             }
    end

    test "returns correct date range for last_quarter" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:last_quarter, reference_date) == %{
               first: ~D[2025-10-01],
               last: ~D[2025-12-31]
             }
    end

    test "returns correct date range for this_year" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:this_year, reference_date) == %{
               first: ~D[2026-01-01],
               last: ~D[2026-12-31]
             }
    end

    test "returns correct date range for last_year" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:last_year, reference_date) == %{
               first: ~D[2025-01-01],
               last: ~D[2025-12-31]
             }
    end

    test "handles leap year February correctly for this_month" do
      # Leap year 2024
      reference_date = ~D[2024-02-29]

      assert PeriodComparison.predefined_period_range(:this_month, reference_date) == %{
               first: ~D[2024-02-01],
               last: ~D[2024-02-29]
             }
    end

    test "handles leap year February correctly for last_month" do
      # Leap year 2024 - January before leap day
      reference_date = ~D[2024-02-29]

      assert PeriodComparison.predefined_period_range(:last_month, reference_date) == %{
               first: ~D[2024-01-01],
               last: ~D[2024-01-31]
             }
    end

    test "handles leap year for this_year" do
      # Leap year 2024
      reference_date = ~D[2024-02-26]

      assert PeriodComparison.predefined_period_range(:this_year, reference_date) == %{
               first: ~D[2024-01-01],
               last: ~D[2024-12-31]
             }
    end

    test "handles year boundary for this_year in December" do
      reference_date = ~D[2026-12-15]

      assert PeriodComparison.predefined_period_range(:this_year, reference_date) == %{
               first: ~D[2026-01-01],
               last: ~D[2026-12-31]
             }
    end

    test "handles year boundary for last_year in January" do
      # January is always in the current year, so last_year is the previous year
      reference_date = ~D[2026-01-15]

      assert PeriodComparison.predefined_period_range(:last_year, reference_date) == %{
               first: ~D[2025-01-01],
               last: ~D[2025-12-31]
             }
    end

    test "handles quarter boundaries correctly" do
      # Q1 boundary
      assert PeriodComparison.predefined_period_range(:this_quarter, ~D[2026-03-31]) == %{
               first: ~D[2026-01-01],
               last: ~D[2026-03-31]
             }

      # Q2 boundary
      assert PeriodComparison.predefined_period_range(:this_quarter, ~D[2026-04-01]) == %{
               first: ~D[2026-04-01],
               last: ~D[2026-06-30]
             }

      # Q3 boundary
      assert PeriodComparison.predefined_period_range(:this_quarter, ~D[2026-07-01]) == %{
               first: ~D[2026-07-01],
               last: ~D[2026-09-30]
             }

      # Q4 boundary
      assert PeriodComparison.predefined_period_range(:this_quarter, ~D[2026-10-01]) == %{
               first: ~D[2026-10-01],
               last: ~D[2026-12-31]
             }
    end

    test "returns error for invalid period" do
      reference_date = ~D[2026-02-26]

      assert PeriodComparison.predefined_period_range(:invalid_period, reference_date) == {
               :error,
               :invalid_period
             }
    end
  end

  describe "predefined_periods/0" do
    test "returns list of available predefined periods" do
      periods = PeriodComparison.predefined_periods()

      assert :this_week in periods
      assert :last_week in periods
      assert :this_month in periods
      assert :last_month in periods
      assert :this_quarter in periods
      assert :last_quarter in periods
      assert :this_year in periods
      assert :last_year in periods
    end
  end

  describe "period_label/1" do
    test "returns human-readable label for each period" do
      assert PeriodComparison.period_label(:this_week) == "This Week"
      assert PeriodComparison.period_label(:last_week) == "Last Week"
      assert PeriodComparison.period_label(:this_month) == "This Month"
      assert PeriodComparison.period_label(:last_month) == "Last Month"
      assert PeriodComparison.period_label(:this_quarter) == "This Quarter"
      assert PeriodComparison.period_label(:last_quarter) == "Last Quarter"
      assert PeriodComparison.period_label(:this_year) == "This Year"
      assert PeriodComparison.period_label(:last_year) == "Last Year"
    end
  end
end
