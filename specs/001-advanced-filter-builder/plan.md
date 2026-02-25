# Implementation Plan: Advanced Filter Builder

**Branch**: `001-advanced-filter-builder` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-advanced-filter-builder/spec.md`

## Summary

Create an advanced filter builder UI component that allows users to combine multiple filter conditions using AND/OR logic for custom visitor segments in Plausible Analytics. This extends the existing single-level filter system to support nested filter groups with complex boolean logic.

## Technical Context

**Language/Version**: Elixir ~> 1.18, TypeScript
**Primary Dependencies**: Phoenix (backend), React + TypeScript (frontend), TailwindCSS, @tanstack/react-query
**Storage**: PostgreSQL (segments metadata), ClickHouse (analytics query data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (Plausible Analytics dashboard)
**Project Type**: Web application
**Performance Goals**: Filter preview updates within 2 seconds (SC-004), support 20 conditions / 5 nesting levels (SC-006)
**Constraints**: Must maintain privacy-first principles (no personal data collection), GDPR/CCPA/PECR compliance
**Scale/Scope**: User-facing feature for all authenticated users creating visitor segments

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Privacy-First Development

| Gate | Status | Notes |
|------|--------|-------|
| No personal data collection | ✅ PASS | Feature filters visitor attributes (country, device, source) - no PII involved |
| GDPR/CCPA/PECR compliant by design | ✅ PASS | Uses existing filter infrastructure that is already compliant |
| Privacy impact assessment needed | ⚠️ REVIEW | Existing segment system already assessed; new AND/OR logic adds no new privacy concerns |

**Assessment**: No new privacy concerns. The feature extends existing filter functionality.

### Test-Driven Development

| Gate | Status | Notes |
|------|--------|-------|
| Tests written before implementation | ⚠️ PENDING | Tests must be created in implementation phase |
| Unit tests for business logic | ⚠️ PENDING | Filter expression parsing/evaluation logic needs unit tests |
| Integration tests for database | ⚠️ PENDING | Segment CRUD operations need integration tests |
| Contract tests for API boundaries | ⚠️ PENDING | API contracts for segment save/load need tests |

**Assessment**: Tests will be created during implementation following TDD practices.

### Performance as a Feature

| Gate | Status | Notes |
|------|--------|-------|
| Query optimization considered | ⚠️ PENDING | Need to ensure filter queries remain efficient |
| Efficient data structures | ✅ PASS | Using existing filter representation |
| Caching strategies | ⚠️ PENDING | May need caching for filter preview counts |
| Benchmarks required | ⚠️ PENDING | Benchmark filter evaluation for 20 conditions / 5 levels |

**Assessment**: Performance targets from spec (2s preview, 20 conditions) will guide implementation.

### Observability and Debuggability

| Gate | Status | Notes |
|------|--------|-------|
| Structured logging | ✅ PASS | Uses existing logging infrastructure |
| Error tracking with context | ✅ PASS | Existing error handling covers new features |
| Metrics for key operations | ✅ PASS | Existing metrics infrastructure available |

**Assessment**: Standard observability practices apply.

### Simplicity and YAGNI

| Gate | Status | Notes |
|------|--------|-------|
| Start with simplest solution | ✅ PASS | Core implementation: single condition → AND/OR groups → nesting |
| No premature abstractions | ✅ PASS | Reusing existing filter infrastructure |
| Avoid over-engineering | ⚠️ PENDING | Nested groups complexity must be justified |

**Assessment**: Feature scope is justified for visitor segmentation use cases.

## Project Structure

### Documentation (this feature)

```text
specs/001-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This is a Plausible Analytics web application with Elixir/Phoenix backend and React/TypeScript frontend.

```text
# Backend - Elixir/Phoenix
lib/plausible/
├──Repo.ex               # Ecto repository
├──segments/
│   └── *.ex             # Segment business logic
└──web/
    ├── controllers/     # API controllers for segments
    └── views/          # JSON views

priv/repo/migrations/   # Database migrations

# Frontend - React/TypeScript
assets/js/
├── dashboard/
│   ├── filtering/
│   │   ├── segments.ts           # Existing segment utilities
│   │   ├── segments-context.tsx  # Segment React context
│   │   └── segments.test.ts
│   ├── components/
│   │   └── filter-modal*.js      # Existing filter UI
│   └── stats/modals/
│       ├── filter-modal.js       # Existing filter modal
│       └── filter-modal-group.js # Existing filter group modal

test/plausible/           # Elixir tests
assets/js/dashboard/     # Jest tests
```

**Structure Decision**: Extend existing segment and filter infrastructure:
- Backend: Add segment CRUD operations in existing `lib/plausible/segments/` module
- Frontend: Add advanced filter builder component in `assets/js/dashboard/components/` or `assets/js/dashboard/filtering/`
- Reuse existing filter modal infrastructure

