defmodule Plausible.GraphQL.Benchmarks.SchemaParsing do
  @moduledoc """
  Benchmarks for GraphQL schema parsing performance.

  This module measures the performance of:
  - Schema compilation
  - Query parsing
  - Type resolution
  """

  alias Plausible.GraphQL.Schema

  @doc """
  Benchmarks schema compilation time.
  """
  def benchmark_schema_compilation do
    IO.puts("\n# Schema Compilation Benchmark")

    # Warmup
    for _ <- 1..10 do
      Absinthe.Schema.compile(Schema)
    end

    # Actual benchmark
    results =
      for i <- 1..100 do
        {time, _} = :timer.tc(fn ->
          # Schema is already compiled, this measures lookup overhead
          Schema.__absinthe_type__(:query)
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average type lookup: #{Float.round(avg, 2)} µs")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 100}
  end

  @doc """
  Benchmarks query parsing performance.
  """
  def benchmark_query_parsing do
    IO.puts("\n# Query Parsing Benchmark")

    query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        url
        timestamp
      }
    }
    """

    # Warmup
    for _ <- 1..10 do
      Absinthe.parse(query)
    end

    # Actual benchmark
    results =
      for _ <- 1..1000 do
        {time, _} = :timer.tc(fn ->
          Absinthe.parse!(query)
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average parse time: #{Float.round(avg, 2)} µs")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 1000}
  end

  @doc """
  Benchmarks document validation.
  """
  def benchmark_document_validation do
    IO.puts("\n# Document Validation Benchmark")

    query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        url
        timestamp
      }
    }
    """

    {:ok, document, _} = Absinthe.parse(query)

    # Warmup
    for _ <- 1..10 do
      Absinthe.Phase.validate(Schema, document, [])
    end

    # Actual benchmark
    results =
      for _ <- 1..500 do
        {time, _} = :timer.tc(fn ->
          Absinthe.Phase.validate(Schema, document, [])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average validation time: #{Float.round(avg, 2)} µs")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 500}
  end

  @doc """
  Benchmarks field resolution.
  """
  def benchmark_field_resolution do
    IO.puts("\n# Field Resolution Benchmark")

    query = """
    query {
      pageviews(siteId: "1", dateRange: {from: "2026-01-01", to: "2026-01-31"}) {
        url
        timestamp
      }
    }
    """

    {:ok, document, _} = Absinthe.parse(query)
    {:ok, validated, _} = Absinthe.Phase.validate(Schema, document, [])

    # Warmup
    for _ <- 1..10 do
      Absinthe.Phase.run(validated, [schema: Schema])
    end

    # Actual benchmark
    results =
      for _ <- 1..100 do
        {time, _} = :timer.tc(fn ->
          Absinthe.Phase.run(validated, [schema: Schema])
        end)
        time
      end

    avg = Enum.sum(results) / length(results)
    IO.puts("Average resolution time: #{Float.round(avg, 2)} µs (#{Float.round(avg/1000, 2)} ms)")
    IO.puts("Min: #{Enum.min(results)} µs")
    IO.puts("Max: #{Enum.max(results)} µs")

    %{average_us: avg, iterations: 100}
  end

  @doc """
  Runs all schema parsing benchmarks.
  """
  def run_all do
    IO.puts("=" <> String.duplicate("=", 60))
    IO.puts("GraphQL Schema Parsing Benchmarks")
    IO.puts("=" <> String.duplicate("=", 60))

    benchmark_schema_compilation()
    benchmark_query_parsing()
    benchmark_document_validation()
    benchmark_field_resolution()

    IO.puts("\n" <> String.duplicate("=", 62))
    IO.puts("Schema parsing benchmarks complete")
    IO.puts(String.duplicate("=", 62))
  end
end
