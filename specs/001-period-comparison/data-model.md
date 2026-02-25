# Data Model: Time Period Comparison

## Overview

This document describes the data structures used by the Time Period Comparison feature. Since this feature is already implemented, this documents the existing data model.

## Frontend Data Types (TypeScript)

### ComparisonMode Enum

```typescript
export enum ComparisonMode {
  off = 'off',
  previous_period = 'previous_period',
  year_over_year = 'year_over_year',
  custom = 'custom'
}
```

### ComparisonMatchMode Enum

```typescript
export enum ComparisonMatchMode {
  MatchExactDate = 0,
  MatchDayOfWeek = 1
}
```

### DashboardState (Partial)

```typescript
type DashboardState = {
  period: DashboardPeriod
  comparison: ComparisonMode | null
  match_day_of_week: boolean
  date: Dayjs | null
  from: Dayjs | null
  to: Dayjs | null
  compare_from: Dayjs | null
  compare_to: Dayjs | null
  // ... other fields
}
```

### URL Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `comparison` | string | Comparison mode: `off`, `previous_period`, `year_over_year`, `custom` |
| `compare_from` | ISO date | Start of custom comparison period |
| `compare_to` | ISO date | End of custom comparison period |
| `match_day_of_week` | string | `true` or `false` |

## Backend Data Types (Elixir)

### QueryInclude.compare (Type)

```elixir
@type compare() :: nil | :previous_period | :year_over_year | {:date_range, Date.t(), Date.t()}
```

### Query Struct

```elixir
defstruct [
  imports: false,
  compare: nil,                          # Comparison mode
  compare_match_day_of_week: false,        # Match day of week option
  # ... other fields
]
```

## Key Entities

### Primary Period
- The main date range selected by the user for analysis
- Defined by: `period`, `date`, `from`, `to` fields in DashboardState
- Stored in URL for shareability

### Comparison Period
- The secondary date range used for comparison
- Calculated automatically (previous_period, year_over_year) or user-specified (custom)
- Defined by: `compare_from`, `compare_to` in DashboardState

### MetricValue
- Numeric value for a metric within a specific period
- Contains both current value and comparison value
- Includes percentage change calculation

### PercentageChange
- Calculated difference between primary and comparison values
- Expressed as percentage (positive or negative)
- Special handling for bounce_rate (inverted logic)

## State Transitions

### Comparison Mode Selection

```
off → previous_period → year_over_year → custom → off
         ↑_____________________________|
```

### Match Mode

```
MatchExactDate ↔ MatchDayOfWeek
```

## Validation Rules

1. Comparison is forbidden for `realtime` and `all` periods
2. Comparison is forbidden when segment is expanded
3. Custom comparison dates must be valid ISO dates
4. Custom comparison dates cannot be in the future (relative to current date

- **)

## StorageURL**: Primary storage for shareable state
- **LocalStorage**: User preferences (period, comparison mode, match day of week)
  - Key: `plausible_period_{domain}`
  - Key: `plausible_comparison_mode_{domain}`
  - Key: `plausible_comparison_match_day_of_week_{domain}`
