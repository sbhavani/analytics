# Quickstart: Time Period Comparison

**Date**: 2026-02-26
**Feature**: Time Period Comparison

## Overview

This guide explains how to use and test the time period comparison feature in Plausible Analytics.

## Using the Feature

### Selecting a Predefined Comparison

1. Navigate to your site dashboard
2. Locate the period selector (typically in the top navigation)
3. Click on the comparison dropdown
4. Select a comparison option:
   - **Previous Period**: Compares current period against the immediately preceding period of the same length
   - **Year over Year**: Compares current period against the same period one year ago

### Selecting a Custom Comparison

1. Click on the comparison dropdown
2. Select **Custom**
3. Use the date picker to select your comparison date range
4. Optionally enable "Match day of week" for more accurate comparison

### Interpreting Results

Once comparison is enabled, metrics display:
- **Current value**: Bold, prominent display
- **Comparison value**: Smaller, secondary display
- **Percentage change**: Color-coded indicator
  - **Green +**: Increase (good for visitors, visits, pageviews)
  - **Red -**: Decrease (good for visitors, visits, pageviews)
  - **Red +**: Increase (bad for bounce_rate - inverted metric)
  - **Green -**: Decrease (bad for bounce_rate - inverted metric)

## Testing the Feature

### Backend Tests

Run comparison logic tests:

```bash
mix test test/plausible/stats/comparisons_test.exs
```

Run query tests:

```bash
mix test test/plausible/stats/query_test.exs
```

### Frontend Tests

Run JavaScript tests:

```bash
npm test -- --testPathPattern=dashboard
```

### Manual Testing Checklist

- [ ] Select "Previous Period" and verify metrics show comparison
- [ ] Select "Year over Year" and verify year shift
- [ ] Select "Custom" and pick date range
- [ ] Verify error shows for overlapping date ranges
- [ ] Verify "N/A" shows when comparison value is zero
- [ ] Verify color coding is correct for all metric types
- [ ] Verify bounce_rate colors are inverted (decrease = green)
- [ ] Verify comparison persists after page refresh
- [ ] Verify can disable comparison and see only current period

### API Testing

Test the API directly:

```bash
curl "http://localhost:8000/api/stats/example.com/top-stats?period=month&comparison=previous_period"
```

Expected response:

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

## Development

### Key Files

| Component | File |
|-----------|------|
| Comparison Logic | `lib/plausible/stats/comparisons.ex` |
| Query Struct | `lib/plausible/stats/query.ex` |
| Query Runner | `lib/plausible/stats/query_runner.ex` |
| Aggregate | `lib/plausible/stats/aggregate.ex` |
| Frontend State | `assets/js/dashboard/dashboard-state.ts` |
| Comparison UI | `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` |
| Change Display | `assets/js/dashboard/stats/reports/change-arrow.tsx` |

### Adding a New Comparison Mode

1. Add mode to `ComparisonMode` enum in `dashboard-time-periods.ts`
2. Add logic in `lib/plausible/stats/comparisons.ex`
3. Add UI option in `comparison-period-menu.tsx`
4. Add tests for the new mode

## Troubleshooting

### Comparison Not Showing

1. Check browser console for errors
2. Verify API is returning comparison_value in response
3. Check that comparison mode is set in DashboardState

### Incorrect Percentage Change

1. Verify ClickHouse query is returning correct values
2. Check aggregate calculation for rounding issues
3. Verify bounce_rate has inverted coloring logic

### Date Range Validation Errors

1. Check that compare_from < compare_to
2. Verify ranges don't overlap with main period
3. Ensure dates are in valid ISO format
