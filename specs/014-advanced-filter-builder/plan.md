# Implementation Plan: Advanced Filter Builder

**Branch**: `014-advanced-filter-builder` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-advanced-filter-builder/spec.md`

## Summary

A UI component that allows users to combine multiple filter conditions using AND/OR logic for creating custom visitor segments. This builds on the existing Plausible Analytics segment system, adding a visual filter builder that supports nested condition groups, real-time preview counts, and template reuse.

## Technical Context

**Language/Version**: Elixir 1.18 (Phoenix), React 18.3 with TypeScript
**Primary Dependencies**: Phoenix framework, React with TanStack Query, TailwindCSS, Headless UI
**Storage**: PostgreSQL (segments table), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (analytics dashboard)
**Performance Goals**: Filter preview updates within 2 seconds for up to 1M visitors
**Constraints**: Maximum 20 conditions per segment, 3 levels of nesting depth
**Scale/Scope**: Multi-tenant SaaS analytics platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Privacy-First Development
- [PASS] Feature maintains privacy-first principles - no new personal data collection
- [PASS] Filters operate on existing visitor attributes only (country, device, behavior)
- [PASS] No PII exposure in filter builder UI

### Test-Driven Development (NON-NEGOTIABLE)
- [PASS] Plan includes testing requirements for all components
- [PASS] Backend tests for filter parsing/validation via ExUnit
- [PASS] Frontend tests for component rendering and state via Jest
- [PASS] Integration tests for API contracts

### Performance as a Feature
- [PASS] Filter preview updates must be < 2 seconds (SC-004)
- [PASS] Support for 20+ simultaneous conditions (SC-006)
- [PASS] Caching strategy for filter suggestions included

### Observability and Debuggability
- [PASS] Structured logging for filter operations
- [PASS] Error tracking with context for invalid filter configurations
- [PASS] Metrics for filter query performance

### Simplicity and YAGNI
- [PASS] Start with visual AND/OR builder only
- [PASS] Reuse existing segment storage schema
- [PASS] No premature abstraction for templates

## Project Structure

### Documentation (this feature)

```text
specs/014-advanced-filter-builder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
lib/
├── plausible/
│   ├── segments/
│   │   ├── segment.ex         # Existing segment schema
│   │   ├── filters.ex         # Existing filter resolution
│   │   └── segments.ex        # Existing segment context
│   └── stats/
│       ├── filters/           # Existing filter parsing
│       ├── aggregate.ex       # For preview counts
│       └── query_builder.ex   # For building queries

# Frontend - React/TypeScript
assets/
├── js/
│   ├── components/
│   │   └── FilterBuilder/     # NEW: Filter builder component
│   │       ├── FilterBuilder.tsx
│   │       ├── ConditionRow.tsx
│   │       ├── ConditionGroup.tsx
│   │       ├── FilterPreview.tsx
│   │       └── index.ts
│   ├── lib/
│   │   └── filter-parser.ts   # NEW: Parse/serialize filters
│   └── hooks/
│       └── useFilterBuilder.ts # NEW: State management

# Tests
test/
├── plausible/segments/         # Existing segment tests
└── plausible_web/             # Existing API/controller tests

assets/
├── js/
│   └── components/
│       └── __tests__/         # Component tests
```

**Structure Decision**: Feature follows existing Plausible patterns - backend extends segments context, frontend adds new FilterBuilder component using React hooks for state management.

## Phase 0: Outline & Research

### Research Tasks

Based on Technical Context analysis, the following research is needed:

1. **Filter Parser for AND/OR/Nested Groups**: Research existing filter grammar in the codebase and determine how to extend for nested groups
   - Existing filters use list-based syntax: `[:is, "visit:country", ["US"]]`
   - Need to support nested group structure with AND/OR connectors

2. **UI Component Patterns**: Research existing modal/popover patterns in the frontend for the filter builder interface
   - Check existing components in `assets/js/components/`
   - Determine if Headless UI Dialog or Popover is appropriate

3. **Filter Suggestions API**: Research existing filter suggestions endpoint to integrate autocomplete
   - Check `lib/plausible/stats/filter_suggestions.ex`
   - Determine API contract for fetching available fields and values

### Expected Outcomes

- Filter grammar extension for nested groups
- Component architecture for visual filter builder
- Integration points with existing filter suggestions

---

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion*

### Privacy-First Development
- [PASS] Feature maintains privacy-first principles - no new personal data collection
- [PASS] Filters operate on existing visitor attributes only (country, device, behavior)
- [PASS] No PII exposure in filter builder UI
- [PASS] Uses existing segment storage (no new data collection)

### Test-Driven Development (NON-NEGOTIABLE)
- [PASS] Backend tests for filter parsing/validation via ExUnit (reuse existing test patterns)
- [PASS] Frontend tests for component rendering and state via Jest
- [PASS] Integration tests for full segment creation flow

### Performance as a Feature
- [PASS] Filter preview uses existing stats query infrastructure
- [PASS] Supports up to 1M visitors per SC-004
- [PASS] Maximum 20 conditions constraint ensures scalability

### Observability and Debuggability
- [PASS] Filter parsing errors tracked via existing QueryError mechanism
- [PASS] Invalid filter configurations return structured error messages
- [PASS] Uses existing logging/metrics infrastructure

### Simplicity and YAGNI
- [PASS] Reuses existing segment schema (no new storage)
- [PASS] UI builds on existing modal/filter component patterns
- [PASS] No new APIs required (uses existing endpoints)

---

## Generated Artifacts

| Artifact | Status |
|----------|--------|
| research.md | Complete |
| data-model.md | Complete |
| contracts/filter-builder-state.md | Complete |
| quickstart.md | Complete |
| CLAUDE.md | Updated |
