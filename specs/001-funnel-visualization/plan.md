# Implementation Plan: Funnel Visualization

**Branch**: `001-funnel-visualization` | **Date**: 2026-02-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Summary

The funnel visualization feature already exists in the codebase as an Enterprise feature. The specification document describes functionality that is fully implemented:

- **Backend**: Elixir/Phoenix with PostgreSQL (metadata) and ClickHouse (analytics data)
- **Frontend**: React with TypeScript, Chart.js for visualization
- **Storage**: PostgreSQL for funnel definitions, ClickHouse for event data
- **Existing Implementation**: `/extra/lib/plausible/funnel*` (backend), `/assets/js/dashboard/extra/funnel.js` (frontend)

## Technical Context

**Language/Version**: Elixir 1.14+, JavaScript/TypeScript
**Primary Dependencies**: Phoenix, React, Chart.js, ClickHouse, Ecto
**Storage**: PostgreSQL (funnel definitions), ClickHouse (analytics events)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web analytics dashboard
**Project Type**: Web service with React frontend
**Performance Goals**: Real-time analytics queries
**Constraints**: Enterprise-only feature (requires paid plan)
**Scale/Scope**: Supports multiple sites with multiple funnels per site

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | No personal data collected, anonymized user IDs |
| Test-Driven Development | PASS | ExUnit tests exist for funnel modules |
| Performance as a Feature | PASS | Uses ClickHouse windowFunnel for efficient queries |
| Observability and Debuggability | PASS | Structured logging in place |
| Simplicity and YAGNI | PASS | Feature is appropriately scoped |

## Project Structure

### Documentation (this feature)

```text
specs/001-funnel-visualization/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Not needed - feature already implemented
├── data-model.md        # Not needed - feature already implemented
├── quickstart.md        # Not needed - feature already implemented
├── contracts/           # Not needed - internal feature
└── tasks.md            # Not needed - feature already implemented
```

### Source Code (repository root)

```text
# Backend - Enterprise features
extra/lib/plausible/
├── funnel.ex           # Funnel schema (2-8 steps)
├── funnel/step.ex      # Step schema
├── funnels.ex          # CRUD operations
└── stats/funnel.ex      # Analytics computation with ClickHouse

# Frontend - React dashboard
assets/js/dashboard/
├── extra/
│   ├── funnel.js       # Main visualization component
│   └── funnel-tooltip.js # Tooltip component
└── ...

# API Endpoints
lib/plausible_web/
├── controllers/
│   └── stats_controller.ex # /api/stats/:domain/funnels/:id
└── ...
```

**Structure Decision**: Feature already exists in production. No new code required - spec serves as documentation.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations - feature follows existing patterns.

## Phase 0: Research Summary

**Status**: NOT NEEDED

The feature already exists and is well-documented in the codebase. Key findings:

1. **Funnel Schema** (`/extra/lib/plausible/funnel.ex`):
   - Supports 2-8 steps per funnel
   - Each step references a Goal (custom event or pageview)
   - Stored in PostgreSQL

2. **Analytics** (`/extra/lib/plausible/stats/funnel.ex`):
   - Uses ClickHouse `windowFunnel` function
   - Calculates drop-off rates and conversion rates
   - Supports 24-hour window duration

3. **Visualization** (`/assets/js/dashboard/extra/funnel.js`):
   - React component with Chart.js
   - Shows visitors per step, drop-off counts, and percentages
   - Dark/light theme support
   - Mobile-responsive (bar chart on small screens)

## Phase 1: Design Summary

**Status**: NOT NEEDED

The feature is already designed and implemented. Key design decisions already made:

1. **Data Model**: Funnels → Steps → Goals → Events
2. **Query Strategy**: ClickHouse windowFunnel for sequential event matching
3. **UI Pattern**: Stacked bar chart with drop-off visualization
4. **API**: RESTful `/api/stats/:domain/funnels/:id`

## Conclusion

The funnel visualization feature described in the specification already exists in this codebase as a production-ready Enterprise feature. The spec.md document accurately describes the implemented functionality:

- ✅ View conversion funnel visualization
- ✅ Configure funnel steps (admin)
- ✅ Analyze drop-off insights
- ✅ Drop-off rate calculations
- ✅ Multiple funnel support
- ✅ Chart.js visualization with dark/light themes

No implementation work is required. This specification serves as documentation of the existing feature.
