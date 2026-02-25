defmodule Plausible.Stats.CohortTest do
  use Plausible.DataCase, async: true
  alias Plausible.Stats.Cohort

  describe "validate_params/1" do
    test "validates valid cohort_periods" do
      assert {:ok, periods: 12} = Cohort.validate_params(%{"cohort_periods" => "12"})
      assert {:ok, periods: 6} = Cohort.validate_params(%{"cohort_periods" => "6"})
      assert {:ok, periods: 1} = Cohort.validate_params(%{"cohort_periods" => "1"})
    end

    test "validates default cohort_periods" do
      assert {:ok, periods: 12} = Cohort.validate_params(%{})
    end

    test "rejects cohort_periods less than 1" do
      assert {:error, "cohort_periods must be at least 1"} = Cohort.validate_params(%{"cohort_periods" => "0"})
      assert {:error, "cohort_periods must be at least 1"} = Cohort.validate_params(%{"cohort_periods" => "-1"})
    end

    test "rejects cohort_periods greater than 24" do
      assert {:error, "cohort_periods cannot exceed 24"} = Cohort.validate_params(%{"cohort_periods" => "25"})
      assert {:error, "cohort_periods cannot exceed 24"} = Cohort.validate_params(%{"cohort_periods" => "100"})
    end
  end

  describe "fetch_cohort_data/3" do
    test "returns cohort data structure" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      assert is_map(result)
      assert is_list(result.cohorts)
      assert is_list(result.period_labels)
      assert is_map(result.meta)
      assert result.meta.cohort_periods == 6
    end

    test "first period in retention array is always 1.0" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      for cohort <- result.cohorts do
        assert List.first(cohort.retention) == 1.0
      end
    end

    test "retention values are within valid range (0.0 to 1.0)" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      for cohort <- result.cohorts do
        for retention_rate <- cohort.retention do
          assert retention_rate >= 0.0
          assert retention_rate <= 1.0
        end
      end
    end

    test "returns correct number of period labels" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      assert length(result.period_labels) == 6
    end

    test "period labels follow Month N format" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      assert result.period_labels == ["Month 0", "Month 1", "Month 2", "Month 3", "Month 4", "Month 5"]
    end

    test "includes date range in meta" do
      site = insert(:site)
      from_date = Date.add(Date.utc_today(), -180)
      to_date = Date.utc_today()
      date_range = Date.range(from_date, to_date)

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      assert result.meta.date_range.from == Date.to_iso8601(from_date)
      assert result.meta.date_range.to == Date.to_iso8601(to_date)
    end

    test "cohorts have required fields" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      for cohort <- result.cohorts do
        assert Map.has_key?(cohort, :cohort_date)
        assert Map.has_key?(cohort, :total_users)
        assert Map.has_key?(cohort, :retention)
        assert is_struct(cohort.cohort_date, Date)
        assert is_integer(cohort.total_users)
        assert is_list(cohort.retention)
      end
    end

    test "total_users is non-negative" do
      site = insert(:site)
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6)

      for cohort <- result.cohorts do
        assert cohort.total_users >= 0
      end
    end

    test "respects custom site_id option" do
      site = insert(:site)
      custom_site_id = 12345
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 6, site_id: custom_site_id)

      assert is_map(result)
    end

    test "returns correct number of cohorts for date range" do
      site = insert(:site)
      # Use a 1-year range which should return 12 monthly cohorts
      date_range = Date.range(Date.add(Date.utc_today(), -365), Date.utc_today())

      result = Cohort.fetch_cohort_data(site, date_range, periods: 12)

      assert length(result.cohorts) == 12
    end
  end
end
