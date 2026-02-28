defmodule Plausible.GraphQL.Benchmarks.Aggregation do
  @moduledoc """
  Benchmarks for GraphQL aggregation performance.

  This module measures the performance of:
  - COUNT aggregation
  - SUM aggregation
  - AVG aggregation
  - Complex multi-aggregation queries
  """

  alias Plausible.GraphQL.Schema

  @doc """
  Benchmarks COUNT aggregation.
  """
  def benchmark_count_aggregation do
    IO.puts("\n# COUNT Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        aggregation: {type: COUNT}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average COUNT aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks SUM aggregation.
  """
  def benchmark_sum_aggregation do
    IO.puts("\n# SUM Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        aggregation: {type: SUM, metric: "visitors"}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average SUM aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks AVG aggregation.
  """
  def benchmark_avg_aggregation do
    IO.puts("\n# AVG Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        aggregation: {type: AVG, metric: "visit_duration"}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average AVG aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks MAX aggregation.
  """
  def benchmark_max_aggregation do
    IO.puts("\n# MAX Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        aggregation: {type: MAX, metric: "page_load_time"}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average MAX aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks MIN aggregation.
  """
  def benchmark_min_aggregation do
    IO.puts("\n# MIN Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        aggregation: {type: MIN, metric: "page_load_time"}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average MIN aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks filtered aggregation.
  """
  def benchmark_filtered_aggregation do
    IO.puts("\n# Filtered Aggregation Benchmark")

    query = """
    query {
      pageviewAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        filter: {browser: "Chrome", country: "US"},
        aggregation: {type: COUNT}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average filtered aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks event aggregation.
  """
  def benchmark_event_aggregation do
    IO.puts("\n# Event Aggregation Benchmark")

    query = """
    query {
      eventAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        filter: {eventName: "pageview"},
        aggregation: {type: COUNT}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average event aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks custom metric aggregation.
  """
  def benchmark_custom_metric_aggregation do
    IO.puts("\n# Custom Metric Aggregation Benchmark")

    query = """
    query {
      customMetricAggregate(
        siteId: "1",
        dateRange: {from: "2026-01-01", to: "2026-01-31"},
        filter: {metricName: "revenue"},
        aggregation: {type: SUM}
      ) {
        value
        type
      }
    }
    """

    # Warmup
    for _ <- 1..5 do
      Absinthe.run(query, Schema, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(query, Schema, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average custom metric aggregation time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Compares aggregation performance across date ranges.
  """
  def benchmark_aggregation_by_date_range do
    IO.puts("\n# Aggregation Performance by Date Range")

    aggregation_types = [
      {"COUNT", "COUNT", nil},
      {"SUM (visitors)", "SUM", "visitors"},
      {"AVG (duration)", "AVG", "visit_duration"}
    ]

    ranges = [
      {"7 days", "2026-01-25", "2026-01-31"},
      {"30 days", "2026-01-01", "2026-01-31"},
      {"90 days", "2025-11-01", "2026-01-31"}
    ]

    for {range_label, from, to} <- ranges do
      IO.puts("\n#{range_label}:")
      for {agg_label, type, metric} <- aggregation_types do
        metric_str = if metric, do: ~s(metric: "#{metric}"), else: ""
        query = """
        query {
          pageviewAggregate(
            siteId: "1",
            dateRange: {from: "#{from}", to: "#{to}"},
            aggregation: {type: #{type}#{metric_str}}
          ) {
            value
            type
          }
        }
        """

        # Warmup
        for _ <- 1..3 do
          Absinthe.run(query, Schema, [])
        end

        results =
          for _ <- 1..30 do
            {time, _} = :timer.tc(fn ->
              Absinthe.run(query, Schema, [])
            end)
            time
          end

        avg = Enum.sum(results) / length(results)
        IO.puts("  #{agg_label}: #{Float.round(avg, 2)} µs")
      end
    end

    :ok
  end

  @doc """
  Runs all aggregation benchmarks.
  """
  def run_all do
    IO.puts("=" <> String.duplicate("=", 60))
    IO.puts("GraphQL Aggregation Benchmarks")
    IO.puts("=" <> String.duplicate("=", 60))

    benchmark_count_aggregation()
    benchmark_sum_aggregation()
    benchmark_avg_aggregation()
    benchmark_max_aggregation()
    benchmark_min_aggregation()
    benchmark_filtered_aggregation()
    benchmark_event_aggregation()
    benchmark_custom_metric_aggregation()
    benchmark_aggregation_by_date_range()

    IO.puts("\n" <> String.duplicate("=", 62))
    IO.puts("Aggregation benchmarks complete")
    IO.puts(String.duplicate("=", 62))
  end
end
