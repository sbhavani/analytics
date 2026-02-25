# Implementation Plan: Advanced Filter Builder

**Branch**: `001-filter-builder` | **Date**: 2026-02-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature adds a visual filter builder UI component that enables users to create custom visitor segments by combining multiple filter conditions with AND/OR logic. The implementation leverages the existing Plausible Analytics stack (Elixir/Phoenix backend, React/TypeScript frontend) to provide a seamless experience for creating, saving, and managing visitor segments.

## Technical Context

**Language/Version**: Elixir 1.15+ (Phoenix 1.7+), TypeScript 5.x
**Primary Dependencies**: Phoenix (web framework), React 18, Ecto (database), TailwindCSS
**Storage**: PostgreSQL (segment metadata), ClickHouse (analytics data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (browser-based)
**Project Type**: Web application (analytics dashboard)
**Performance Goals**: Filter preview updates <2 seconds (SC-004), supports 20+ conditions (SC-006)
**Constraints**: Privacy-first (no personal data), responsive UI, real-time preview
**Scale/Scope**: Multi-tenant SaaS analytics with thousands of sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| **II. Test-Driven Development** | APPLY | Tests must be written before implementation. Unit tests for filter logic, integration tests for segment storage. |
| **III. Performance as a Feature** | APPLY | Filter preview must update within 2 seconds. Must support 20+ conditions without degradation. |
| **IV. Observability and Debuggability** | APPLY | Structured logging for segment creation/updates/deletions. Error tracking with context. |
| **I. Privacy-First Development** | PASS | Feature filters existing analytics data, does not collect new personal data. No privacy impact. |

**Privacy Gate Justification**: This feature creates UI for filtering existing visitor properties (country, device, browser, etc.) which are already collected for analytics purposes. No new data collection occurs. Privacy impact assessment not required per constitution exception for features that filter existing data.

## Project Structure

### Documentation (this feature)

```text
specs/001-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
lib/
├── plausible/
│   ├── segments/              # New: Segment business logic
│   │   └──.ex                # Segment   └── repo.ex query builder
│               # Existing: Ecto repository
└── plausible_web/
    ├── controllers/           # Existing: API endpoints
    ├── components/            # Existing: Phoenix components
    └── live/                  # Existing: LiveView views

# Frontend - React/TypeScript
assets/js/
├── components/               # Existing: React components
│   └── filter-builder/       # New: Filter builder component
└── lib/                      # Existing: Utilities

# Tests
test/
├── plausible/               # Existing: Elixir tests
│   └── segments_test.exs   # New: Segment tests
└── support/                 # Existing: Test utilities

assets/test-utils/           # Existing: JavaScript test utilities
```

**Structure Decision**: Feature follows existing Plausible Analytics project structure:
- Backend: Phoenix contexts in `lib/plausible/` for business logic, controllers in `lib/plausible_web/`
- Frontend: React components in `assets/js/components/`
- Tests: ExUnit in `test/plausible/`, Jest tests alongside components

No additional project separation required - single codebase with clear module boundaries.
