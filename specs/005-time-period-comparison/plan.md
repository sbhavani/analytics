# Implementation Plan: Time Period Comparison

**Branch**: `005-time-period-comparison` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-time-period-comparison/spec.md`

**Note**: This feature already exists in the codebase. This plan documents the current implementation.

## Summary

The time period comparison feature allows users to compare analytics metrics between two date ranges (source period and comparison period). It supports three comparison modes: previous_period (immediately preceding period of equal length), year_over_year (same period from previous year), and custom (user-selected date range). Percentage changes are displayed with directional arrows and appropriate color coding.

## Technical Context

**Language/Version**: Elixir 1.15+ / Phoenix 1.7+ (Backend), TypeScript 5.x / React 18.x (Frontend)
**Primary Dependencies**: Phoenix Framework, React, ClickHouse (analytics queries), PostgreSQL (transactional data)
**Storage**: ClickHouse for analytics data queries
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (web application)
**Project Type**: Web application / Analytics dashboard
**Performance Goals**: Query results displayed within 2 seconds
**Constraints**: Comparison disabled for "Realtime" and "All time" periods
**Scale/Scope**: Multi-tenant analytics platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Test-Driven Development (Principle II) | PASS | Existing implementation has tests in both Elixir and JavaScript |
| Performance as Feature (Principle III) | PASS | Comparison queries use optimized ClickHouse queries |
| Simplicity and YAGNI (Principle V) | PASS | Feature uses existing comparison module pattern |
| Privacy Impact | PASS | No new data collection; compares existing analytics data |

## Project Structure

### Documentation (this feature)

```text
specs/005-time-period-comparison/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # N/A - Feature already implemented
├── data-model.md        # N/A - Uses existing data models
├── quickstart.md        # N/A - No new implementation
├── contracts/           # N/A - Uses existing API contracts
└── tasks.md             # N/A - Feature already complete
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
lib/
├── plausible/stats/
│   ├── comparisons.ex        # Core comparison logic
│   ├── query.ex              # Query building
│   └── query_runner.ex       # Query execution
├── plausible_web/
│   └── controllers/          # API endpoints
test/
├── plausible/
│   └── stats/                # Tests for comparisons

# Frontend - React/TypeScript
assets/js/dashboard/
├── dashboard-time-periods.ts     # Period/comparison state management
├── stats/
│   ├── reports/
│   │   └── change-arrow.tsx      # Percentage change display
│   └── graph/
│       ├── top-stats.js           # Top stats with comparison
│       └── graph-tooltip.js       # Tooltip with comparison
└── nav-menu/query-periods/
    ├── dashboard-period-picker.tsx
    └── comparison-period-menu.tsx
assets/js/dashboard/test/          # Jest tests
```

**Structure Decision**: This is a web application with Phoenix backend and React frontend. The comparison feature spans both layers following existing patterns:
- Backend: `lib/plausible/stats/` for analytics logic
- Frontend: `assets/js/dashboard/` for UI components

## Complexity Tracking

> N/A - No violations. Feature uses existing patterns and infrastructure.

---

## Phase 0: Research

**Status**: COMPLETE (Feature already implemented)

The time period comparison feature was analyzed during specification. Key findings:

### Implementation Overview

| Component | Location | Status |
|-----------|----------|--------|
| Backend comparison logic | `lib/plausible/stats/comparisons.ex` | Implemented |
| Query integration | `lib/plausible/stats/query.ex` | Implemented |
| Frontend state | `assets/js/dashboard/dashboard-time-periods.ts` | Implemented |
| Percentage display | `assets/js/dashboard/stats/reports/change-arrow.tsx` | Implemented |
| Comparison menu UI | `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Implemented |
| Tests | Various `*_test.exs` and `.test.tsx` files | Implemented |

### Comparison Modes

1. **previous_period**: Shifts back the query by the same number of days as the source period
2. **year_over_year**: Shifts back the query by 1 year
3. **custom**: Uses user-selected date range via `{:date_range, from, to}`

### Day-of-Week Matching

Option to align comparison period by day of week rather than exact dates, useful for businesses with weekly patterns.

---

## Phase 1: Design & Contracts

**Status**: COMPLETE (Feature already implemented)

### Data Model

The feature uses existing data structures:

| Entity | Type | Description |
|--------|------|-------------|
| ComparisonMode | Enum | `off`, `previous_period`, `year_over_year`, `custom` |
| ComparisonMatchMode | Enum | `MatchExactDate`, `MatchDayOfWeek` |
| DateTimeRange | Struct | Represents source and comparison periods |

### API Contracts

The feature uses existing API contracts:
- Query parameters: `comparison`, `compare_from`, `compare_to`, `match_day_of_week`
- Response: Metrics include `comparison_value` alongside primary `value`

---

## Phase 2: Implementation

**Status**: NOT APPLICABLE - Feature already implemented

No new implementation tasks required. The feature is complete and functional.

### Verification Checklist

If verification is needed:

- [ ] Previous period comparison displays correctly
- [ ] Year-over-year comparison displays correctly
- [ ] Custom date range comparison works
- [ ] Day-of-week matching functions correctly
- [ ] Percentage change arrows display with correct colors
- [ ] Comparison preference persists in local storage
- [ ] Comparison disabled for Realtime and All time periods
