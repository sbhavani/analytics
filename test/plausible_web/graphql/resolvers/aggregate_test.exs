defmodule PlausibleWeb.GraphQL.Resolvers.AggregateTest do
  use ExUnit.Case, async: false
  use Plausible.TestUtils

  alias PlausibleWeb.GraphQL.Resolvers.Aggregate

  describe "get_aggregate/3" do
    setup [:create_user, :create_site]

    test "returns aggregate metrics for valid input", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors", "pageviews", "events"]
      }

      {:ok, result} = Aggregate.get_aggregate(nil, args, nil)

      # Should return a map with the expected keys
      assert is_map(result)
      assert Map.has_key?(result, :visitors)
      assert Map.has_key?(result, :pageviews)
      assert Map.has_key?(result, :events)
    end

    test "returns error for invalid date range (from > to)", %{site: site} do
      date_range = %{from: "2024-01-31", to: "2024-01-01"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_aggregate(nil, args, nil)

      assert {:error, _} = result
    end

    test "returns error for invalid from date format", %{site: site} do
      date_range = %{from: "invalid-date", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_aggregate(nil, args, nil)

      assert {:error, _} = result
    end

    test "returns error for invalid to date format", %{site: site} do
      date_range = %{from: "2024-01-01", to: "also-invalid"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_aggregate(nil, args, nil)

      assert {:error, _} = result
    end

    test "returns error for non-existent site", _context do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: "non-existent-12345.example.com",
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_aggregate(nil, args, nil)

      assert {:error, _} = result
    end

    test "returns all supported metrics", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors", "pageviews", "events", "bounce_rate", "visit_duration", "views_per_visit"]
      }

      {:ok, result} = Aggregate.get_aggregate(nil, args, nil)

      assert Map.has_key?(result, :visitors)
      assert Map.has_key?(result, :pageviews)
      assert Map.has_key?(result, :events)
      assert Map.has_key?(result, :bounce_rate)
      assert Map.has_key?(result, :visit_duration)
      assert Map.has_key?(result, :views_per_visit)
    end

    test "handles empty metrics list", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: []
      }

      {:ok, result} = Aggregate.get_aggregate(nil, args, nil)

      # Should still return a map even with empty metrics
      assert is_map(result)
    end

    test "accepts metrics as atoms", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: [:visitors, :pageviews]
      }

      {:ok, result} = Aggregate.get_aggregate(nil, args, nil)

      assert is_map(result)
    end
  end

  describe "get_timeseries/3" do
    setup [:create_user, :create_site]

    test "returns timeseries data for valid input", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-07"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors", "pageviews"],
        interval: :day
      }

      {:ok, result} = Aggregate.get_timeseries(nil, args, nil)

      assert result[:interval] == :day
      assert is_list(result[:data])
    end

    test "returns timeseries with hourly interval", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-01"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"],
        interval: :hour
      }

      {:ok, result} = Aggregate.get_timeseries(nil, args, nil)

      assert result[:interval] == :hour
    end

    test "returns timeseries with weekly interval", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"],
        interval: :week
      }

      {:ok, result} = Aggregate.get_timeseries(nil, args, nil)

      assert result[:interval] == :week
    end

    test "returns timeseries with monthly interval", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-03-31"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"],
        interval: :month
      }

      {:ok, result} = Aggregate.get_timeseries(nil, args, nil)

      assert result[:interval] == :month
    end

    test "defaults to daily interval when not specified", %{site: site} do
      date_range = %{from: "2024-01-01", to: "2024-01-07"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"]
      }

      {:ok, result} = Aggregate.get_timeseries(nil, args, nil)

      assert result[:interval] == :day
    end

    test "returns error for invalid date range", %{site: site} do
      date_range = %{from: "2024-01-31", to: "2024-01-01"}
      args = %{
        site_id: site.domain,
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_timeseries(nil, args, nil)

      assert {:error, _} = result
    end

    test "returns error for non-existent site", %{site: _site} do
      date_range = %{from: "2024-01-01", to: "2024-01-07"}
      args = %{
        site_id: "non-existent-12345.example.com",
        date_range: date_range,
        metrics: ["visitors"]
      }

      result = Aggregate.get_timeseries(nil, args, nil)

      assert {:error, _} = result
    end
  end
end
