# Data Model: Time Period Comparison

## Overview

This document defines the data model for the Time Period Comparison feature, based on existing Plausible Analytics architecture.

## Core Entities

### Query (Existing)

The existing `Query` struct already contains comparison support:

```elixir
%Query{
  utc_time_range: DateTimeRange.t(),
  comparison_utc_time_range: DateTimeRange.t() | nil,
  include: %{
    compare: :previous_period | :year_over_year | {:date_range, Date.t(), Date.t()} | nil,
    compare_match_day_of_week: boolean()
  }
}
```

### DateRange

Represents a period of time for querying analytics data.

| Field | Type | Description |
|-------|------|-------------|
| first | Date.t() | Start date of the range |
| last | Date.t() | End date of the range |

### ComparisonMode

Enum defining available comparison types.

| Value | Description |
|-------|-------------|
| `:previous_period` | Compare with the same period shifted back |
| `:year_over_year` | Compare with same dates from previous year |
| `{:date_range, from, to}` | Custom date range comparison |
| `nil` | No comparison |

### MetricValue

A single metric value from query results.

| Field | Type | Description |
|-------|------|-------------|
| name | atom | Metric identifier (e.g., :visitors, :pageviews) |
| value | number | Raw metric value |
| formatted | string | Human-readable formatted value |

### ComparisonResult

The result of comparing a metric between two periods.

| Field | Type | Description |
|-------|------|-------------|
| metric | atom | Metric identifier |
| current_value | number | Value for current period |
| comparison_value | number | Value for comparison period |
| percentage_change | float | Calculated percentage change |
| direction | :up \| :down \| :neutral | Direction indicator |

## Validation Rules

1. **Date Range Validation**:
   - Start date must be before or equal to end date
   - Date range must be within available data window

2. **Comparison Validation**:
   - Comparison mode must be valid enum value
   - Custom comparison dates must both be provided

3. **Percentage Calculation**:
   - When comparison value is 0: Display "N/A" or "No data"
   - When current value is 0 and comparison > 0: Display "-100%"
   - Missing data in either period: Display appropriate indicator

## State Transitions

```
No Comparison → Select Mode → Previous Period
                              → Year over Year
                              → Custom Date Range

Previous Period → Change Mode → Year over Year
                              → Custom Date Range
                              → Disable Comparison

Custom Date Range → Select Dates → Valid Range
                               → Invalid Range (error)
```

## Relationships

- Query contains one optional Comparison (via `comparison_utc_time_range`)
- Query results contain list of Metrics
- Each Metric has optional ComparisonResult when comparison enabled
- DashboardState manages comparison UI state (existing)

## Integration Points

| Component | Interface | Purpose |
|-----------|-----------|---------|
| ClickHouse | SQL Queries | Fetch metrics for both periods |
| API Controller | HTTP Params | Accept comparison mode/params |
| Frontend State | React Context | Manage comparison UI state |
| Metric Display | Component Props | Show comparison values |
