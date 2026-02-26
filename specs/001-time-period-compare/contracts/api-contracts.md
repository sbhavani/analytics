# API Contracts: Time Period Comparison

## Overview

This document defines the API contracts for the Time Period Comparison feature.

## External API: Stats Query

### Existing Endpoint

```
GET /api/v1/stats/:domain/timeseries
GET /api/v1/stats/:domain/realtime/visitors
```

### Query Parameters (Existing)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| period | string | Yes | Time period (day, week, month, etc.) |
| date | string | No | Specific date for period |
| comparison | string | No | Comparison mode (previous_period, year_over_year) |
| compare_from | string | No | Start date for custom comparison |
| compare_to | string | No | End date for custom comparison |
| match_day_of_week | boolean | No | Match day of week in comparison |

### Response Format

```json
{
  "results": [
    {
      "date": "2024-01-01",
      "visitors": 100,
      "pageviews": 250,
      "comparison": {
        "date": "2024-01-08",
        "visitors": 90,
        "pageviews": 200,
        "change": {
          "visitors": 11.11,
          "pageviews": 25
        }
      }
    }
  ],
  "meta": {
    "date_range_label": "Jan 1 - Jan 7, 2024",
    "comparison_date_range_label": "Jan 8 - Jan 14, 2024"
  }
}
```

## Internal Query Interface

### Comparison Query Builder

The internal interface for building comparison queries:

```elixir
# Generate comparison query
comparison_query = Comparisons.get_comparison_query(source_query)

# Execute both queries
current_results = QueryRunner.run(site, source_query, metrics)
comparison_results = QueryRunner.run(site, comparison_query, metrics)

# Calculate percentage changes
combined = merge_with_percentage_change(current_results, comparison_results)
```

## Frontend State Contract

### Dashboard State Context

```typescript
interface ComparisonState {
  mode: 'off' | 'previous_period' | 'year_over_year' | 'custom'
  compare_from?: Date
  compare_to?: Date
  match_day_of_week: boolean | null
}

interface DashboardState {
  period: Period
  dateRange: DateRange
  comparison: ComparisonState
  // ...
}
```

### URL Parameters

| Key | Type | Description |
|-----|------|-------------|
| period | string | Selected period |
| from | string | Start date (for custom) |
| to | string | End date (for custom) |
| comparison | string | Comparison mode |
| compare_from | string | Comparison start date |
| compare_to | string | Comparison end date |
| match_day_of_week | string | "true" or "false" |

## Component Interface

### MetricValue Component

```typescript
interface MetricValueProps {
  listItem: {
    [metric: string]: number
    comparison: {
      [metric: string]: number
      change: {
        [metric: string]: number
      }
    }
  }
  metric: Metric
  renderLabel: (state: DashboardState) => string
  formatter?: (value: ValueType) => string
}
```
