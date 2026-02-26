# Research: Time Period Comparison Feature

## Overview

This document captures research findings for implementing the Time Period Comparison feature in Plausible Analytics.

## Key Finding: Feature Already Exists

**Important Discovery**: The Time Period Comparison feature is already implemented in Plausible Analytics. The codebase already supports:

1. **Backend (Elixir)**: `lib/plausible/stats/comparisons.ex`
   - Previous period comparisons
   - Year-over-year comparisons
   - Custom date range comparisons
   - Match day of week option

2. **Frontend (React)**: `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`
   - UI for selecting comparison periods
   - Calendar for custom date ranges

3. **Metric Display**: `assets/js/dashboard/stats/reports/metric-value.tsx`
   - Percentage change display with arrows
   - Comparison tooltip with both period values

## Architecture Analysis

### Query Flow

1. User selects comparison mode via UI
2. Query params added to URL (`comparison`, `compare_from`, `compare_to`, `match_day_of_week`)
3. Backend `Comparisons` module generates comparison query
4. Both queries execute against ClickHouse
5. Results merged with percentage change calculated
6. Frontend displays with visual indicators

### Key Files

| File | Purpose |
|------|---------|
| `lib/plausible/stats/comparisons.ex` | Generates comparison date ranges |
| `lib/plausible/stats/query.ex` | Query struct with comparison options |
| `lib/plausible_web/controllers/api/stats_controller.ex` | API endpoint handling |
| `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Comparison UI |
| `assets/js/dashboard/stats/reports/metric-value.tsx` | Metric display with comparison |
| `assets/js/dashboard/dashboard-time-periods.ts` | Time period logic |

## Edge Case Handling (Research Findings)

### Zero Division
- When comparison value is 0, percentage change is undefined
- Current behavior: Shows "∞" or handles gracefully

### Missing Data
- Both periods checked for data availability
- Partial data handled - comparison still runs

### Different Period Lengths
- Match day of week option addresses this
- User can choose exact date match or day-of-week match

## Decision: Enhancement vs Bug Fix

Given the feature already exists, the implementation should focus on:

1. **Verification**: Ensure existing functionality works as specified
2. **Enhancement**: Add any missing preset options (quarterly comparisons)
3. **Testing**: Ensure edge cases are properly handled

## Alternatives Considered

| Alternative | Reason for Rejection |
|-------------|---------------------|
| Custom comparison engine | Already exists |
| Pre-calculated comparisons | Adds storage overhead |
| Client-side calculations | Less accurate, more bandwidth |

## Conclusion

The Time Period Comparison feature is already implemented. The spec should focus on validating existing functionality and identifying any gaps between current implementation and user requirements.
