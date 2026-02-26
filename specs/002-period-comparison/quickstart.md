# Developer Quickstart: Time Period Comparison Feature

## Overview

This feature adds period comparison functionality to the analytics dashboard, allowing users to compare metrics between two date ranges with percentage change display.

**Status**: The period comparison feature is already implemented in the codebase.

## Architecture

- **Backend**: Phoenix context for period calculations
- **Frontend**: JavaScript/TypeScript components for period picker and comparison display
- **Storage**: ClickHouse for analytics data retrieval

## Existing Implementation

### Backend Modules

| Module | Location | Description |
|--------|----------|-------------|
| `Plausible.Stats.Compare` | `lib/plausible/stats/compare.ex` | Percentage change calculation |
| `Plausible.Stats.Comparisons` | `lib/plausible/stats/comparisons.ex` | Period comparison logic (previous period, year-over-year, custom) |
| `Plausible.Stats.Query` | `lib/plausible/stats/query.ex` | Date range validation and handling |

### Frontend Components

| Component | Location | Description |
|-----------|----------|-------------|
| `ChangeArrow` | `assets/js/dashboard/stats/reports/change-arrow.tsx` | Color-coded percentage indicator (green/red) |
| `MetricValue` | `assets/js/dashboard/stats/reports/metric-value.tsx` | Metrics display with comparison tooltips |
| `dashboard-time-periods.ts` | `assets/js/dashboard/dashboard-time-periods.ts` | Period selection with comparison modes |

### Comparison Modes

The system supports three comparison modes (defined in `dashboard-time-periods.ts`):

1. **Previous Period** (`previous_period`) - Compares with the same period immediately before
2. **Year over Year** (`year_over_year`) - Compares with the same period from the previous year
3. **Custom Period** (`custom`) - User-defined comparison period

### API Integration

The frontend connects to existing API endpoints that already support period comparisons. The `ComparisonMode` enum in `dashboard-time-periods.ts` defines:
- `ComparisonMode.off` - No comparison
- `ComparisonMode.previous_period` - Previous period comparison
- `ComparisonMode.year_over_year` - Year-over-year comparison
- `ComparisonMode.custom` - Custom date range comparison

### Edge Case Handling

| Scenario | Implementation |
|----------|----------------|
| Division by zero | Returns 100 (from `compare.ex:29`) |
| Both values zero | Returns 0 (from `compare.ex:32`) |
| No data in period | Returns null (from `compare.ex:20-21`) |
| Bounce rate metric | Special handling in `compare.ex:12-14` |
| Conversion rate metric | Special handling in `compare.ex:2-4` |

## Testing

Run tests with:

```bash
# Elixir tests
mix test test/plausible/stats/

# JavaScript tests
cd assets && npm test
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Query performance | Use ClickHouse query optimization; add caching for frequently compared periods |
| Date timezone | Use UTC for all calculations, display in user's timezone |
| No data in period | Display "No data available" instead of percentage |

## Key Files

- `lib/plausible/stats/compare.ex` - Core percentage change calculation
- `lib/plausible/stats/comparisons.ex` - Period comparison logic
- `lib/plausible/stats/datetime_range.ex` - Date range handling
- `assets/js/dashboard/dashboard-time-periods.ts` - Period selection UI
- `assets/js/dashboard/stats/reports/change-arrow.tsx` - Visual percentage indicator
- `assets/js/dashboard/stats/reports/metric-value.tsx` - Metrics with comparison display
