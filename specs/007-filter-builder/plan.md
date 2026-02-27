# Implementation Plan: Advanced Filter Builder for Visitor Segments

**Branch**: `007-filter-builder` | **Date**: 2026-02-27 | **Spec**: [link](./spec.md)
**Input**: Feature specification from `/specs/007-filter-builder/spec.md`

## Summary

Create a UI component enabling marketing analysts to build custom visitor segments by combining multiple filter conditions with AND/OR logic and nested groupings. The component allows users to select visitor fields, apply operators, combine conditions, save templates, and preview matching visitor counts in real-time.

## Technical Context

**Language/Version**: Elixir 1.15+ (backend), TypeScript 5.x (frontend)
**Primary Dependencies**: Phoenix Framework, React 18, TailwindCSS, ClickHouse (analytics queries)
**Storage**: PostgreSQL (templates, user preferences), ClickHouse (visitor data, filter evaluation)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (analytics dashboard)
**Project Type**: web-service + frontend
**Performance Goals**: Real-time preview updates within 2 seconds; filter evaluation on ClickHouse
**Constraints**: Privacy-first (no personal data collection); GDPR/CCPA/PECR compliant
**Scale/Scope**: Multi-tenant analytics platform with per-site visitor segments

### Technical Unknowns (NEEDS CLARIFICATION)

| Unknown | Impact | Question |
|---------|--------|----------|
| Available visitor fields | Core feature | What visitor attributes are available for filtering in ClickHouse? |
| Filter evaluation API | Implementation | Does an existing API endpoint exist to evaluate filters against visitor data, or need new endpoint? |
| Template schema | Data model | Where are filter templates stored (PostgreSQL) and what is the schema? |
| Nested group UI depth | UX constraint | What is the maximum nesting depth supported in similar features? |

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate Evaluation

| Principle | Status | Notes |
|----------|--------|-------|
| I. Privacy-First | ✅ PASS | Filter builder operates on aggregated analytics data; no personal data collection |
| II. Test-Driven | ⚠️ NOTE | Must write tests before implementation per constitution |
| III. Performance | ✅ PASS | Real-time preview requires efficient ClickHouse queries |
| IV. Observability | ✅ PASS | Need structured logging for filter operations |
| V. Simplicity | ✅ PASS | Start with simple UI, add nesting as needed |

**Gate Result**: ✅ PASS - All gates satisfied. Note: Must ensure TDD approach in implementation phase.

## Project Structure

### Documentation (this feature)

```
specs/007-filter-builder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (if needed)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/plausible/
├── web/
│   ├── controllers/     # API controllers for filter operations
│   ├── contexts/       # Business logic for filters
│   └── schemas/        # Ecto schemas for templates
priv/repo/migrations/   # Database migrations

assets/
├── js/
│   ├── components/     # React components for filter builder
│   ├── lib/           # Utilities for filter operations
│   └── hooks/         # React hooks for filter state
test/
├── plausible/
│   └── filters/       # Tests for filter logic
```

**Structure Decision**: Full-stack feature with React frontend and Phoenix backend. Filter builder is a new UI component in the analytics dashboard. Backend stores filter templates in PostgreSQL and evaluates filters against ClickHouse visitor data.

## Phase 0: Research Tasks

### Research: Available Visitor Fields

**Task**: Research what visitor fields are available in the existing ClickHouse schema for filtering.

**Context**: The filter builder needs to present a list of filterable fields. Need to understand:
- What visitor attributes are stored (country, device, source, etc.)
- Field types (string, number, date)
- Whether fields are queryable in real-time

### Research: Filter Evaluation Pattern

**Task**: Research existing patterns for evaluating filters against analytics data.

**Context**: Need to understand:
- How existing filters/funnels are evaluated in ClickHouse
- Whether there's a reusable query builder pattern
- Performance considerations for real-time preview

### Research: Template Storage Pattern

**Task**: Research existing template/persistence patterns in the codebase.

**Context**: Need to understand:
- How other user configurations are stored (site settings, goals, etc.)
- Ecto schema patterns used
- Migration conventions

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Nested filter groups | Required by User Story 4 | Flat AND/OR insufficient for real-world segmentation |
| Real-time preview | Required by User Story 6 | Post-only preview creates poor UX |

---

*Plan created by /speckit.plan - Phase 1 complete. Ready for /speckit.tasks.*
