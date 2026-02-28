# Quickstart: Time Period Comparison

**Feature**: Time Period Comparison

## Overview

This document provides developer onboarding for the time period comparison feature. The feature is already implemented and enables users to compare metrics between two date ranges with percentage change display.

## Key Files

### Backend

| File | Purpose |
|------|---------|
| `lib/plausible/stats/comparisons.ex` | Core comparison logic |
| `lib/plausible/stats/compare.ex` | Percentage change calculation |
| `lib/plausible/stats/query.ex` | Query struct with comparison config |
| `lib/plausible/stats/datetime_range.ex` | Date range types and utilities |

### Frontend

| File | Purpose |
|------|---------|
| `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Comparison UI |
| `assets/js/dashboard/dashboard-time-periods.ts` | Period constants |
| `assets/js/dashboard/stats/graph/top-stats.js` | Metrics display |
| `assets/js/dashboard/stats/reports/change-arrow.tsx` | Change indicator |

### Tests

| File | Purpose |
|------|---------|
| `test/plausible/stats/comparisons_test.exs` | Backend comparison tests |
| (no file) | `test/plausible/stats/compare_test.exs` does not exist - no dedicated test file for percentage change logic |

## How It Works

### 1. User Selects Comparison Mode

User selects comparison mode via the comparison period menu:
- Previous Period (e.g., this week vs last week)
- Year over Year (e.g., this month vs same month last year)
- Custom Date Range

### 2. Backend Processes Comparison

The backend:
1. Builds the main query for current period
2. Builds comparison query using `Comparisons.get_comparison_query/2`
3. Executes both queries against ClickHouse
4. Calculates percentage changes using `Compare.percent_change/2`

### 3. Frontend Displays Results

The frontend displays:
- Current period metrics
- Comparison period metrics
- Percentage change with directional indicators (arrows, colors)

## Running Tests

```bash
# Run comparison tests
mix test test/plausible/stats/comparisons_test.exs

# Run percentage change tests
mix test test/plausible/stats/compare_test.exs
```

## Adding a New Comparison Mode

To add a new comparison mode (e.g., "Last 7 days vs 7 days before"):

1. **Backend**: Add mode to `lib/plausible/stats/comparisons.ex`
2. **Frontend**: Add mode constant to `assets/js/dashboard/dashboard-time-periods.ts`
3. **Frontend**: Add menu option in `comparison-period-menu.tsx`
4. **Tests**: Add tests for the new mode

## Common Issues

### Issue: Comparison returns no data

- Check that comparison date range has data
- Verify timezone handling is correct

### Issue: Percentage shows 100% when comparison is 0

- This is expected behavior (100% increase from 0)
- Consider displaying "N/A" in UI for this case

### Issue: Different results for same period

- Check if "match day of week" option is enabled
- This adjusts comparison to match day of week, not exact dates

### Issue: Overlapping date ranges

- The implementation does not explicitly handle overlapping date ranges
- Users can select overlapping periods but no warning is displayed
- This is a potential enhancement opportunity

## Verification Results (Feb 2026)

The following items were verified through code inspection:

| Requirement | Status | Location |
|------------|--------|----------|
| Previous period comparison | VERIFIED | `lib/plausible/stats/comparisons.ex` |
| Year over year comparison | VERIFIED | `lib/plausible/stats/comparisons.ex` |
| Custom date range | VERIFIED | `lib/plausible/stats/comparisons.ex:185-187` |
| Percentage change calculation | VERIFIED | `lib/plausible/stats/compare.ex:27-37` |
| Zero comparison value handling | VERIFIED | Returns 100% (line 29-30) |
| Both zero values handling | VERIFIED | Returns 0% (line 32-33) |
| Change arrow display | VERIFIED | `assets/js/dashboard/stats/reports/change-arrow.tsx` |
| Comparison presets | VERIFIED | `assets/js/dashboard/dashboard-time-periods.ts` |
| Multiple metrics support | VERIFIED | `top-stats.js` displays all metrics |

## Known Gaps

- No dedicated test file for `Compare.percent_change/2` function
- No explicit handling for overlapping date ranges (spec edge case)
- Backend tests could not run due to dependency compilation issues (`gen_smtp` package)
