# Implementation Plan: Advanced Filter Builder

**Branch**: `009-advanced-filter-builder` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-advanced-filter-builder/spec.md`

## Summary

Create a UI component for building advanced visitor filters with AND/OR logic and nested groups. The feature extends the existing Segment system with a visual filter builder that generates compatible filter payloads for the existing stats query API.

## Technical Context

**Language/Version**: Elixir 1.18+ (Phoenix), React 18+ with TypeScript
**Primary Dependencies**: Phoenix (backend), React, TailwindCSS, TanStack Query (frontend)
**Storage**: PostgreSQL (segments table), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (analytics dashboard)
**Performance Goals**: Real-time count updates within 2 seconds (SC-003), UI interactions under 500ms (SC-005)
**Constraints**: Maximum 3 nesting levels, 20 conditions per filter
**Scale/Scope**: Single-page UI component integrated into existing dashboard

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Phase 0 Gate Review

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy-First Development | PASS | Filter builder only queries aggregate visitor data; no new PII collection |
| Test-Driven Development | PASS | Will write tests before implementation per constitution |
| Performance as a Feature | PASS | Real-time updates within 2s target; UI under 500ms per success criteria |
| Observability | PASS | Will add structured logging for filter operations |
| Simplicity and YAGNI | PASS | Extends existing Segment system; no over-engineering |

### Phase 1 Re-check (Post-Design)

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy-First Development | PASS | No new data collection; only reads existing visitor attributes |
| Test-Driven Development | PASS | Implementation plan includes test tasks |
| Performance as a Feature | PASS | Debounced API calls; efficient filter query building |
| Observability | PASS | Will log segment create/update/delete operations |
| Simplicity and YAGNI | PASS | Reuses existing Segment schema; integrates with existing filter API |

## Project Structure

### Documentation (this feature)

```text
specs/009-advanced-filter-builder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (if applicable)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
lib/
├── plausible/
│   ├── segments/           # Existing segment functionality
│   │   └── segment.ex      # Segment schema (existing)
│   └── stats/
│       └── sql/
│           └── where_builder.ex  # Existing filter query builder
└── plausible_web/
    ├── controllers/
    │   └── api/
    │       └── stats_controller.ex  # Existing stats API
    └── views/

# Frontend - React/TypeScript
assets/
├── js/
│   ├── dashboard/
│   │   ├── components/     # Where filter builder will be added
│   │   └── util/
│   │       └── filters.ts  # Existing filter utilities
│   └── types/
└── css/

# Tests
test/
├── plausible/
│   └── segments/           # Segment tests
├── plausible_web/
│   └── controllers/
└── js/
    └── dashboard/
```

**Structure Decision**: Feature integrates into existing backend (`lib/plausible/segments/`) and frontend (`assets/js/dashboard/components/`). No new directories required - adding to existing component locations.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
