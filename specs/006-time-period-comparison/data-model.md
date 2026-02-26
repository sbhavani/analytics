# Data Model: Time Period Comparison

## Overview

This document describes the data entities and structures used for the time period comparison feature in Plausible Analytics.

## Existing Entities

### Date Range

Represents a time period with a start date and end date.

**Source**: `lib/plausible/stats/date_time_range.ex`

| Field | Type | Description |
|-------|------|-------------|
| first | DateTime | Start of the period |
| last | DateTime | End of the period |
| timezone | String | Timezone for the date range |

### Query

Represents a complete analytics query including date range and comparison settings.

**Source**: `lib/plausible/stats/query.ex`

| Field | Type | Description |
|-------|------|-------------|
| utc_time_range | DateTimeRange | UTC time range for the query |
| input_date_range | atom | Input date range type (e.g., :day, :month) |
| include | QueryInclude | Include options including comparison settings |

### QueryInclude

Contains comparison and other optional query parameters.

**Source**: `lib/plausible/stats/query_include.ex`

| Field | Type | Description |
|-------|------|-------------|
| compare | atom/tuple | Comparison mode |
| compare_match_day_of_week | boolean | Whether to match day of week |

## Comparison Mode Enum

**Location**: `assets/js/dashboard/dashboard-time-periods.ts`

| Value | Description |
|-------|-------------|
| `off` | No comparison |
| `previous_period` | Compare with previous period |
| `year_over_year` | Compare with same period last year |
| `custom` | Custom date range comparison |

## Relationship Diagram

```
Query
├── utc_time_range: DateTimeRange (main period)
├── comparison_utc_time_range: DateTimeRange (comparison period)
└── include
    └── compare: ComparisonMode
```

## API Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| period | string | Main period (day, month, year, custom) |
| date | string | Custom date range (from/to) |
| comparison | string | Comparison mode |
| compare_from | string | Custom comparison start date |
| compare_to | string | Custom comparison end date |
| match_day_of_week | boolean | Match day of week option |

## Percentage Change Calculation

The percentage change is calculated as:

```
((current_value - comparison_value) / comparison_value) × 100
```

**Source**: Handled in API response transformation, displayed in `metric-value.tsx`
