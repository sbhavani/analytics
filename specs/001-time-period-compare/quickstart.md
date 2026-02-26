# Quickstart: Time Period Comparison Feature

## Overview

This feature enables comparing analytics metrics between two date ranges with percentage change display. The feature is **already implemented** in the codebase.

## Development Setup

### Prerequisites

- Elixir 1.15+
- Node.js 18+
- PostgreSQL (for application data)
- ClickHouse (for analytics data)
- Docker (for local development)

### Running the Application

```bash
# Start the Elixir/Phoenix backend
mix phx.server

# Start the frontend (separate terminal)
cd assets && npm run watch
```

### Running Tests

```bash
# Backend tests (ExUnit)
mix test

# Frontend tests (Jest)
cd assets && npm test
```

## Key Files

### Backend

| File | Purpose |
|------|---------|
| `lib/plausible/stats/comparisons.ex` | Comparison date range logic |
| `lib/plausible/stats/query.ex` | Query struct with comparison fields |
| `lib/plausible_web/controllers/api/stats_controller.ex` | API endpoint |

### Frontend

| File | Purpose |
|------|---------|
| `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Comparison UI |
| `assets/js/dashboard/stats/reports/metric-value.tsx` | Metric display with change |
| `assets/js/dashboard/dashboard-time-periods.ts` | Time period utilities |

## Testing the Feature

### Via UI

1. Navigate to any dashboard view
2. Click the comparison period selector
3. Choose a comparison mode (Previous Period, Year over Year, or Custom)
4. View metrics with percentage changes displayed

### Via API

```bash
# Previous period comparison
curl "http://localhost:8000/api/v1/stats/example.com/timeseries?period=day&comparison=previous_period"

# Year over year comparison
curl "http://localhost:8000/api/v1/stats/example.com/timeseries?period=day&comparison=year_over_year"

# Custom date range
curl "http://localhost:8000/api/v1/stats/example.com/timeseries?period=day&comparison=custom&compare_from=2024-01-01&compare_to=2024-01-07"
```

## Verification Checklist

- [ ] Comparison period selector visible in dashboard
- [ ] Previous period comparison shows correct dates
- [ ] Year-over-year comparison shows correct dates
- [ ] Custom date range picker works
- [ ] Percentage change displayed correctly (positive/negative)
- [ ] Zero value edge case handled
- [ ] Missing data handled gracefully
- [ ] Match day of week option works
