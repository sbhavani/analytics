# Research: Time Period Comparison Feature

**Date**: 2026-02-27
**Feature**: Time Period Comparison

## Overview

This document captures the research findings from analyzing the existing codebase for the time period comparison feature.

## Existing Implementation

### Backend Components

#### 1. Comparison Logic (`lib/plausible/stats/comparisons.ex`)

The `Comparisons` module provides functions for comparing query periods:

- **Modes supported**:
  - `:previous_period` - shifts back by same number of days
  - `:year_over_year` - shifts back by 1 year
  - `{:date_range, from, to}` - custom date range

- **Key functions**:
  - `get_comparison_utc_time_range/1` - generates comparison DateTimeRange
  - `get_comparison_query/2` - builds comparison query
  - `add_comparison_filters/2` - adds filters for dimension comparisons

#### 2. Percentage Change Calculation (`lib/plausible/stats/compare.ex`)

The `Compare` module calculates percentage changes:

- `calculate_change/3` - calculates change based on metric type
- `percent_change/2` - calculates percentage change between two values

**Formula**: `((current - comparison) / comparison) * 100`

**Edge cases handled**:
- When comparison is 0 and current > 0: returns 100%
- When both are 0: returns 0%

### Frontend Components

#### 1. Comparison Period Menu (`assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`)

- UI for selecting comparison mode
- Options: Off, Previous Period, Year over Year, Custom
- Match day of week option

#### 2. Dashboard Time Periods (`assets/js/dashboard/dashboard-time-periods.ts`)

- Time period constants and utilities
- Comparison mode definitions

#### 3. Top Stats Display (`assets/js/dashboard/stats/graph/top-stats.js`)

- Displays metrics with comparison values
- Shows percentage change with directional indicators
- Renders both current and comparison period values

### Tests

- `test/plausible/stats/comparisons_test.exs`
- `test/plausible/stats/compare_test.exs`

## Conclusion

The time period comparison feature is **already fully implemented** in the codebase. All requirements from the specification are satisfied by existing code.

## Recommendations

1. Verify existing tests pass
2. Run manual testing to confirm UI/UX matches requirements
3. Consider adding tests for any edge cases not covered
