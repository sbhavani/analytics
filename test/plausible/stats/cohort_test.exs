defmodule Plausible.Stats.CohortTest do
  use Plausible.DataCase, async: true
  alias Plausible.Stats.Cohort

  describe "period parameter handling" do
    test "validates daily period" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "daily"})

      assert result.meta.period == "daily"
      assert is_list(result.cohorts)
    end

    test "validates weekly period" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "weekly"})

      assert result.meta.period == "weekly"
      assert is_list(result.cohorts)
    end

    test "validates monthly period" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      assert result.meta.period == "monthly"
      assert is_list(result.cohorts)
    end

    test "uses monthly as default period when not specified" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{})

      assert result.meta.period == "monthly"
    end

    test "returns error for invalid period" do
      site = build(:site)

      {:error, reason} = Cohort.cohorts(site, %{"period" => "yearly"})

      assert reason == "Invalid period. Must be daily, weekly, or monthly."
    end

    test "returns error for empty period" do
      site = build(:site)

      {:error, reason} = Cohort.cohorts(site, %{"period" => ""})

      assert reason == "Invalid period. Must be daily, weekly, or monthly."
    end

    test "includes date range in metadata" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      assert result.meta.date_range.from
      assert result.meta.date_range.to
    end

    test "accepts custom from date" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{
        "period" => "monthly",
        "from" => "2025-01-01"
      })

      assert result.meta.date_range.from == "2025-01-01"
    end

    test "accepts custom to date" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{
        "period" => "monthly",
        "to" => "2025-12-31"
      })

      assert result.meta.date_range.to == "2025-12-31"
    end

    test "accepts custom date range" do
      site = build(:site)

      {:ok, result} =
        Cohort.cohorts(site, %{
          "period" => "monthly",
          "from" => "2025-01-01",
          "to" => "2025-12-31"
        })

      assert result.meta.date_range.from == "2025-01-01"
      assert result.meta.date_range.to == "2025-12-31"
    end
  end

  describe "cohort data structure" do
    test "each cohort has required fields" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      assert length(result.cohorts) > 0

      Enum.each(result.cohorts, fn cohort ->
        assert cohort["id"]
        assert cohort["date"]
        assert cohort["size"]
        assert is_list(cohort["retention"])
      end)
    end

    test "retention data includes period_number and retention_rate" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      [cohort | _] = result.cohorts

      Enum.each(cohort["retention"], fn retention ->
        assert retention["period_number"]
        assert retention["retained_count"]
        assert retention["retention_rate"]
        assert is_number(retention["retention_rate"])
      end)
    end

    test "retention rate is between 0 and 1" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      Enum.each(result.cohorts, fn cohort ->
        Enum.each(cohort["retention"], fn retention ->
          assert retention["retention_rate"] >= 0
          assert retention["retention_rate"] <= 1
        end)
      end)
    end
  end

  describe "cohort id format" do
    test "monthly cohorts have YYYY-MM format" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "monthly"})

      [cohort | _] = result.cohorts

      assert Regex.match?(~r/^\d{4}-\d{2}$/, cohort["id"])
    end

    test "weekly cohorts have YYYY-WW format" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "weekly"})

      [cohort | _] = result.cohorts

      assert Regex.match?(~r/^\d{4}-W\d{2}$/, cohort["id"])
    end

    test "daily cohorts have YYYY-MM-DD format" do
      site = build(:site)

      {:ok, result} = Cohort.cohorts(site, %{"period" => "daily"})

      [cohort | _] = result.cohorts

      assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, cohort["id"])
    end
  end
end
