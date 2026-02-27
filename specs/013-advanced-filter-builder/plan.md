# Implementation Plan: Advanced Filter Builder

**Branch**: `013-advanced-filter-builder` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-advanced-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Extend the current flat filter system to support nested filter groups with AND/OR logic for custom visitor segments. The feature adds a visual filter builder UI component that allows users to create complex boolean filter expressions like "(Country = US AND Device = Mobile) OR (Country = UK AND Device = Desktop)".

## Technical Context

**Language/Version**: Elixir 1.16+, TypeScript 5.x
**Primary Dependencies**: Phoenix (Elixir), React 18, ClickHouse (analytics queries)
**Storage**: PostgreSQL (segments), existing ClickHouse (analytics data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web dashboard (responsive)
**Project Type**: Web application with analytics backend
**Performance Goals**: Filter application <2s for 10+ conditions, saved segment retrieval <3s
**Constraints**: Maximum 2 levels of nesting depth, 10+ conditions per group support
**Scale/Scope**: Multi-tenant SaaS analytics platform, 10k+ sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **TDD Required**: All new features require tests before implementation
- [x] **Privacy-First**: Filter data contains no personal information (filtering on analytics properties only)
- [x] **Performance**: Query optimization considered for nested filter evaluation
- [x] **Simplicity**: Nested structure extends existing flat model (no separate tables needed)
- [x] **Observability**: Structured logging for filter operations, error tracking for invalid configurations

## Project Structure

### Documentation (this feature)

```
specs/013-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
# Backend - Elixir/Phoenix
lib/
├── plausible/
│   ├── stats/
│   │   ├── filters/
│   │   │   └── filter_parser.ex       # NEW: Parse nested filter structures
│   │   └── query_builder.ex           # MODIFIED: Handle nested AND/OR groups
│   └── segments/
│       ├── segment.ex                  # MODIFIED: Validate nested filter data
│       └── segments.ex                 # MODIFIED: CRUD operations

# Frontend - React/TypeScript
assets/js/
└── dashboard/
    ├── filtering/
    │   ├── filter-builder/             # NEW: Advanced filter builder components
    │   │   ├── filter-group.tsx
    │   │   ├── filter-condition.tsx
    │   │   ├── filter-connector.tsx
    │   │   └── index.tsx
    │   ├── segments-context.tsx       # MODIFIED: Handle nested filter serialization
    │   └── segments.ts                 # MODIFIED: Segment data parsing
    └── components/
        └── modals/
            └── filter-modal.tsx        # MODIFIED: Support group operations
```

**Structure Decision**: Feature follows existing Plausible project structure:
- Backend: Elixir contexts in `lib/plausible/` following Phoenix conventions
- Frontend: React components in `assets/js/dashboard/` with co-located tests
- Shared: TypeScript types in `assets/js/types/`

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Nested filter structure | Required by feature spec (FR-004) for complex boolean logic | Flat structure insufficient for OR logic within AND groups |

## Phase 1: Design & Contracts

### Output Artifacts Required

- [ ] `data-model.md` - Entity definitions for filter groups, conditions, and segments
- [ ] `contracts/` - API contracts for filter operations (if needed)
- [ ] `quickstart.md` - Developer setup guide for the feature

### Next Steps

Proceed to generate Phase 1 artifacts using the research findings and existing system patterns.
