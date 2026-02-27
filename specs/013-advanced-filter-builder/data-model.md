# Data Model: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-26

## Overview

This document defines the data structures for the Advanced Filter Builder, extending the existing flat filter model to support nested filter groups with AND/OR boolean logic.

## Entities

### Filter Condition

A single rule that checks a visitor property against a value.

```typescript
interface FilterCondition {
  /** Filter operation: 'is', 'is_not', 'contains', 'contains_not', 'has_not_done' */
  operation: FilterOperation
  /** Dimension name: 'country', 'browser', 'source', etc. */
  dimension: string
  /** Values to compare against */
  clauses: unknown[]
}
```

**Example**:
```json
["is", "country", ["US"]]
```

### Filter Group

A collection of filter conditions combined with a logical operator.

```typescript
type FilterGroup = {
  /** Logical operator for combining children */
  filter_type: 'and' | 'or'
  /** Child conditions or nested groups */
  children: (FilterCondition | FilterGroup)[]
}
```

**Example**:
```json
{
  "filter_type": "and",
  "children": [
    ["is", "country", ["US"]],
    ["is", "device", ["mobile"]]
  ]
}
```

### Filter Composite

The complete filter configuration that may contain a single condition, a flat group, or nested groups.

```typescript
type FilterComposite =
  | FilterCondition
  | FilterGroup
```

**Backward Compatibility Note**: The existing flat filter array format `[[operation, dimension, clauses], ...]` is equivalent to:
```json
{
  "filter_type": "and",
  "children": [[operation, dimension, clauses], ...]
}
```

### Saved Segment

A named filter configuration stored for future use, persisted in PostgreSQL.

```typescript
interface SavedSegment {
  /** Unique identifier */
  id: number
  /** User-provided name */
  name: string
  /** Segment scope: 'personal' or 'site' */
  type: 'personal' | 'site'
  /** Filter configuration */
  segment_data: {
    filters: FilterComposite | FilterCondition[]  // Supports both new nested and old flat formats
    labels: Record<string, string>
  }
  /** Original creator */
  owner_id: number | null
  owner_name: string | null
  /** Timestamps */
  inserted_at: string
  updated_at: string
}
```

## Validation Rules

### Filter Condition

- `operation` must be one of: `is`, `is_not`, `contains`, `contains_not`, `has_not_done`
- `dimension` must be a non-empty string
- `clauses` must be a non-empty array

### Filter Group

- `filter_type` must be `and` or `or`
- `children` must contain at least one element
- Maximum nesting depth: 2 levels (a group within a group)
- Maximum children per group: 10

### Saved Segment

- `name`: 1-255 bytes
- `segment_data`: JSON object with optional `filters` and `labels`
- `filters`: Must be valid filter composite or flat array (backward compatibility)
- `labels`: Optional map of value keys to display labels

## State Transitions

### Filter Builder State

```
Empty → Adding Condition → Condition Added
Condition Added → Adding Another Condition → Multiple Conditions
Multiple Conditions → Adding Connector (AND/OR) → Grouped Conditions
Grouped Conditions → Nesting Group → Nested Groups
Any State → Saving Segment → Saved Segment
```

### Segment Lifecycle

```
Draft → Validating → Validated
Validated → Saving → Saved
Saved → Loading → Loaded
Loaded → Editing → Modified
Modified → Saving → Saved (updated)
Any → Deleting → Deleted
```

## API Data Formats

### GET /api/sites/:site_id/segments

Returns list of saved segments with filter data.

### POST /api/sites/:site_id/segments

Creates a new segment with filter configuration.

**Request Body**:
```json
{
  "name": "US Mobile Users",
  "type": "site",
  "segment_data": {
    "filters": {
      "filter_type": "and",
      "children": [
        ["is", "country", ["US"]],
        ["is", "device", ["mobile"]]
      ]
    },
    "labels": {"US": "United States", "mobile": "Mobile"}
  }
}
```

### PUT /api/sites/:site_id/segments/:id

Updates an existing segment.

### DELETE /api/sites/:site_id/segments/:id

Deletes a segment.

## Database Schema

### PostgreSQL: segments table

```sql
CREATE TABLE segments (
  id SERIAL PRIMARY KEY,
  site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  owner_id INTEGER NOT NULL REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('personal', 'site')),
  segment_data JSONB NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_segments_site_id ON segments(site_id);
CREATE INDEX idx_segments_owner_id ON segments(owner_id);
```

**Note**: No schema changes required - existing `segment_data` JSONB column supports both flat array (backward compatibility) and nested object (new format) through validation logic.
