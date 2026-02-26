# Research: Time Period Comparison Feature

**Date**: 2026-02-26
**Feature**: Time Period Comparison
**Status**: Feature already implemented in codebase

## Executive Summary

The time period comparison feature described in the specification already exists in the codebase. This research document outlines the existing implementation.

## Existing Implementation

### Backend (Elixir/Phoenix)

#### Comparison Logic (`lib/plausible/stats/comparisons.ex`)

**Decision**: Use existing comparison module that supports three comparison modes

**Rationale**: The module provides:
- `:previous_period` - Automatically shifts date range back by same duration
- `:year_over_year` - Shifts date range back by exactly 1 year
- `{:date_range, from, to}` - Custom date range comparison
- Day-of-week matching option for accurate comparison

**Alternatives considered**:
- Building new comparison logic (rejected - YAGNI, existing code works)
- Using external analytics tools (rejected - privacy-first requirement)

#### Query Structure (`lib/plausible/stats/query.ex`)

**Decision**: Extend existing Query struct with `comparison_utc_time_range` field

**Fields**:
- `utc_time_range` - Main period time range
- `comparison_utc_time_range` - Comparison period time range
- `input_date_range` - Original period type (`:day`, `:month`, etc.)

#### Query Runner (`lib/plausible/stats/query_runner.ex`)

**Decision**: Execute main and comparison queries in parallel

**Rationale**:
- Both queries run against ClickHouse
- Results combined with `value`, `comparison_value`, `change`
- Efficient parallel execution

### Frontend (React/TypeScript)

#### State Management (`assets/js/dashboard/dashboard-state.ts`)

**Decision**: Store comparison settings in dashboard state

**State fields**:
- `comparison`: Current comparison mode (`:off`, `:previous_period`, `:year_over_year`, `:custom`)
- `compare_from`: Start date of comparison period
- `compare_to`: End date of comparison period
- `match_day_of_week`: Boolean for day-of-week matching

#### UI Components

**Decision**: Reuse existing UI patterns for consistency

Components:
- `comparison-period-menu.tsx` - Dropdown to select comparison mode
- `date-range-calendar.tsx` - Custom date range picker
- `metric-value.tsx` - Displays comparison values
- `change-arrow.tsx` - Color-coded percentage change indicator

## Percentage Change Calculation

Formula: `((current_value - comparison_value) / comparison_value) * 100`

Display logic:
- Positive change (increase): Green color, upward arrow
- Negative change (decrease): Red color, downward arrow
- Zero change: Neutral color
- Division by zero: Display "N/A" or "New"

Special handling for bounce_rate (inverted - decrease is good)

## API Integration

**Decision**: Use query parameters for comparison

**Parameters**:
- `comparison` - Mode: `previous_period`, `year_over_year`, `custom`
- `compare_from` - ISO date string for comparison start
- `compare_to` - ISO date string for comparison end
- `match_day_of_week` - `true`/`false` for day matching

## Test Coverage

Existing tests in:
- `test/plausible/stats/comparisons_test.exs`
- `test/plausible/stats/query_test.exs`

## Recommendations

The feature is fully implemented. If issues are found:
1. Check comparison mode selection in UI
2. Verify query parameters are passed correctly
3. Check ClickHouse query execution
4. Review test coverage for edge cases
