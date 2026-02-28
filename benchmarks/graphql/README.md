# GraphQL Performance Benchmarks

This directory contains performance benchmarks for the Plausible GraphQL Analytics API.

## Overview

The benchmarks measure the performance of GraphQL operations including:

- **Schema Parsing**: Schema compilation, query parsing, document validation, field resolution
- **Query Execution**: Pageviews, events, custom metrics, filtered queries, pagination
- **Aggregation**: COUNT, SUM, AVG, MIN, MAX operations across various date ranges

## Directory Structure

```
benchmarks/graphql/
├── README.md                    # This file
├── benchmarks.ex                # Main benchmark runner
├── benchmark_case.exs           # Benchmark utilities and helpers
├── schema_parsing.exs           # Schema parsing benchmarks
├── query_execution.exs          # Query execution benchmarks
└── aggregation.exs              # Aggregation benchmarks
```

## Running Benchmarks

### Running All Benchmarks

```bash
# From the project root with iex
iex> c("benchmarks/graphql/benchmarks.ex")
iex> Plausible.GraphQL.Benchmarks.run_all()
```

### Running Individual Benchmark Categories

```bash
# Schema parsing benchmarks
iex> Plausible.GraphQL.Benchmarks.SchemaParsing.run_all()

# Query execution benchmarks
iex> Plausible.GraphQL.Benchmarks.QueryExecution.run_all()

# Aggregation benchmarks
iex> Plausible.GraphQL.Benchmarks.Aggregation.run_all()
```

### Running Specific Benchmarks

```bash
# Query parsing only
iex> Plausible.GraphQL.Benchmarks.SchemaParsing.benchmark_query_parsing()

# Pageview query
iex> Plausible.GraphQL.Benchmarks.QueryExecution.benchmark_pageview_query()

# COUNT aggregation
iex> Plausible.GraphQL.Benchmarks.Aggregation.benchmark_count_aggregation()
```

## Benchmark Results Interpretation

### Schema Parsing

| Metric | Description |
|--------|-------------|
| Type lookup | Time to resolve a type from the schema |
| Parse time | Time to parse a GraphQL query string |
| Validation time | Time to validate the query structure |
| Resolution time | Time to resolve all fields in a query |

### Query Execution

| Metric | Description |
|--------|-------------|
| Execution time | Total time from query to result |
| Pagination overhead | Impact of different page sizes |
| Filter complexity | Impact of filter complexity |

### Aggregation

| Metric | Description |
|--------|-------------|
| COUNT | Simple count aggregation |
| SUM | Sum aggregation for metrics |
| AVG | Average aggregation |
| MIN/MAX | Min/max value aggregations |
| Filtered | Aggregation with applied filters |

## Performance Targets

Based on the project requirements:
- 5s response time for 30-day queries
- 100 concurrent requests
- 95% success rate

## Notes

- Benchmarks include warmup iterations to ensure JIT compilation
- Each benchmark runs multiple iterations and reports average, min, and max
- Results may vary based on hardware and system load
- Run benchmarks on a consistent system for comparative analysis
