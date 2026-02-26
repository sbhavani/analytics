# Data Model: Time Period Comparison

**Feature**: Time Period Comparison - Compare metrics between two date ranges with percentage change display
**Status**: Already implemented in codebase

## Entities

### ComparisonMode (Enum)
Represents the type of comparison to perform.

| Value | Description |
|-------|-------------|
| `off` | No comparison, show only current period |
| `previous_period` | Compare with the same period immediately before |
| `year_over_year` | Compare with the same period from the previous year |
| `custom` | User-defined custom date range |

### DateRangePair
A data structure containing two date ranges (primary and comparison) that define the time periods being compared.

| Field | Type | Description |
|-------|------|-------------|
| `primary_range` | DateTimeRange | The main period being analyzed |
| `comparison_range` | DateTimeRange | The period to compare against |
| `mode` | ComparisonMode | Type of comparison |
| `match_day_of_week` | boolean | Whether to align day of week |

### ComparisonResult
The calculated metrics for both periods including absolute values and percentage change.

| Field | Type | Description |
|-------|------|-------------|
| `metric` | string | The metric name (visitors, pageviews, etc.) |
| `primary_value` | number | Value for primary period |
| `comparison_value` | number | Value for comparison period |
| `change` | number | Percentage change: ((primary - comparison) / comparison) * 100 |
| `change_direction` | enum | `up`, `down`, `unchanged`, `unavailable` |

### PeriodPreset
Predefined comparison options that users can quickly select.

| Preset | Primary Period | Comparison Period |
|--------|---------------|-------------------|
| This Week vs Last Week | Current week | Previous week (same length) |
| This Month vs Last Month | Current month | Previous month |
| This Quarter vs Last Quarter | Current quarter | Previous quarter |
| This Year vs Last Year | Current year | Previous year |

## Query Parameters (API Contract)

The comparison state is persisted via URL query parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `comparison` | string | `previous_period`, `year_over_year`, `custom` |
| `compare_from` | date | Start of custom comparison period (YYYY-MM-DD) |
| `compare_to` | date | End of custom comparison period (YYYY-MM-DD) |
| `match_day_of_week` | boolean | Align comparison to same day of week |

## State Transitions

### Enabling Comparison
1. User selects comparison mode from dropdown
2. Frontend updates URL query params
3. Backend parses params and builds comparison query
4. Stats module calculates both periods
5. Results returned with comparison data

### Changing Period
1. User selects new primary period
2. Comparison period recalculated based on mode
3. Both queries executed in parallel
4. Results merged with change calculation

## Validation Rules

1. Custom comparison dates cannot overlap with primary period
2. Comparison period cannot be in the future
3. Comparison period must have data available
4. Zero comparison values result in unavailable change (N/A)

## Existing Code Locations

- Backend: `lib/plausible/stats/comparisons.ex`
- Frontend State: `assets/js/dashboard/dashboard-state.ts`
- Frontend UI: `assets/js/dashboard/nav-menu/query-periods/`
