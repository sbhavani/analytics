defmodule Plausible.Stats.ComparisonsTest do
  use Plausible.DataCase
  alias Plausible.Stats.{Query, Comparisons, QueryBuilder, ParsedQueryParams, QueryInclude}

  setup [:create_user, :create_site]

  describe "with period set to this month" do
    test "shifts back this month period when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-03-02],
          include: [compare: :previous_period],
          now: ~U[2023-03-02 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-02-27 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-02-28 23:59:59Z]
    end

    test "shifts back this month period when it's the first day of the month and mode is previous_period",
         %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-03-01],
          include: [compare: :previous_period],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-02-28 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-02-28 23:59:59Z]
    end

    test "matches the day of the week when nearest day is original query start date and mode is previous_period",
         %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-03-02],
          include: [compare: :previous_period, compare_match_day_of_week: true],
          now: ~U[2023-03-02 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-02-22 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-02-23 23:59:59Z]
    end

    test "custom time zone sets timezone to UTC" do
      site = insert(:site, timezone: "US/Eastern")

      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-03-02],
          include: [compare: :previous_period],
          now: ~U[2023-03-02 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-02-27 05:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-03-01 04:59:59Z]
    end
  end

  describe "with period set to previous month" do
    test "shifts back using the same number of days when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-02-01],
          include: [compare: :previous_period],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-01-04 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-01-31 23:59:59Z]
    end

    test "shifts back the full month when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-02-01],
          include: [compare: :year_over_year],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-02-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-02-28 23:59:59Z]
    end

    test "shifts back whole month plus one day when mode is year_over_year and a leap year", %{
      site: site
    } do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2020-02-01],
          include: [compare: :year_over_year],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2019-02-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2019-03-01 23:59:59Z]
    end

    test "matches the day of the week when mode is previous_period keeping the same day", %{
      site: site
    } do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-02-01],
          include: [compare: :previous_period, compare_match_day_of_week: true],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-01-04 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-01-31 23:59:59Z]
    end

    test "matches the day of the week when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-01-01],
          include: [compare: :previous_period, compare_match_day_of_week: true],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-12-04 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-01-03 23:59:59Z]
    end
  end

  describe "year_over_year, exact dates behavior with leap years" do
    test "start of the year matching", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:last_n_days, 7},
          relative_date: ~D[2021-01-05],
          include: [compare: :year_over_year]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2019-12-29 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2020-01-04 23:59:59Z]
      assert date_range_length(comparison_query) == 7
    end

    test "leap day matching", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:last_n_days, 7},
          relative_date: ~D[2021-03-04],
          include: [compare: :year_over_year]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2020-02-25 00:00:00Z]
      # :TRICKY: Since dates of the two months don't match precisely we cut off earlier
      assert comparison_query.utc_time_range.last == ~U[2020-03-02 23:59:59Z]
      assert date_range_length(comparison_query) == 7
    end

    test "end of the year matching", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:last_n_days, 7},
          relative_date: ~D[2021-11-25],
          include: [compare: :year_over_year]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2020-11-18 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2020-11-24 23:59:59Z]
      assert date_range_length(comparison_query) == 7
    end
  end

  describe "with period set to year to date" do
    test "shifts back by the same number of days when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :year,
          relative_date: ~D[2023-03-01],
          include: [compare: :previous_period],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-11-02 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-31 23:59:59Z]
    end

    test "shifts back by the same number of days when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :year,
          relative_date: ~D[2023-03-01],
          include: [compare: :year_over_year],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-01-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-03-01 23:59:59Z]
    end

    test "matches the day of the week when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :year,
          relative_date: ~D[2023-03-01],
          include: [compare: :year_over_year, compare_match_day_of_week: true],
          now: ~U[2023-03-01 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-01-02 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-03-02 23:59:59Z]
    end
  end

  describe "with period set to previous year" do
    test "shifts back a whole year when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :year,
          relative_date: ~D[2022-03-02],
          include: [compare: :year_over_year]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2021-01-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2021-12-31 23:59:59Z]
    end

    test "shifts back a whole year when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :year,
          relative_date: ~D[2022-03-02],
          include: [compare: :previous_period]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2021-01-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2021-12-31 23:59:59Z]
    end
  end

  describe "with period set to custom" do
    test "shifts back by the same number of days when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-07]},
          include: [compare: :previous_period]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-12-25 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-31 23:59:59Z]
    end

    test "shifts back to last year when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-07]},
          include: [compare: :year_over_year]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-01-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-01-07 23:59:59Z]
    end
  end

  describe "with mode set to custom" do
    test "sets first and last dates", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-07]},
          include: [compare: {:date_range, ~D[2022-05-25], ~D[2022-05-30]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-05-25 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-05-30 23:59:59Z]
    end

    test "custom date range comparison returns correct data for 7-day period", %{site: site} do
      # Main period: Jan 1-7, 2023 (7 days)
      # Comparison period: Dec 25-31, 2022 (7 days)
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors, :pageviews],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-07]},
          include: [compare: {:date_range, ~D[2022-12-25], ~D[2022-12-31]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Verify main query has correct date range
      assert query.utc_time_range.first == ~U[2023-01-01 00:00:00Z]
      assert query.utc_time_range.last == ~U[2023-01-07 23:59:59Z]

      # Verify comparison query has the custom date range
      assert comparison_query.utc_time_range.first == ~U[2022-12-25 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-31 23:59:59Z]

      # Verify both periods have the same length (7 days)
      assert date_range_length(query) == 7
      assert date_range_length(comparison_query) == 7
    end

    test "custom date range comparison with different length periods", %{site: site} do
      # Main period: Jan 1-15, 2023 (15 days)
      # Comparison period: Dec 1-31, 2022 (31 days) - different length
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-15]},
          include: [compare: {:date_range, ~D[2022-12-01], ~D[2022-12-31]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Verify comparison query uses the exact custom dates provided
      assert comparison_query.utc_time_range.first == ~U[2022-12-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-31 23:59:59Z]

      # Main period is 15 days, comparison is 31 days
      assert date_range_length(query) == 15
      assert date_range_length(comparison_query) == 31
    end

    test "custom date range comparison with single day period", %{site: site} do
      # Main period: single day
      # Comparison period: different single day
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-06-15], ~D[2023-06-15]},
          include: [compare: {:date_range, ~D[2023-06-01], ~D[2023-06-01]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2023-06-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-06-01 23:59:59Z]
    end

    test "custom date range comparison works with custom main period", %{site: site} do
      # Custom main period: Feb 14-20, 2023 (Valentine's week)
      # Custom comparison: Feb 7-13, 2023 (week before)
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors, :pageviews, :bounce_rate],
          input_date_range: {:date_range, ~D[2023-02-14], ~D[2023-02-20]},
          include: [compare: {:date_range, ~D[2023-02-07], ~D[2023-02-13]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Main period dates
      assert query.utc_time_range.first == ~U[2023-02-14 00:00:00Z]
      assert query.utc_time_range.last == ~U[2023-02-20 23:59:59Z]

      # Comparison period dates (the custom dates)
      assert comparison_query.utc_time_range.first == ~U[2023-02-07 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-02-13 23:59:59Z]

      # Both should be 7 days
      assert date_range_length(query) == 7
      assert date_range_length(comparison_query) == 7
    end

    test "custom date range comparison ignores match_day_of_week option", %{site: site} do
      # Custom date ranges should not be affected by match_day_of_week
      # because the user explicitly specified the dates
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2023-01-01], ~D[2023-01-07]},
          include: [
            compare: {:date_range, ~D[2022-12-25], ~D[2022-12-31]},
            compare_match_day_of_week: true
          ]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Should use exact custom dates, not adjusted for day of week
      assert comparison_query.utc_time_range.first == ~U[2022-12-25 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-31 23:59:59Z]
    end

    test "custom date range comparison with month-spanning dates", %{site: site} do
      # Main period: Dec 15, 2022 - Jan 15, 2023 (spans month boundary)
      # Comparison period: Nov 15 - Dec 15, 2022 (similar length)
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:date_range, ~D[2022-12-15], ~D[2023-01-15]},
          include: [compare: {:date_range, ~D[2022-11-15], ~D[2022-12-15]}]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      assert comparison_query.utc_time_range.first == ~U[2022-11-15 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-12-15 23:59:59Z]
    end
  end

  describe "with predefined comparison modes" do
    test "this_week_vs_last_week generates correct comparison range", %{site: site} do
      # Use a known date: Wednesday, Feb 21, 2024
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :week,
          relative_date: ~D[2024-02-21],
          include: [compare: :this_week_vs_last_week],
          now: ~U[2024-02-21 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # This week: Monday Feb 19 to Sunday Feb 25 (2024)
      # Last week: Monday Feb 12 to Sunday Feb 18
      assert comparison_query.utc_time_range.first == ~U[2024-02-12 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2024-02-18 23:59:59Z]
    end

    test "this_month_vs_last_month generates correct comparison range", %{site: site} do
      # Use a known date in March 2024
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2024-03-15],
          include: [compare: :this_month_vs_last_month],
          now: ~U[2024-03-15 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # This month: March 2024 (Mar 1 to Mar 31)
      # Last month: February 2024 (Feb 1 to Feb 29, leap year)
      assert comparison_query.utc_time_range.first == ~U[2024-02-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2024-02-29 23:59:59Z]
    end

    test "this_month_vs_last_month handles non-leap year correctly", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :month,
          relative_date: ~D[2023-03-15],
          include: [compare: :this_month_vs_last_month],
          now: ~U[2023-03-15 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # This month: March 2023
      # Last month: February 2023 (28 days, not leap year)
      assert comparison_query.utc_time_range.first == ~U[2023-02-01 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-02-28 23:59:59Z]
    end

    test "last_7_days_vs_previous_7_days generates correct comparison range", %{site: site} do
      # Use a known date: Wednesday, Feb 21, 2024
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: {:last_n_days, 7},
          relative_date: ~D[2024-02-21],
          include: [compare: :last_7_days_vs_previous_7_days],
          now: ~U[2024-02-21 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Last 7 days: Feb 15-21 (inclusive)
      # Previous 7 days: Feb 8-14 (7 days before last 7 days)
      assert comparison_query.utc_time_range.first == ~U[2024-02-08 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2024-02-14 23:59:59Z]
    end

    test "predefined modes ignore match_day_of_week option", %{site: site} do
      # this_week_vs_last_week should work regardless of match_day_of_week
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :week,
          relative_date: ~D[2024-02-21],
          include: [compare: :this_week_vs_last_week, compare_match_day_of_week: true],
          now: ~U[2024-02-21 14:00:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # Should still return last week's range, not affected by match_day_of_week
      assert comparison_query.utc_time_range.first == ~U[2024-02-12 00:00:00Z]
      assert comparison_query.utc_time_range.last == ~U[2024-02-18 23:59:59Z]
    end
  end

  describe "add_comparison_filters" do
    test "no results doesn't update filters", %{site: site} do
      query = build_comparison_query(site, %ParsedQueryParams{dimensions: ["visit:browser"]})

      result_query = Comparisons.add_comparison_filters(query, [])

      assert result_query.filters == []
    end

    test "no dimensions doesn't update filters", %{site: site} do
      query = build_comparison_query(site, %ParsedQueryParams{})

      result_query =
        Comparisons.add_comparison_filters(query, [%{dimensions: [], metrics: [123]}])

      assert result_query.filters == []
    end

    test "no time dimension doesn't update filters", %{site: site} do
      query = build_comparison_query(site, %ParsedQueryParams{dimensions: ["time:day"]})

      result_query =
        Comparisons.add_comparison_filters(query, [%{dimensions: ["2024-01-01"], metrics: [123]}])

      assert result_query.filters == []
    end

    test "updates filters in a single-row case", %{site: site} do
      query = build_comparison_query(site, %ParsedQueryParams{dimensions: ["visit:browser"]})

      result_query =
        Comparisons.add_comparison_filters(query, [%{dimensions: ["Chrome"], metrics: [123]}])

      assert result_query.filters == [
               [:ignore_in_totals_query, [:is, "visit:browser", ["Chrome"]]]
             ]
    end

    test "updates filters for a complex case", %{site: site} do
      query =
        build_comparison_query(site, %ParsedQueryParams{
          dimensions: ["visit:browser", "visit:browser_version", "time:day"],
          filters: [[:is, "visit:country_name", ["Estonia"]]]
        })

      main_query_results = [
        %{
          dimensions: ["Chrome", "99.9", "2024-01-01"],
          metrics: [123]
        },
        %{
          dimensions: ["Firefox", "12.0", "2024-01-01"],
          metrics: [123]
        }
      ]

      result_query = Comparisons.add_comparison_filters(query, main_query_results)

      assert result_query.filters == [
               [:is, "visit:country_name", ["Estonia"]],
               [
                 :ignore_in_totals_query,
                 [
                   :or,
                   [
                     [
                       :and,
                       [
                         [:is, "visit:browser", ["Chrome"]],
                         [:is, "visit:browser_version", ["99.9"]]
                       ]
                     ],
                     [
                       :and,
                       [
                         [:is, "visit:browser", ["Firefox"]],
                         [:is, "visit:browser_version", ["12.0"]]
                       ]
                     ]
                   ]
                 ]
               ]
             ]
    end
  end

  defp build_comparison_query(site, %ParsedQueryParams{} = params) do
    QueryBuilder.build!(
      site,
      struct!(params,
        metrics: [:pageviews],
        input_date_range: {:date_range, ~D[2024-01-01], ~D[2024-02-01]},
        include: %QueryInclude{compare: :previous_period}
      )
    )
  end

  defp date_range_length(query) do
    query
    |> Query.date_range()
    |> Enum.count()
  end

  describe "with period set to 24h" do
    test "shifts back 24h period when mode is previous_period", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :"24h",
          include: [compare: :previous_period],
          now: ~U[2023-03-15 18:30:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # 24h range from 2023-03-14 18:30:00 to 2023-03-15 18:30:00 (UTC)
      # Previous period shifts back exactly 24 hours
      assert comparison_query.utc_time_range.first == ~U[2023-03-13 18:30:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-03-14 18:30:00Z]
    end

    test "shifts back 24h period when mode is year_over_year", %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :"24h",
          include: [compare: :year_over_year],
          now: ~U[2023-03-15 18:30:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # 24h range: 2023-03-14 18:30:00 to 2023-03-15 18:30:00 (UTC)
      # Year over year shifts back exactly 1 year
      assert comparison_query.utc_time_range.first == ~U[2022-03-14 18:30:00Z]
      assert comparison_query.utc_time_range.last == ~U[2022-03-15 18:30:00Z]
    end

    test "custom time zone works with 24h comparison" do
      site = insert(:site, timezone: "US/Eastern")

      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :"24h",
          include: [compare: :previous_period],
          now: ~U[2023-03-15 18:30:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # 24h range: 2023-03-14 18:30:00 to 2023-03-15 18:30:00 (UTC)
      # Previous period shifts back exactly 24 hours
      assert comparison_query.utc_time_range.first == ~U[2023-03-13 18:30:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-03-14 18:30:00Z]
    end

    test "shifts back 24h period to match day of week when mode is previous_period with match_day_of_week",
         %{site: site} do
      query =
        QueryBuilder.build!(site,
          metrics: [:visitors],
          input_date_range: :"24h",
          include: [compare: :previous_period, compare_match_day_of_week: true],

          # Wednesday
          now: ~U[2023-03-15 18:30:00Z]
        )

      comparison_query = Comparisons.get_comparison_query(query)

      # 24h range: Tuesday 2023-03-14 18:30:00 to Wednesday 2023-03-15 18:30:00 (UTC)
      # Match day of week: shift back 7 days to get the same Tuesday->Wednesday window
      # Result: Tuesday 2023-03-07 18:30:00 to Wednesday 2023-03-08 18:30:00
      assert comparison_query.utc_time_range.first == ~U[2023-03-07 18:30:00Z]
      assert comparison_query.utc_time_range.last == ~U[2023-03-08 18:30:00Z]
    end
  end
end
