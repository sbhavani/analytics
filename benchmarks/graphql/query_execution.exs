defmodule Plausible.GraphQL.Benchmarks.QueryExecution do
  @moduledoc """
  Benchmarks for GraphQL query execution performance.

  This module measures the performance of:
  - Pageview query execution
  - Event query execution
  - Custom metric queries
  - Filter application
  """

  alias Plausible.GraphQL.Schema

  @doc """
  Benchmarks pageview list query execution.
  """
  def benchmark_pageview_query do
    IO.puts("\n# Pageview Query Execution Benchmark")

    query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        url
        timestamp
        visitorId
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
    IO.puts("Average execution time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks event query execution.
  """
  def benchmark_event_query do
    IO.puts("\n# Event Query Execution Benchmark")

    query = """
    query {
      events(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        name
        timestamp
        visitorId
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
    IO.puts("Average execution time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks custom metric query execution.
  """
  def benchmark_custom_metric_query do
    IO.puts("\n# Custom Metric Query Execution Benchmark")

    query = """
    query {
      customMetrics(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        name
        value
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
    IO.puts("Average execution time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks filtered query execution.
  """
  def benchmark_filtered_query do
    IO.puts("\n# Filtered Query Execution Benchmark")

    query = """
    query {
      pageviews(
        siteId: "1",
        dateRange: {from: "2025-01-01", to: "2025-12-31"},
        filter: {url: "/blog/**", browser: "Chrome"}
      ) {
        url
        timestamp
        visitorId
        browser
        country
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
    IO.puts("Average execution time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 50}
  end

  @doc """
  Benchmarks pagination performance.
  """
  def benchmark_pagination do
    IO.puts("\n# Pagination Benchmark")

    # Small page
    small_query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}, limit: 10, offset: 0) {
        url
        timestamp
      }
    }
    """

    # Large page
    large_query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}, limit: 1000, offset: 0) {
        url
        timestamp
      }
    }
    """

    # Offset pagination
    offset_query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}, limit: 100, offset: 500) {
        url
        timestamp
      }
    }
    """

    IO.puts("\nSmall page (10 items):")
    for _ <- 1..5 do
      Absinthe.run(small_query, Schema, [])
    end

    small_results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(small_query, Schema, [])
        end)
        time
      end

    IO.puts("Average: #{Float.round(Enum.sum(small_results) / length(small_results), 2)} µs")

    IO.puts("\nLarge page (1000 items):")
    for _ <- 1..5 do
      Absinthe.run(large_query, Schema, [])
    end

    large_results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(large_query, Schema, [])
        end)
        time
      end

    IO.puts("Average: #{Float.round(Enum.sum(large_results) / length(large_results), 2)} µs")

    IO.puts("\nOffset pagination (offset 500):")
    for _ <- 1..5 do
      Absinthe.run(offset_query, Schema, [])
    end

    offset_results =
      for _ <- 1..50 do
        {time, _} = :timer.tc(fn ->
          Absinthe.run(offset_query, Schema, [])
        end)
        time
      end

    IO.puts("Average: #{Float.round(Enum.sum(offset_results) / length(offset_results), 2)} µs")

    %{
      small_avg: Enum.sum(small_results) / length(small_results),
      large_avg: Enum.sum(large_results) / length(large_results),
      offset_avg: Enum.sum(offset_results) / length(offset_results)
    }
  end

  @doc """
  Benchmarks query execution with different date ranges.
  """
  def benchmark_date_ranges do
    IO.puts("\n# Date Range Performance Benchmark")

    query_template = fn from, to ->
      """
      query {
        pageviews(siteId: "1", dateRange: {from: "#{from}", to: "#{to}"}) {
          url
          timestamp
        }
      }
      """
    end

    ranges = [
      {"7 days", query_template.("2026-01-25", "2026-01-31")},
      {"30 days", query_template.("2026-01-01", "2026-01-31")},
      {"90 days", query_template.("2025-11-01", "2026-01-31")},
      {"180 days", query_template.("2025-08-01", "2026-01-31")},
      {"365 days", query_template.("2025-01-01", "2026-01-31")}
    ]

    for {label, query} <- ranges do
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
      IO.puts("#{label}: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    end

    :ok
  end

  @doc """
  Runs all query execution benchmarks.
  """
  def run_all do
    IO.puts("=" <> String.duplicate("=", 60))
    IO.puts("GraphQL Query Execution Benchmarks")
    IO.puts("=" <> String.duplicate("=", 60))

    benchmark_pageview_query()
    benchmark_event_query()
    benchmark_custom_metric_query()
    benchmark_filtered_query()
    benchmark_pagination()
    benchmark_date_ranges()

    IO.puts("\n" <> String.duplicate("=", 62))
    IO.puts("Query execution benchmarks complete")
    IO.puts(String.duplicate("=", 62))
  end
end
