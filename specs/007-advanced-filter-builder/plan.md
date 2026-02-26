# Implementation Plan: Advanced Filter Builder

**Branch**: `007-advanced-filter-builder` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-advanced-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The Advanced Filter Builder is a UI component that allows users to create complex visitor segments by combining multiple filter conditions using AND/OR logic and nested groups. It extends the existing segment functionality in Plausible Analytics with a visual builder interface for creating sophisticated segmentation criteria without requiring technical knowledge of the underlying filter syntax.

**Primary Requirement**: Create a UI component enabling users to combine multiple filter conditions with AND/OR operators, support nested condition groups, save filter templates, and iterate on filters with undo/redo support.

**Technical Approach**: Build a React component that leverages existing filter infrastructure (FilterModal, filter contexts) while adding visual condition grouping, logical operators, and template persistence via the existing segments API.

## Technical Context

**Language/Version**: Elixir 1.15+, React 18+, TypeScript 5+
**Primary Dependencies**: @headlessui/react, @heroicons/react, @tanstack/react-query, Phoenix LiveView (backend)
**Storage**: PostgreSQL (filter templates via segments table), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (browser-based UI)
**Performance Goals**: Filter results update within 2 seconds; support 10+ conditions without degradation
**Constraints**: Must work within existing filter system; support 3+ nesting levels
**Scale/Scope**: Feature module ~10 React components, ~5 Elixir API endpoints

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | PASS | No personal data collection; filters operate on aggregated analytics data only |
| II. Test-Driven Development | PASS | ExUnit tests for backend filter parsing; Jest tests for UI components |
| III. Performance as a Feature | PASS | Target 2s update time; supports caching via existing query infrastructure |
| IV. Observability and Debuggability | PASS | Structured logging in API; filter debug view for troubleshooting |
| V. Simplicity and YAGNI | PASS | Uses existing segment infrastructure; no premature abstractions |

**Initial Gate Result**: PASS - All constitutional principles satisfied. No violations requiring complexity tracking.

## Project Structure

### Documentation (this feature)

```
specs/007-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
# Plausible Analytics Structure
lib/
├── plausible/
│   ├── segments/              # Existing segment logic
│   │   ├── segment.ex         # Core segment functions
│   │   ├── segments.ex        # Segment CRUD operations
│   │   └── filters.ex         # Filter parsing
│   └── stats/
│       ├── query_builder.ex   # Query building
│       └── filters/           # Filter implementations

assets/js/dashboard/
├── filtering/
│   ├── segments.ts            # Existing segment context
│   ├── segments-context.tsx   # Segment provider
│   └── new-filter-builder/    # NEW: Advanced filter builder components
│       ├── FilterBuilder.tsx  # Main builder component
│       ├── ConditionRow.tsx  # Individual condition
│       ├── ConditionGroup.tsx # Group of conditions
│       ├── OperatorSelector.tsx # AND/OR selector
│       └── FilterSummary.tsx # Readable filter summary
├── segments/
│   └── segment-modals.tsx    # Existing segment modals (extend)
└── util/
    └── filters.js             # Existing filter utilities (extend)

lib/plausible_web/
├── controllers/
│   └── api/
│       └── segments_controller.ex  # Existing API (extend)
└── live/
    └── components/
        └── filter_builder_live.ex  # NEW: LiveView component
```

**Structure Decision**: Filter builder components will be placed in `assets/js/dashboard/filtering/new-filter-builder/`. Backend persistence leverages existing segments table and API. No new database tables required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity tracking required - no constitutional violations.

---

## Phase 0: Outline & Research

### Research Tasks

1. **Understand existing filter architecture**
   - Current filter representation in frontend and backend
   - How filters are parsed and converted to queries
   - Existing segment storage and retrieval

2. **Investigate UI component patterns**
   - Headless UI usage for dropdowns/modals
   - Existing modal patterns in segment-modals.tsx
   - TailwindCSS conventions for complex interactive components

3. **Review API integration**
   - Existing segments API endpoints
   - Query parameter format for filters
   - Error handling patterns

### Research Findings

**Decision**: Use existing filter infrastructure with new UI layer

**Rationale**: The codebase already has robust filter parsing and segment persistence. Adding a visual builder on top follows the principle of simplicity - build on existing foundations rather than creating parallel systems.

**Alternatives considered**:
- Creating new filter storage table: Rejected - existing segments table sufficient
- Building separate API: Rejected - leverage existing segments API
- Using third-party query builder library: Rejected - YAGNI, existing patterns sufficient

---

## Phase 1: Design & Contracts

### Entities

#### FilterCondition

Represents a single filtering rule in the builder UI.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier for the condition |
| dimension | String | Yes | Filter field (e.g., "country", "page_views") |
| operator | String | Yes | Filter operation (e.g., "is", "contains", "greater_than") |
| value | String/Array | Yes | Filter value(s) |

#### FilterGroup

Represents a collection of conditions combined with a logical operator.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier for the group |
| operator | Enum | Yes | "and" or "or" - logical combination |
| children | Array | Yes | Array of FilterCondition or nested FilterGroup |

#### FilterTemplate

Saved filter configuration for reuse. Extends existing SavedSegment.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| name | String | Yes | User-provided template name |
| type | Enum | Yes | "site" or "personal" |
| filters | JSON | Yes | Serialized filter tree (FilterGroup) |
| description | String | No | Optional description |

### Validation Rules

1. **FilterCondition**
   - dimension: Must be one of supported filter fields
   - operator: Must be valid for the dimension type
   - value: Required unless operator is "is_not" with no value

2. **FilterGroup**
   - operator: Must be "and" or "or"
   - children: Minimum 1 child required

3. **FilterTemplate**
   - name: 1-255 characters, required
   - filters: Must be valid FilterGroup structure
   - type: Required, determines visibility (site-wide vs personal)

### State Transitions

```
[Empty] --add condition--> [Single Condition]
[Single Condition] --add condition--> [Multiple Conditions]
[Multiple Conditions] --group selected--> [Nested Group]
[Nested Group] --change operator--> [Updated Group]
[Any State] --remove condition--> [Updated State]
[Any State] --save template--> [Template Saved]
```

### API Contracts

#### Create Segment (extends existing)

```
POST /api/stats/:site_id/segments
Body: { name, type, filters: { operator: "and", children: [...] } }
Response: { id, name, type, filters, ... }
```

#### Update Segment

```
PUT /api/stats/:site_id/segments/:id
Body: { name?, type?, filters? }
Response: { id, name, type, filters, ... }
```

#### List Segments

```
GET /api/stats/:site_id/segments
Response: [{ id, name, type, filters, ... }]
```

#### Query with Segment

```
GET /api/stats/:site_id/main?segment=<segment_id>
Response: { ... analytics data ... }
```

---

## Phase 2: Implementation Planning

*Tasks will be generated via `/speckit.tasks` command*

The implementation will focus on:
1. Building the React filter builder component
2. Integrating with existing segments API
3. Adding nested group support
4. Implementing save/load functionality
5. Adding validation and error handling

---

## Post-Design Constitution Re-Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | PASS | No personal data collection; filters operate on aggregated analytics data only |
| II. Test-Driven Development | PASS | ExUnit tests for backend filter parsing; Jest tests for UI components |
| III. Performance as a Feature | PASS | Target 2s update time; supports caching via existing query infrastructure |
| IV. Observability and Debuggability | PASS | Structured logging in API; filter debug view for troubleshooting |
| V. Simplicity and YAGNI | PASS | Uses existing segment infrastructure; no premature abstractions |

**Final Gate Result**: PASS - All constitutional principles satisfied.
