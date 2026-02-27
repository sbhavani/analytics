# Implementation Plan: Advanced Filter Builder

**Branch**: `011-advanced-filter-builder` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-advanced-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Create an advanced filter builder UI component that enables users to combine multiple filter conditions (AND/OR logic) for custom visitor segments in Plausible Analytics. The feature includes a visual interface for building complex filter trees, saving/loading segments, and real-time preview of matching visitors.

## Technical Context

**Language/Version**: Elixir 1.15+, TypeScript 5.x
**Primary Dependencies**: Phoenix 1.7+, React 18+, TailwindCSS 3.x
**Storage**: PostgreSQL (segments metadata), ClickHouse (visitor query data)
**Testing**: ExUnit for Elixir, Jest for JavaScript
**Target Platform**: Linux server (backend), Modern browsers (frontend)
**Project Type**: Web application (analytics dashboard)
**Performance Goals**: Preview results within 2 seconds for <10k visitors
**Constraints**: Maximum 5 nesting levels, 10 conditions per group
**Scale/Scope**: Supports multiple sites per user, typical segment size <100 conditions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First (I) | PASS | Filter builder only processes visitor data users already have access to |
| Test-Driven (II) | PASS | Tests required - ExUnit for backend, Jest for frontend |
| Performance (III) | PASS | 2s preview requirement aligns with constitution |
| Observability (IV) | PASS | Structured logging for filter operations |
| Simplicity (V) | PASS | Start with basic AND/OR, add nesting as P2 |
| Elixir/Phoenix | PASS | Backend follows Phoenix conventions |
| React/TypeScript | PASS | Frontend uses React + TypeScript + TailwindCSS |
| Quality Gates | PASS | All tests, Credo, ESLint, TypeScript must pass |

## Project Structure

### Documentation (this feature)

```text
specs/011-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

Based on Plausible Analytics structure:

```text
lib/
├── plausible/
│   ├── repo.ex
│   ├── application.ex
│   └── ...
├── plausible_web/
│   ├── router.ex
│   ├── controllers/
│   ├── views/
│   └── components/        # For new filter builder components
└── ...

assets/
├── js/
│   ├── components/        # React components for filter builder
│   ├── lib/               # Utility functions
│   └── hooks/             # React hooks for state management
└── css/
    └── app.css

test/
├── plausible/            # Backend tests
│   └── ...
└── plausible_web/        # Controller/integration tests
    └── ...
```

**Structure Decision**: Plausible Analytics uses Phoenix + React. New filter builder will add React components in `assets/js/components/` and Phoenix components/controllers in `lib/plausible_web/`. Backend business logic in `lib/plausible/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
