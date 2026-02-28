# Implementation Plan: Advanced Filter Builder

**Branch**: `016-advanced-filter-builder` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-advanced-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The Advanced Filter Builder is a React UI component enabling users to create complex filter conditions with AND/OR logic for custom visitor segments. Building on the existing segment infrastructure, this feature adds a visual filter builder that supports nested groups, real-time preview, and persistent saved segments.

## Technical Context

**Language/Version**: TypeScript (React), Elixir/Phoenix backend
**Primary Dependencies**: React 18+, @headlessui/react, @heroicons/react, @tanstack/react-query, TailwindCSS
**Storage**: PostgreSQL (segments metadata), ClickHouse (analytics queries)
**Testing**: Jest for JavaScript, ExUnit for Elixir
**Target Platform**: Web browser (responsive)
**Project Type**: Web analytics application
**Performance Goals**: Filter preview in <3s, handle 20+ conditions without UI degradation
**Constraints**: Must work with existing filter API schema, maintain backward compatibility with saved segments
**Scale/Scope**: Enterprise-ready, supports 50+ saved segments per site

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | Filters operate on aggregate analytics data only; no PII collected |
| Test-Driven Development | PASS | Jest tests required for UI components; ExUnit tests for backend API |
| Performance as Feature | PASS | Preview queries optimized; lazy evaluation for complex filters |
| Observability | PASS | Add analytics events for filter builder usage |
| Simplicity and YAGNI | PASS | Start with visual builder; nested groups only if needed |

## Project Structure

### Documentation (this feature)

```text
specs/016-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# React Frontend (existing)
assets/js/dashboard/
├── components/
│   └── filter-builder/      # NEW: Advanced filter builder components
├── contexts/
│   └── filter-builder-context.tsx  # NEW: State management
├── util/
│   └── filter-tree.ts        # NEW: Filter tree manipulation utilities
├── segments/
│   └── [existing segment code]
└── [existing dashboard code]

# Elixir Backend (existing)
lib/plausible/
├── segments/                 # Existing segment logic
└── [existing analytics code]

test/
├── plausible_web/
│   └── [existing API tests]
└── [existing tests]
```

**Structure Decision**: The filter builder extends existing dashboard filtering. New code in `assets/js/dashboard/components/filter-builder/` with state management in React Context. Backend leverages existing segment storage APIs with possible extension for nested group support.

## Phase 0: Research

*No unknowns identified - spec is well-defined with clear requirements.*

The feature builds directly on existing:
- Segment storage and retrieval APIs (`/api/{site.domain}/segments`)
- Filter parsing utilities (`assets/js/dashboard/util/filters.js`)
- Dashboard state management (`dashboard-state.ts`)
- Filter modal components (`stats/modals/filter-modal.js`)

## Phase 1: Design Artifacts

### Generated Files

- **data-model.md**: Filter tree data structures and types
- **quickstart.md**: Developer onboarding for the feature
- **contracts/**: API contracts for segment save/load operations

---

*Plan completed. Ready for /speckit.tasks*
