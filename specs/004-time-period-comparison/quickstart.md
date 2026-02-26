# Quickstart: Time Period Comparison

**Feature**: Time Period Comparison - Compare metrics between two date ranges with percentage change display

> **Note**: This feature is already implemented in the codebase. This document provides an overview for reference.

## Overview

Time Period Comparison allows users to compare analytics metrics between two date ranges. The comparison displays both absolute values and percentage change indicators.

## Usage

### Enabling Comparison

1. Navigate to any analytics dashboard view
2. Click on the comparison period selector (labeled with current comparison mode, e.g., "Compare to previous period")
3. Select a comparison mode:
   - **Previous Period**: Compare with the immediately preceding period of the same length
   - **Year over Year**: Compare with the same period from the previous year
   - **Custom**: Select specific dates using the calendar

### Viewing Comparison Results

- **Metric Cards**: Display the primary value with a change arrow indicator (↑ for increase, ↓ for decrease)
- **Tooltips**: Hover over any metric to see both the primary and comparison values with the percentage change
- **Main Graph**: Shows comparison data alongside primary data when enabled

### Custom Date Range

1. Select "Custom" from the comparison dropdown
2. A calendar appears for selecting the comparison date range
3. Select start and end dates
4. Click to apply

## Query Parameters

The comparison state is stored in URL parameters for sharing:

```
?period=month&comparison=previous_period
?period=7d&comparison=year_over_year
?period=custom&from=2024-01-01&to=2024-01-31&comparison=custom&compare_from=2023-01-01&compare_to=2023-01-31
```

## Technical Details

### Backend
- **Module**: `Plausible.Stats.Comparisons`
- **Query Parameter Parsing**: `Plausible.Stats.Query`
- **API Endpoints**: StatsController, API.StatsController

### Frontend
- **State Management**: Dashboard state context with URL synchronization
- **Components**:
  - `ComparisonPeriodMenu` - Dropdown selector
  - `DateRangeCalendar` - Custom date picker
  - `MetricValue` - Displays change indicators

## Testing

Run the comparison tests:
```bash
mix test test/plausible/stats/comparisons_test.exs
```

Run frontend tests:
```bash
npm test -- --testPathPattern="metric-value"
```

## Implementation Status

✅ Fully implemented - No additional work required
