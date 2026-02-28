# Data Model: Advanced Filter Builder

This document describes the data structures for the Advanced Filter Builder feature.

## Overview

The filter builder uses a tree-based structure to represent complex filter conditions with AND/OR logic and nested groups.

## TypeScript Types

### FilterCondition

Represents a single filter rule.

```typescript
interface FilterCondition {
  id: string           // Unique identifier for the condition
  attribute: string    // e.g., "country", "browser", "device_type"
  operator: FilterOperator
  value: string | number
  isNegated: boolean   // true for "does not equal", "does not contain"
}
```

### FilterOperator

```typescript
type FilterOperator =
  | 'equals'        // "is"
  | 'contains'      // "contains"
  | 'is_set'       // "is set"
  | 'is_not_set'   // "is not set"
```

### FilterGroup

Represents a group of conditions connected by AND/OR.

```typescript
interface FilterGroup {
  id: string                    // Unique identifier for the group
  connector: 'AND' | 'OR'       // How conditions are combined
  conditions: FilterCondition[] // Flat list within this group
  nestedGroups: FilterGroup[]   // Nested groups (for complex logic)
}
```

### FilterTree (Root Structure)

The complete filter configuration.

```typescript
interface FilterTree {
  rootGroup: FilterGroup
}
```

### SavedSegment

Extended from existing segment model.

```typescript
interface SavedSegment {
  id: number
  name: string
  type: 'personal' | 'site'
  filterTree: FilterTree
  inserted_at: string
  updated_at: string
  owner_id: number | null
  owner_name: string | null
}
```

### SegmentPreview

Real-time visitor count preview.

```typescript
interface SegmentPreview {
  visitorCount: number
  isLoading: boolean
  hasError: boolean
  errorMessage?: string
}
```

## API Data Structures

### Filter (Legacy Format)

For backward compatibility with existing API:

```typescript
type LegacyFilter = [string, string, (string | number)[]]
// Example: ['is', 'country', ['US', 'DE']]
```

### Segment API Response

```typescript
interface SegmentAPIResponse {
  id: number
  name: string
  type: 'personal' | 'site'
  segment_data: {
    filters: LegacyFilter[]
    labels: Record<string, string>
  }
  inserted_at: string
  updated_at: string
}
```

## Conversion Between Formats

### FilterTree → Legacy Filters

```typescript
function filterTreeToLegacyFilters(tree: FilterTree): LegacyFilter[] {
  // Recursively flatten the tree to legacy filter format
  // Returns array of filters that can be sent to existing API
}
```

### Legacy Filters → FilterTree

```typescript
function legacyFiltersToFilterTree(filters: LegacyFilter[]): FilterTree {
  // Convert legacy flat filter array to tree structure
  // Default connector: AND
}
```

## State Management

### FilterBuilderState

```typescript
interface FilterBuilderState {
  filterTree: FilterTree
  isDirty: boolean
  isValid: boolean
  preview: SegmentPreview
  savedSegments: SavedSegment[]
  isLoadingSegments: boolean
}
```

### Actions

```typescript
type FilterBuilderAction =
  | { type: 'ADD_CONDITION'; groupId: string; condition: FilterCondition }
  | { type: 'UPDATE_CONDITION'; conditionId: string; updates: Partial<FilterCondition> }
  | { type: 'DELETE_CONDITION'; conditionId: string }
  | { type: 'ADD_NESTED_GROUP'; parentGroupId: string; group: FilterGroup }
  | { type: 'UPDATE_CONNECTOR'; groupId: string; connector: 'AND' | 'OR' }
  | { type: 'LOAD_SEGMENT'; segment: SavedSegment }
  | { type: 'CLEAR_ALL' }
  | { type: 'SET_PREVIEW'; preview: SegmentPreview }
  | { type: 'SET_SEGMENTS'; segments: SavedSegment[] }
```

## Validation Rules

1. Each condition must have a non-empty attribute
2. "equals" and "contains" operators require a value
3. Minimum one condition required to apply filter
4. Maximum 50 conditions per filter tree (performance constraint)
5. Nested group depth limited to 5 levels (complexity constraint)
