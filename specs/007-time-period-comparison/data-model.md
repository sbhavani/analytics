# Data Model: Time Period Comparison

**Date**: 2026-02-26
**Feature**: Time Period Comparison

## Overview

This document describes the data entities and structures used for time period comparison in the Plausible Analytics system.

## Core Entities

### 1. Query

Represents a time-bound analytics query with optional comparison period.

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `utc_time_range` | `DateTime.t()` tuple | Main period: `{start_utc, end_utc}` |
| `comparison_utc_time_range` | `DateTime.t()` tuple or `nil` | Comparison period: `{start_utc, end_utc}` |
| `input_date_range` | `atom` | Period type: `:day`, `:month`, `:"7d"`, etc. |
| `site_id` | `integer` | The site being queried |
| `filters` | `map` | Applied filters |
| `include_imported` | `boolean` | Include imported data |

**Validation**:
- `utc_time_range` is required
- `comparison_utc_time_range` is optional (nil when comparison disabled)
- Comparison range cannot overlap with main range

---

### 2. ComparisonMode

Enumeration of supported comparison modes.

**Values**:
| Value | Description |
|-------|-------------|
| `:off` | No comparison - single period view |
| `:previous_period` | Compare against equivalent previous period |
| `:year_over_year` | Compare against same period last year |
| `:custom` | User-specified custom comparison period |

---

### 3. DateRange

Represents a calendar date range for comparison selection.

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `from` | `Date.t()` | Start date (inclusive) |
| `to` | `Date.t()` | End date (inclusive) |

**Validation**:
- `from` must be before or equal to `to`
- Range cannot include future dates (warns user)
- Range cannot overlap with other selected range

---

### 4. AggregateResult

The computed result for a metric including comparison data.

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| `metric` | `atom` | Metric name (`:visitors`, `:visits`, etc.) |
| `value` | `integer` or `float` | Main period value |
| `comparison_value` | `integer` or `float` or `nil` | Comparison period value |
| `change` | `float` or `nil` | Percentage change |

**Calculated Field**:
- `change`: `((value - comparison_value) / comparison_value) * 100` (rounded to 2 decimal places)

**Edge Cases**:
- `comparison_value` is `nil` when comparison is disabled
- `change` is `nil` when `comparison_value` is `nil` or zero
- Division by zero displays as "N/A"

---

### 5. Metric

Supported analytics metrics that can be compared.

**Values**:
| Metric | Type | Unit | Notes |
|--------|------|------|-------|
| `:visitors` | `integer` | count | Unique visitors |
| `:visits` | `integer` | count | Total visits |
| `:pageviews` | `integer` | count | Total pageviews |
| `:bounce_rate` | `float` | percentage | Inverted (lower is better) |
| `:visit_duration` | `integer` | seconds | Average visit duration |
| `:views_per_visit` | `float` | ratio | Pageviews / visits |
| `:conversion_rate` | `float` | percentage | Goals / visitors |

---

## State Management (Frontend)

### DashboardState

React state containing comparison settings.

```typescript
interface DashboardState {
  period: DashboardPeriod    // Current period type
  from: Date                 // Current period start
  to: Date                  // Current period end
  comparison: ComparisonMode // Comparison mode
  compare_from?: Date        // Comparison period start
  compare_to?: Date          // Comparison period end
  match_day_of_week: boolean // Enable day-of-week matching
}
```

---

## API Contract

### Query Parameters

```
GET /api/stats/{site_id}/top-stats

Query Parameters:
- period: string (day, 7d, month, custom, etc.)
- from: ISO date string (for custom periods)
- to: ISO date string (for custom periods)
- comparison: string (previous_period, year_over_year, custom)
- compare_from: ISO date string (for custom comparison)
- compare_to: ISO date string (for custom comparison)
- match_day_of_week: boolean string
```

### Response

```json
{
  "results": [
    {
      "metric": "visitors",
      "value": 1500,
      "comparison_value": 1200,
      "change": 25.0
    }
  ]
}
```

---

## Relationships

```
Query
  ├── has one DateRange (main period)
  └── has one DateRange (comparison period) [optional]

AggregateResult
  ├── belongs to Metric
  └── calculates Change from value + comparison_value

DashboardState
  ├── stores ComparisonMode
  ├── stores DateRange (main)
  └── stores DateRange (comparison) [optional]
```

---

## Data Flow

1. User selects comparison mode in UI
2. DashboardState updates with comparison settings
3. API request includes comparison query params
4. QueryParser extracts comparison range
5. Comparisons module calculates shifted comparison range
6. QueryRunner executes main + comparison queries in parallel
7. Aggregate module calculates change percentages
8. Response includes value, comparison_value, change for each metric
9. Frontend displays with color-coded indicators
