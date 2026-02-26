# Implementation Plan: Time Period Comparison

**Branch**: `002-period-comparison` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-period-comparison/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Enable users to compare analytics metrics between two date ranges (e.g., this week vs last week) with visual percentage change indicators. This feature extends the existing analytics dashboard with period comparison capabilities, allowing users to select primary and comparison date ranges via predefined options or custom dates, displaying side-by-side metrics with color-coded percentage changes.

## Technical Context

**Language/Version**: Elixir 1.14+, Phoenix Framework 1.7+
**Primary Dependencies**: Phoenix, Ecto, ClickHouse NIF adapter, React 18, TypeScript, TailwindCSS
**Storage**: PostgreSQL (transactions), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (web application)
**Project Type**: web-service
**Performance Goals**: Real-time analytics queries with sub-second response for comparison calculations
**Constraints**: Privacy-first (no personal data collection), GDPR/CCPA/PECR compliant
**Scale/Scope**: Multi-tenant analytics dashboard supporting thousands of concurrent users viewing comparisons

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| II. Test-Driven Development | **REQUIRED** | All new features require tests written before implementation using ExUnit for Elixir, Jest for JavaScript |
| III. Performance as a Feature | **APPLICABLE** | Analytics queries must be optimized; consider ClickHouse query patterns for period comparisons |
| IV. Observability and Debuggability | **APPLICABLE** | Add structured logging for comparison calculations |
| V. Simplicity and YAGNI | **APPLICABLE** | Start with simple comparison UI; avoid over-engineering |

**Constitution Alignment**: Feature is privacy-compliant by design (comparing aggregate metrics, no PII), requires tests before implementation, and should be implemented simply.

---

## Constitution Check (Post-Design)

*GATE: Re-evaluated after Phase 1 design completion.*

| Gate | Status | Verification |
|------|--------|--------------|
| II. Test-Driven Development | **PASS** | Research confirms tests required; quickstart.md includes test checklist |
| III. Performance as a Feature | **PASS** | ClickHouse query patterns identified; simple application-layer calculation |
| IV. Observability and Debuggability | **PASS** | Logging included in quickstart.md for comparison calculations |
| V. Simplicity and YAGNI | **PASS** | Simple UI-first approach; predefined periods minimize complexity |

**Result**: All gates pass - feature is ready for implementation.

---

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

Based on Plausible Analytics project structure:

```text
lib/
├── plausible/
│   ├── application.ex
│   ├── repo.ex
│   └── [contexts, schemas, controllers]

priv/
├── repo/
│   └── migrations/

assets/
├── src/
│   ├── components/       # React components (period picker, comparison display)
│   ├── pages/           # Dashboard pages
│   └── lib/             # Utility functions

test/
├── plausible/           # Elixir unit/integration tests
└── support/

e2e/
└── tests/               # End-to-end tests
```

**Structure Decision**: This is a Phoenix web application with React frontend. The period comparison feature will require:
- **Backend**: New context for period calculations, existing ClickHouse query patterns for metrics
- **Frontend**: New React components for period picker and comparison display
- **Tests**: Both Elixir tests for backend logic and Jest tests for React components

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
