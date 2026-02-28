# Implementation Plan: Time Period Comparison

**Branch**: `017-time-period-comparison` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature enables users to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display. After researching the codebase, we discovered that this functionality is **already substantially implemented**:

- Backend comparison logic exists in `lib/plausible/stats/comparisons.ex`
- Percentage change calculation exists in `lib/plausible/stats/compare.ex`
- Frontend comparison period selection UI exists in `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`
- Metrics display with comparison values exists in `assets/js/dashboard/stats/graph/top-stats.js`

The implementation already supports:
- Previous period comparison
- Year-over-year comparison
- Custom date range comparison
- Percentage change calculation and display
- Visual indicators for increase/decrease

This plan identifies any gaps between the spec requirements and existing implementation.

## Technical Context

**Language/Version**: Elixir 1.15+, Phoenix, React 18, TypeScript
**Primary Dependencies**: Phoenix (backend), React (frontend), TailwindCSS, ClickHouse (analytics queries), PostgreSQL (metadata)
**Storage**: PostgreSQL (transactional), ClickHouse (analytics/time-series data)
**Testing**: ExUnit (Elixir), Jest (JavaScript), Playwright (e2e)
**Target Platform**: Web application (browser)
**Project Type**: Web service / Analytics dashboard
**Performance Goals**: Real-time analytics queries with sub-second response times
**Constraints**: Privacy-first analytics (no cookies, GDPR compliant)
**Scale/Scope**: Multi-tenant SaaS serving thousands of sites

## Constitution Check

*Initial Gate Check - Feb 27, 2026*

### Privacy-First Development
- **APPLIES**: This feature processes user data (analytics metrics)
- **Required**: Privacy impact assessment - Feature processes aggregate metrics only, no personal data
- **Status**: PASS - Uses aggregate analytics data, no PII

### Test-Driven Development (NON-NEGOTIABLE)
- **Required**: Tests written before implementation
- **Status**: CHECK - Existing code has tests; new additions require tests

### Performance as a Feature
- **Required**: Query optimization, caching strategies
- **Status**: PASS - Existing comparison queries use optimized ClickHouse queries

### Observability and Debuggability
- **Required**: Structured logging, metrics
- **Status**: PASS - Existing logging infrastructure in place

### Simplicity and YAGNI
- **Required**: Avoid over-engineering
- **Status**: PASS - Feature is already implemented with minimal complexity

## Project Structure

### Documentation (this feature)

```
specs/017-time-period-comparison/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (existing implementation analysis)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - internal feature)
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

This is a Phoenix web application with a React/TypeScript frontend:

```
lib/plausible/
├── stats/
│   ├── comparisons.ex       # EXISTING - Comparison period logic
│   ├── compare.ex           # EXISTING - Percentage change calculation
│   ├── query.ex             # Query struct definition
│   └── datetime_range.ex    # Date range handling
└── ...

assets/js/dashboard/
├── nav-menu/query-periods/
│   ├── comparison-period-menu.tsx  # EXISTING - Comparison UI
│   ├── dashboard-period-picker.tsx  # Period selection
│   └── dashboard-time-periods.ts    # Time period logic
├── stats/graph/
│   ├── top-stats.js        # EXISTING - Metrics display with comparison
│   └── change-arrow.tsx    # EXISTING - Change indicator component
└── ...

test/plausible/stats/
├── comparisons_test.exs     # EXISTING - Backend tests
└── compare_test.exs        # EXISTING - Percentage change tests
```

**Structure Decision**: Web application (Phoenix + React). The time period comparison feature is a backend query enhancement with frontend display components. Both existing backend and frontend code follow the project's conventions.

## Phase 0: Research Findings

### Existing Implementation Analysis

The time period comparison feature is **already implemented** in the codebase:

| Component | Location | Status |
|-----------|----------|--------|
| Comparison logic | `lib/plausible/stats/comparisons.ex` | IMPLEMENTED |
| Percentage calculation | `lib/plausible/stats/compare.ex` | IMPLEMENTED |
| Period presets | `assets/js/dashboard/dashboard-time-periods.ts` | IMPLEMENTED |
| Comparison UI | `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | IMPLEMENTED |
| Metrics display | `assets/js/dashboard/stats/graph/top-stats.js` | IMPLEMENTED |

### Comparison Modes Supported

1. **Previous Period** - Shifts back by same number of days (e.g., this week vs last week)
2. **Year over Year** - Shifts back by 1 year (e.g., this month vs same month last year)
3. **Custom Date Range** - User selects specific comparison dates

### Gaps Identified

Comparing existing implementation to spec requirements:

| Spec Requirement | Current Status | Gap |
|-----------------|----------------|-----|
| FR-001: Select current date range | IMPLEMENTED | None |
| FR-002: Select comparison date range | IMPLEMENTED | None |
| FR-003: Display metrics for both periods | IMPLEMENTED | None |
| FR-004: Calculate percentage change | IMPLEMENTED | None |
| FR-005: Display direction indicators | IMPLEMENTED | None |
| FR-006: Preset options | IMPLEMENTED | Presets exist but verify all required ones |
| FR-007: Customize after preset | IMPLEMENTED | None |
| FR-008: Handle zero comparison value | IMPLEMENTED | Returns 100% change |
| FR-009: Compare multiple metrics | IMPLEMENTED | None |
| FR-010: Enable/disable comparison | IMPLEMENTED | None |

**Conclusion**: Feature appears fully implemented. Next step is verification/testing against spec requirements.

## Phase 1: Design

Since the feature is already implemented, Phase 1 focuses on documenting the existing data model and verifying completeness.

### Data Model

See [data-model.md](data-model.md) for entity definitions:
- DateRange
- MetricValue
- PercentageChange
- ComparisonConfiguration

### Contracts

Not applicable - this is an internal feature with no external API contracts.

### Quickstart

See [quickstart.md](quickstart.md) for developer onboarding.

## Complexity Tracking

No complexity violations identified. Feature is already implemented with appropriate simplicity.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Next Steps

1. **Verify existing implementation** against spec requirements
2. **Run existing tests** to ensure functionality works as expected
3. **Add any missing tests** for edge cases
4. **Document any gaps** and create tasks for fixes
