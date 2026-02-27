# Data Model: Advanced Filter Builder

## Entities

### FilterCondition

Represents a single filter rule with dimension, operator, and value(s).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | `string` | Unique identifier for the condition | Auto-generated UUID |
| `dimension` | `string` | The field to filter (e.g., "country", "device") | Required, must be valid filter dimension |
| `operator` | `string` | Comparison operator | Required, valid operator for dimension type |
| `values` | `string[]` | Filter values | Required, non-empty for most operators |

### FilterGroup

A collection of filter conditions combined with AND/OR logic, which can contain nested groups.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | `string` | Unique identifier for the group | Auto-generated UUID |
| `operator` | `'and' \| 'or'` | How to combine children | Required, defaults to 'and' |
| `children` | `(FilterGroup \| FilterCondition)[]` | Nested groups or conditions | Required, at least 1 child |

### FilterTree

The hierarchical structure representing the complete filter configuration.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `rootGroup` | `FilterGroup` | Root group containing all filters | Required |
| `version` | `number` | Filter tree format version | Defaults to 1 |

### SavedSegment

A persisted filter configuration with a user-defined name for reuse.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | `number` | Unique segment ID | Assigned by backend |
| `name` | `string` | User-defined segment name | Required, 1-255 bytes |
| `type` | `'personal' \| 'site'` | Segment visibility | Required |
| `filterTree` | `FilterTree` | The saved filter configuration | Required |
| `ownerId` | `number \| null` | Segment owner user ID | Set on creation |
| `siteId` | `number` | Associated site | Required |
| `createdAt` | `string` | Creation timestamp | Assigned by backend |
| `updatedAt` | `string` | Last update timestamp | Assigned by backend |

### FilterDimension

Available field that can be filtered.

| Field | Type | Description |
|-------|------|-------------|
| `key` | `string` | Dimension identifier (e.g., "country", "device") |
| `name` | `string` | Display name |
| `type` | `'string' \| 'number' \| 'boolean'` | Value type |
| `operators` | `string[]` | Available operators for this dimension |

## Relationships

```
FilterTree
  └── FilterGroup (rootGroup)
       ├── FilterGroup (nested)
       │    └── FilterCondition[]
       └── FilterCondition[]

SavedSegment
  ├── FilterTree (filterTree)
  ├── Site (belongs to)
  └── User (owner)
```

## State Transitions

### FilterCondition State

```
[empty] → [dimension set] → [operator set] → [value set] → [valid]
                                              ↓
                                         [invalid] → [valid]
```

### FilterGroup State

```
[empty] → [has children] → [operator changed] → [nested added]
```

## Validation Rules

1. **FilterCondition**: Dimension and operator required; value required unless operator is "is_set" or "is_not_set"
2. **FilterGroup**: Must have at least one child; operator must be 'and' or 'or'
3. **FilterTree**: Root group required; max nesting depth is 3 levels
4. **SavedSegment**: Name unique per site; filterTree must pass validation

## API Serialization

### Frontend → Backend (Filter Tree to Flat Array)

```typescript
// Filter tree structure
{
  operator: 'and',
  children: [
    { dimension: 'country', operator: 'is', values: ['US'] },
    {
      operator: 'or',
      children: [
        { dimension: 'device', operator: 'is', values: ['mobile'] },
        { dimension: 'browser', operator: 'is', values: ['Chrome'] }
      ]
    }
  ]
}

// Serialized to flat array (existing backend format)
[
  ['is', 'country', ['US']],
  ['and', [
    ['is', 'device', ['mobile']],
    ['is', 'browser', ['Chrome']]
  ]]
]
```

### Backend → Frontend (Flat Array to Filter Tree)

Reverse the serialization above, reconstructing the tree from nested `:and`/`:or` arrays.
