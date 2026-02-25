# Quickstart: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments

## Overview

This guide helps developers start implementing the Advanced Filter Builder feature. The feature adds a UI component that allows users to combine multiple filter conditions with AND/OR logic for custom visitor segments.

## Prerequisites

- Node.js 18+
- Elixir 1.16+
- PostgreSQL (local development)
- ClickHouse (local development)

## Setup

1. **Install frontend dependencies**:
   ```bash
   cd assets && npm install
   ```

2. **Run frontend tests**:
   ```bash
   npm test
   ```

3. **Start development server**:
   ```bash
   mix phx.server
   ```

## Key Files to Modify

### Frontend (React/TypeScript)

| File | Purpose |
|------|---------|
| `assets/js/dashboard/components/filter-builder/FilterBuilder.tsx` | Main container component |
| `assets/js/dashboard/components/filter-builder/FilterConditionRow.tsx` | Single condition row |
| `assets/js/dashboard/components/filter-builder/FilterGroup.tsx` | Nested group container |
| `assets/js/dashboard/components/filter-builder/LogicalOperatorSelector.tsx` | AND/OR toggle |
| `assets/js/dashboard/components/filter-builder/FilterPreview.tsx` | Visitor count preview |
| `assets/js/dashboard/stats/modals/filter-modal.js` | Add "Advanced" toggle |
| `assets/js/dashboard/filtering/segments.ts` | Add segment save/load logic |

### Backend (Elixir)

| File | Purpose |
|------|---------|
| `lib/plausible/segments.ex` | Add filter structure validation |

## Running Tests

```bash
# Frontend unit tests
cd assets && npm test

# Backend tests
mix test
```

## Common Tasks

### Add a new filter field

1. Add field to `FILTER_MODAL_TO_FILTER_GROUP` in `filters.js`
2. Add operators to `FILTER_OPERATIONS`
3. Update `VisitorAttribute` in data-model.md

### Add a new operator

1. Add to `FILTER_OPERATIONS` in `filters.js`
2. Add display name to `FILTER_OPERATIONS_DISPLAY_NAMES`
3. Add to operator selector component

### Save filter as segment

1. Use existing `segments-context.tsx` for state management
2. Convert `FilterGroup` to legacy filter format
3. Call `POST /api/stats/:domain/segments`

## Debugging

- Check browser console for React component errors
- Use React DevTools to inspect filter state
- Check network tab for API calls to `/api/stats/*/segments`
- Review ClickHouse query logs for filter performance
