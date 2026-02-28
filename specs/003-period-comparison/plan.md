# Implementation Plan: Time Period Comparison

**Branch**: `003-period-comparison` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-period-comparison/spec.md`

## Summary

The Time Period Comparison feature is **already implemented** in the codebase. This implementation plan documents the existing architecture and verifies alignment with the specification. The feature enables users to compare analytics metrics between two date ranges (e.g., this week vs last week) with percentage change display.

**Technical Approach**: The existing implementation uses:
- Backend: Elixir/Phoenix with `Plausible.Stats.Comparisons` module for date range calculation
- Frontend: React with TypeScript, comparing mode selection in `comparison-period-menu.tsx`
- Percentage calculations: `Plausible.Stats.Compare` module with handlers for various metric types

## Technical Context

**Language/Version**: Elixir 1.15+, React 18+, TypeScript 5.x
**Primary Dependencies**: Phoenix Framework, React, TailwindCSS, Day.js
**Storage**: PostgreSQL (transactions), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web analytics dashboard (browser)
**Project Type**: Web analytics SaaS platform
**Performance Goals**: Real-time analytics queries, sub-second page loads
**Constraints**: GDPR/CCPA compliance, privacy-first approach

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| II. Test-Driven Development | PASS | ExUnit tests exist for comparison logic in `test/plausible/stats/comparisons_test.exs` |
| III. Performance as a Feature | PASS | Query optimization built into comparison logic |
| V. Simplicity and YAGNI | PASS | Uses existing query infrastructure, no unnecessary abstractions |

**Constitution Alignment**: The implementation follows all core principles:
- Privacy: No personal data collected, analytics-only
- Performance: Efficient query construction using existing infrastructure
- Observability: Structured logging via Logger
- Simplicity: Leverages existing `Query` struct and date handling

## Project Structure

### Documentation (this feature)

```text
specs/003-period-comparison/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Not needed - feature already implemented
├── data-model.md        # Not needed - uses existing data models
├── quickstart.md        # Not needed - feature already implemented
├── contracts/           # Not needed - internal feature
└── checklists/          # Requirements validation
```

### Source Code (repository root)

```text
lib/plausible/stats/
├── comparisons.ex       # Core comparison logic (period calculation)
├── compare.ex           # Percentage change calculations
├── query.ex             # Query struct definition
└── query_builder.ex     # Query construction

assets/js/dashboard/
├── nav-menu/query-periods/
│   ├── comparison-period-menu.tsx    # Comparison mode UI
│   └── dashboard-period-picker.tsx  # Date range picker
├── stats/reports/
│   ├── metric-value.tsx              # Displays comparison values
│   └── change-arrow.tsx              # Directional indicators
├── dashboard-state-context.tsx       # State management
└── dashboard-time-periods.ts         # Time period utilities

test/plausible/stats/
└── comparisons_test.exs               # Backend tests
```

**Structure Decision**: The feature uses the existing Phoenix MVC architecture with:
- Backend logic in `lib/plausible/stats/` (context layer)
- Frontend React components in `assets/js/dashboard/`
- State management via React Context (DashboardStateContext)
- URL-based session persistence (query parameters)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Not applicable - feature already implemented with no violations.

---

## Phase 0: Research

**Status**: COMPLETE - Feature already implemented

The existing implementation matches all specification requirements:

| Spec Requirement | Implementation |
|-----------------|----------------|
| FR-001: Comparison mode selection | `ComparisonMode` enum in `dashboard-time-periods.ts` with `off`, `previous_period`, `year_over_year`, `custom` |
| FR-002: Auto-calculate previous period | `Comparisons.get_comparison_utc_time_range/1` calculates period based on source query |
| FR-003: Display percentage change | `Compare.percent_change/2` calculates change; `ChangeArrow` component displays |
| FR-004: Color-coded indicators | Green (positive) / Red (negative) in `change-arrow.tsx` |
| FR-005: Custom date ranges | `{:date_range, from, to}` mode in comparisons.ex |
| FR-006: Session persistence | URL search params via `dashboard-state.ts` |
| FR-007: Display both values | `MetricValue` component shows current + comparison in tooltip |
| FR-008: Handle missing data | `percent_change/2` returns `nil` for missing values |
| FR-009: Support all period types | Day, week, month, custom ranges supported in comparisons.ex |

## Phase 1: Design & Contracts

**Status**: COMPLETE - Feature already designed and implemented

### Existing Data Models

The implementation uses existing data structures:

1. **Query** - Contains `utc_time_range`, `include.compare`, `include.compare_match_day_of_week`
2. **DateTimeRange** - Elixir native for date ranges
3. **ComparisonMode** - TypeScript enum: `off | previous_period | year_over_year | custom`
4. **MetricValues** - Record mapping metrics to values with comparison metadata

### Interface Contracts

Internal feature - no external contracts needed. The UI exposes:
- Comparison mode selector in date picker dropdown
- Metric cards with change indicators
- Tooltip showing both period values

---

## Verification: Specification Alignment

Checking implementation against spec.md:

| Spec Item | Status |
|-----------|--------|
| User Story 1 (Previous period) | IMPLEMENTED |
| User Story 2 (Year-over-year) | IMPLEMENTED |
| User Story 3 (Custom range) | IMPLEMENTED |
| Edge Case: No data | HANDLED (returns nil) |
| Edge Case: Zero values | HANDLED (returns 100% or 0%) |
| Edge Case: Timezone | HANDLED (UTC conversion) |
| Success Criteria SC-001 | IMPLEMENTED (2-click enable) |
| Success Criteria SC-002 | IMPLEMENTED |
| Success Criteria SC-003 | IMPLEMENTED (URL persistence) |
| Success Criteria SC-004 | IMPLEMENTED |
| Success Criteria SC-004 | IMPLEMENTED |

**Conclusion**: The Time Period Comparison feature is **fully implemented** and aligns with the specification. No additional work is required unless specific enhancements are identified.
