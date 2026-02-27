# Contracts: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-26

## Overview

This document describes the internal API contracts used by the Advanced Filter Builder. Since this is an internal feature extension (not a public API), these contracts define the internal patterns used between frontend and backend.

## Existing API Contracts

The Advanced Filter Builder extends existing segment APIs. No new endpoints are required.

### Segment API (Existing - Extended)

#### GET /api/sites/:site_id/segments

Returns all saved segments for a site.

**Response**:
```typescript
{
  "results": Array<{
    id: number
    name: string
    type: "personal" | "site"
    segment_data: {
      filters: FilterComposite | FilterCondition[]  // New nested or old flat
      labels: Record<string, string>
    }
    owner_id: number | null
    owner_name: string | null
    inserted_at: string
    updated_at: string
  }>
}
```

#### POST /api/sites/:site_id/segments

Creates a new segment with filter configuration.

**Request Body**:
```typescript
{
  name: string
  type: "personal" | "site"
  segment_data: {
    filters: FilterComposite | FilterCondition[]  // New nested or old flat
    labels?: Record<string, string>
  }
}
```

**Response** (201 Created):
```typescript
{
  id: number
  name: string
  // ... full segment object
}
```

**Errors**:
- 400: Invalid filter structure or validation failure
- 403: User lacks permission
- 422: Segment name conflict or data limit exceeded

#### PUT /api/sites/:site_id/segments/:id

Updates an existing segment.

**Request Body**:
```typescript
{
  name?: string
  segment_data?: {
    filters: FilterComposite | FilterCondition[]
    labels?: Record<string, string>
  }
}
```

**Response** (200 OK):
```typescript
{
  id: number
  // ... updated segment object
}
```

#### DELETE /api/sites/:site_id/segments/:id

Deletes a segment.

**Response** (204 No Content)

### Query API (Existing - Extended)

#### GET /api/stats/:domain

The analytics query API already supports filters. The Advanced Filter Builder extends the filter format but maintains backward compatibility.

**Query Parameters**:
- `filters`: JSON-encoded filter structure (supports both old flat array and new nested format)

**Filter Format Examples**:

Old flat format (still supported):
```json
[["is","country",["US"]],["is","device",["mobile"]]]
```

New nested format:
```json
{"filter_type":"and","children":[["is","country",["US"]],["is","device",["mobile"]]]}
```

With OR:
```json
{
  "filter_type": "or",
  "children": [
    {"filter_type": "and", "children": [["is","country",["US"]],["is","device",["mobile"]]]},
    {"filter_type": "and", "children": [["is","country",["UK"]],["is","device",["desktop"]]]}
  ]
}
```

## Internal Component Contracts

### FilterBuilder Component

```typescript
interface FilterBuilderProps {
  /** Current filter configuration */
  filter: FilterComposite
  /** Callback when filter changes */
  onChange: (filter: FilterComposite) => void
  /** Available filter dimensions */
  availableDimensions: Dimension[]
  /** Maximum nesting depth allowed */
  maxDepth?: number
  /** Maximum children per group */
  maxChildren?: number
  /** Whether the builder is read-only */
  readOnly?: boolean
}
```

### FilterGroup Component

```typescript
interface FilterGroupProps {
  /** Group configuration */
  group: FilterGroup
  /** Group index for identification */
  groupId: string
  /** Depth level for nesting */
  depth: number
  /** Callback when group changes */
  onChange: (group: FilterGroup) => void
  /** Callback to remove this group */
  onRemove: () => void
  /** Available filter dimensions */
  availableDimensions: Dimension[]
  /** Maximum nesting depth allowed */
  maxDepth: number
}
```

### FilterCondition Component

```typescript
interface FilterConditionProps {
  /** Condition configuration */
  condition: FilterCondition
  /** Condition index */
  conditionId: string
  /** Callback when condition changes */
  onChange: (condition: FilterCondition) => void
  /** Callback to remove this condition */
  onRemove: () => void
  /** Available filter dimensions */
  availableDimensions: Dimension[]
  /** Available operations for the selected dimension */
  availableOperations: FilterOperation[]
}
```

## Data Type Definitions

### FilterOperation

```typescript
type FilterOperation = 'is' | 'is_not' | 'contains' | 'contains_not' | 'has_not_done'
```

### Dimension

```typescript
interface Dimension {
  key: string
  name: string
  type: 'string' | 'number' | 'boolean'
  supportedOperations: FilterOperation[]
}
```

### FilterComposite

```typescript
type FilterComposite = FilterCondition | FilterGroup

interface FilterCondition {
  operation: FilterOperation
  dimension: string
  clauses: unknown[]
}

interface FilterGroup {
  filter_type: 'and' | 'or'
  children: FilterComposite[]
}
```

## Backward Compatibility

The API contracts maintain full backward compatibility:

1. **Old flat array format** in requests: `[[op, dim, clauses], ...]` → Automatically converted to nested format internally
2. **New nested format** in requests: Full support for AND/OR groups and nesting
3. **API responses**: Always return new nested format for consistency

### Conversion Logic

```typescript
function flatToNested(filters: FilterCondition[]): FilterGroup {
  return {
    filter_type: 'and',
    children: filters
  }
}

function nestedToFlat(filter: FilterComposite): FilterCondition[] {
  if ('filter_type' in filter) {
    return flattenConditions(filter.children)
  }
  return [filter]
}
```
