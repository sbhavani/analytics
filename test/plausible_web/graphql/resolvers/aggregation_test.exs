defmodule PlausibleWeb.GraphQL.Resolvers.AggregationTest do
  @moduledoc """
  Unit tests for the Aggregation helper module.
  """

  use PlausibleWeb.ConnCase, async: true
  alias PlausibleWeb.GraphQL.Resolvers.Aggregation

  describe "parse_aggregation_type/1" do
    test "parses SUM aggregation type" do
      assert Aggregation.parse_aggregation_type(:sum) == :sum
      assert Aggregation.parse_aggregation_type("SUM") == :sum
    end

    test "parses AVG aggregation type" do
      assert Aggregation.parse_aggregation_type(:avg) == :avg
      assert Aggregation.parse_aggregation_type("AVG") == :avg
    end

    test "parses MIN aggregation type" do
      assert Aggregation.parse_aggregation_type(:min) == :min
      assert Aggregation.parse_aggregation_type("MIN") == :min
    end

    test "parses MAX aggregation type" do
      assert Aggregation.parse_aggregation_type(:max) == :max
      assert Aggregation.parse_aggregation_type("MAX") == :max
    end

    test "parses COUNT as default aggregation type" do
      assert Aggregation.parse_aggregation_type(nil) == :count
      assert Aggregation.parse_aggregation_type(:count) == :count
      assert Aggregation.parse_aggregation_type("COUNT") == :count
      assert Aggregation.parse_aggregation_type(:unknown) == :count
    end
  end

  describe "parse_group_by/1" do
    test "parses path group by dimension" do
      assert Aggregation.parse_group_by(:path) == :pathname
      assert Aggregation.parse_group_by("PATH") == :pathname
    end

    test "parses url group by dimension" do
      assert Aggregation.parse_group_by(:url) == :url
      assert Aggregation.parse_group_by("URL") == :url
    end

    test "parses browser group by dimension" do
      assert Aggregation.parse_group_by(:browser) == :browser
      assert Aggregation.parse_group_by("BROWSER") == :browser
    end

    test "parses device group by dimension" do
      assert Aggregation.parse_group_by(:device) == :device
      assert Aggregation.parse_group_by("DEVICE") == :device
    end

    test "parses country group by dimension" do
      assert Aggregation.parse_group_by(:country) == :country
      assert Aggregation.parse_group_by("COUNTRY") == :country
    end

    test "parses referrer group by dimension" do
      assert Aggregation.parse_group_by(:referrer) == :referrer
      assert Aggregation.parse_group_by("REFERRER") == :referrer
    end

    test "returns nil for unknown group by dimension" do
      assert Aggregation.parse_group_by(nil) == nil
      assert Aggregation.parse_group_by(:unknown) == nil
    end
  end

  describe "parse_time_interval/1" do
    test "parses minute time interval" do
      assert Aggregation.parse_time_interval(:minute) == :minute
      assert Aggregation.parse_time_interval("MINUTE") == :minute
    end

    test "parses hour time interval" do
      assert Aggregation.parse_time_interval(:hour) == :hour
      assert Aggregation.parse_time_interval("HOUR") == :hour
    end

    test "parses day time interval" do
      assert Aggregation.parse_time_interval(:day) == :date
      assert Aggregation.parse_time_interval("DAY") == :date
    end

    test "parses week time interval" do
      assert Aggregation.parse_time_interval(:week) == :week
      assert Aggregation.parse_time_interval("WEEK") == :week
    end

    test "parses month time interval" do
      assert Aggregation.parse_time_interval(:month) == :month
      assert Aggregation.parse_time_interval("MONTH") == :month
    end

    test "returns nil for unknown time interval" do
      assert Aggregation.parse_time_interval(nil) == nil
      assert Aggregation.parse_time_interval(:unknown) == nil
    end
  end

  describe "apply_aggregation/2" do
    test "applies SUM aggregation to list of results" do
      results = [
        %{count: 10},
        %{count: 20},
        %{count: 30}
      ]

      assert Aggregation.apply_aggregation(results, :sum) == 60
    end

    test "applies AVG aggregation to list of results" do
      results = [
        %{count: 10},
        %{count: 20},
        %{count: 30}
      ]

      assert Aggregation.apply_aggregation(results, :avg) == 20
    end

    test "applies MIN aggregation to list of results" do
      results = [
        %{count: 10},
        %{count: 5},
        %{count: 30}
      ]

      assert Aggregation.apply_aggregation(results, :min) == 5
    end

    test "applies MAX aggregation to list of results" do
      results = [
        %{count: 10},
        %{count: 5},
        %{count: 30}
      ]

      assert Aggregation.apply_aggregation(results, :max) == 30
    end

    test "applies COUNT aggregation to list of results" do
      results = [
        %{count: 10},
        %{count: 20},
        %{count: 30}
      ]

      assert Aggregation.apply_aggregation(results, :count) == 3
    end

    test "handles empty results" do
      assert Aggregation.apply_aggregation([], :sum) == 0
      assert Aggregation.apply_aggregation([], :avg) == 0
      assert Aggregation.apply_aggregation([], :count) == 0
    end

    test "handles nil values in results" do
      results = [
        %{count: nil},
        %{count: 20},
        %{count: nil}
      ]

      assert Aggregation.apply_aggregation(results, :sum) == 20
      assert Aggregation.apply_aggregation(results, :count) == 1
    end
  end

  describe "build_aggregation/1" do
    test "builds aggregation map with default values" do
      assert Aggregation.build_aggregation(nil) == %{
        type: :count,
        group_by: nil,
        interval: nil
      }
    end

    test "builds aggregation map with provided values" do
      input = %{
        type: :sum,
        group_by: :country,
        interval: :day
      }

      assert Aggregation.build_aggregation(input) == %{
        type: :sum,
        group_by: :country,
        interval: :date
      }
    end

    test "parses string values to atoms" do
      input = %{
        type: "SUM",
        group_by: "COUNTRY",
        interval: "DAY"
      }

      assert Aggregation.build_aggregation(input) == %{
        type: :sum,
        group_by: :country,
        interval: :date
      }
    end

    test "handles partial aggregation input" do
      input = %{type: :avg}

      assert Aggregation.build_aggregation(input) == %{
        type: :avg,
        group_by: nil,
        interval: nil
      }
    end
  end

  describe "format_period/2" do
    test "formats period for minute interval" do
      row = %{date: ~N[2026-01-15 10:30:00]}
      assert Aggregation.format_period(row, :minute) == ~N[2026-01-15 10:30:00]
    end

    test "formats period for hour interval" do
      row = %{date: ~N[2026-01-15 10:00:00]}
      assert Aggregation.format_period(row, :hour) == ~N[2026-01-15 10:00:00]
    end

    test "formats period for day interval" do
      row = %{date: ~D[2026-01-15]}
      assert Aggregation.format_period(row, :date) == ~D[2026-01-15]
    end

    test "formats period for week interval" do
      row = %{date: ~D[2026-01-13]}
      assert Aggregation.format_period(row, :week) == ~D[2026-01-13]
    end

    test "formats period for month interval" do
      row = %{date: ~D[2026-01-01]}
      assert Aggregation.format_period(row, :month) == ~D[2026-01-01]
    end

    test "returns nil for unknown interval" do
      row = %{date: ~D[2026-01-15]}
      assert Aggregation.format_period(row, :unknown) == nil
    end
  end
end
