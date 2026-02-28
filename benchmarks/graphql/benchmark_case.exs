defmodule Plausible.GraphQL.BenchmarkCase do
  @moduledoc """
  Benchmark case for GraphQL performance testing.
  Provides common setup and helper functions.
  """

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import Plausible.GraphQL.BenchmarkCase
    end
  end

  @doc """
  Measures execution time of a function in microseconds.
  """
  def measure_time(fun) do
    {time, result} = :timer.tc(fun)
    {time, result}
  end

  @doc """
  Runs a function multiple times and returns the average time in microseconds.
  """
  def benchmark(fun, iterations \\ 1000) do
    times =
      for _ <- 1..iterations do
        {time, _} = :timer.tc(fun)
        time
      end

    avg = Enum.sum(times) / length(times)
    min = Enum.min(times)
    max = Enum.max(times)

    %{
      iterations: iterations,
      average_us: avg,
      average_ms: avg / 1000,
      min_us: min,
      max_us: max,
      times: times
    }
  end

  @doc """
  Creates a sample GraphQL query for benchmarking.
  """
  def sample_pageview_query do
    """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}) {
        url
        timestamp
        visitorId
      }
    }
    """
  end

  @doc """
  Creates a sample aggregate query for benchmarking.
  """
  def sample_aggregate_query do
    """
    query {
      pageviewAggregate(siteId: "1", dateRange: {from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z"}, aggregation: {type: COUNT}) {
        value
        type
      }
    }
    """
  end

  @doc """
  Creates a complex query with filters for benchmarking.
  """
  def sample_filtered_query do
    """
    query {
      pageviews(
        siteId: "1",
        dateRange: {from: "2025-01-01T00:00:00Z", to: "2025-12-31T23:59:59Z"},
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
  end

  @doc """
  Formats benchmark results for display.
  """
  def format_results(name, results) do
    IO.puts("\n=== #{name} ===")
    IO.puts("Iterations: #{results.iterations}")
    IO.puts("Average: #{Float.round(results.average_us, 2)} µs (#{Float.round(results.average_ms, 4)} ms)")
    IO.puts("Min: #{results.min_us} µs")
    IO.puts("Max: #{results.max_us} µs")
  end
end
