defmodule Plausible.GraphQL.Benchmarks do
  @moduledoc """
  Main module for running GraphQL performance benchmarks.

  This module provides a unified interface to run all GraphQL-related benchmarks:
  - Schema parsing benchmarks
  - Query execution benchmarks
  - Aggregation benchmarks

  ## Usage

      # Run all benchmarks
      iex> Plausible.GraphQL.Benchmarks.run_all()

      # Run specific benchmark category
      iex> Plausible.GraphQL.Benchmarks.SchemaParsing.run_all()
      iex> Plausible.GraphQL.Benchmarks.QueryExecution.run_all()
      iex> Plausible.GraphQL.Benchmarks.Aggregation.run_all()

  ## Benchmark Categories

  1. Schema Parsing: Measures the performance of schema compilation,
     query parsing, document validation, and field resolution.

  2. Query Execution: Measures the performance of different query types
     including pageviews, events, custom metrics, and filtered queries.

  3. Aggregation: Measures the performance of various aggregation types
     (COUNT, SUM, AVG, MIN, MAX) across different date ranges.
  """

  alias Plausible.GraphQL.Benchmarks.SchemaParsing
  alias Plausible.GraphQL.Benchmarks.QueryExecution
  alias Plausible.GraphQL.Benchmarks.Aggregation

  @doc """
  Runs all GraphQL performance benchmarks.

  This is the main entry point for running benchmarks. It executes:
  - Schema parsing benchmarks
  - Query execution benchmarks
  - Aggregation benchmarks

  ## Options

  - `:schema` - Run schema parsing benchmarks (default: true)
  - `:queries` - Run query execution benchmarks (default: true)
  - `:aggregation` - Run aggregation benchmarks (default: true)

  ## Example

      iex> Plausible.GraphQL.Benchmarks.run_all()
  """
  def run_all(opts \\ []) do
    schema = Keyword.get(opts, :schema, true)
    queries = Keyword.get(opts, :queries, true)
    aggregation = Keyword.get(opts, :aggregation, true)

    IO.puts("\n" <> String.duplicate("=", 62))
    IO.puts("GraphQL Performance Benchmarks")
    IO.puts("Date: #{DateTime.utc_now() |> DateTime.format_iso8601()}")
    IO.puts(String.duplicate("=", 62))

    if schema, do: SchemaParsing.run_all()
    if queries, do: QueryExecution.run_all()
    if aggregation, do: Aggregation.run_all()

    IO.puts("\n" <> String.duplicate("=", 62))
    IO.puts("All benchmarks complete!")
    IO.puts(String.duplicate("=", 62))
  end

  @doc """
  Runs only schema parsing benchmarks.

  ## Example

      iex> Plausible.GraphQL.Benchmarks.run_schema()
  """
  def run_schema do
    SchemaParsing.run_all()
  end

  @doc """
  Runs only query execution benchmarks.

  ## Example

      iex> Plausible.GraphQL.Benchmarks.run_queries()
  """
  def run_queries do
    QueryExecution.run_all()
  end

  @doc """
  Runs only aggregation benchmarks.

  ## Example

      iex> Plausible.GraphQL.Benchmarks.run_aggregation()
  """
  def run_aggregation do
    Aggregation.run_all()
  end

  @doc """
  Prints benchmark configuration and system info.
  """
  def print_system_info do
    IO.puts("\n=== System Information ===")
    IO.puts("Elixir: #{System.version()}")
    IO.puts("OTP: #{String.upcase(inspect(:os.version()))}")
    IO.puts("ERTS: #{:erlang.system_info(:version)}")

    # Memory info
    :erlang.garbage_collect()
    mem = :erlang.memory()
    IO.puts("\n=== Memory (bytes) ===")
    IO.puts("Total: #{div(mem[:total], 1_000_000)} MB")
    IO.puts("Processes: #{div(mem[:processes], 1_000_000)} MB")
    IO.puts("Atom: #{div(mem[:atom], 1_000)} KB")
    IO.puts("Binary: #{div(mem[:binary], 1_000_000)} MB")
    IO.puts("Code: #{div(mem[:code], 1_000_000)} MB")
  end
end
