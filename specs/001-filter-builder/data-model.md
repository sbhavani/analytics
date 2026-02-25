# Data Model: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments
**Date**: 2026-02-25
**Spec**: [spec.md](spec.md)

## Entities

### FilterCondition

Represents a single filtering rule in the UI.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID string | Unique identifier for the condition |
| property | string | Visitor property to filter (e.g., "country", "device") |
| operator | string | Comparison operator (e.g., "equals", "contains") |
| value | string \| string[] | Value(s) to match against |

**Validation Rules**:
- `property` must be from predefined list of available visitor properties
- `operator` must be valid for the property type
- `value` must match expected format (string, array of strings, or numeric)

---

### FilterGroup

A container for conditions combined with AND/OR logic. Can contain both conditions and nested groups.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID string | Unique identifier for the group |
| logic | enum ('AND', 'OR') | How conditions in this group are combined |
| conditions | FilterCondition[] | List of conditions at this level |
| groups | FilterGroup[] | Nested filter groups |

**Validation Rules**:
- At least one of `conditions` or `groups` must be non-empty
- Maximum nesting depth: 5 levels
- Maximum conditions per group: 20

---

### VisitorSegment (Backend - Existing)

The saved segment entity.

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Primary key |
| name | string | User-defined segment name (max 255 bytes) |
| type | enum ('personal', 'site') | Segment visibility |
| segment_data | JSON | Contains `filters` and `labels` |
| site_id | integer | Foreign key to site |
| owner_id | integer | Foreign key to user |
| inserted_at | datetime | Creation timestamp |
| updated_at | datetime | Last modification |

**Validation Rules** (from existing Segment schema):
- `name` required, 1-255 bytes
- `segment_data.filters` must be non-empty array
- `segment_data.labels` must be map or null
- `segment_data` max 5KB

---

### Visitor Property

Metadata about filterable visitor properties.

| Field | Type | Description |
|-------|------|-------------|
| key | string | Property identifier (e.g., "visit:country") |
| name | string | Display name (e.g., "Country") |
| type | enum ('string', 'numeric', 'list') | Data type |
| operators | string[] | Available operators for this property |

**Example Properties**:
- `visit:country` - Country code (string)
- `visit:device` - Device type (string)
- `visit:browser` - Browser name (string)
- `visit:pages_viewed` - Pages viewed count (numeric)
- `visit:duration` - Session duration in seconds (numeric)

---

## Relationships

```
FilterBuilder
    │
    ├── contains ──► FilterGroup (root)
    │                    │
    │                    ├── contains ──► FilterCondition
    │                    │
    │                    └── contains ──► FilterGroup (nested)
    │
    └── converts to ──► VisitorSegment.segment_data
```

---

## State Transitions

### Filter Builder State

```
┌─────────────────┐
│   Empty State   │ ◄── Start (clear all)
└────────┬────────┘
         │ add condition
         ▼
┌─────────────────┐
│  Single Condition│
└────────┬────────┘
         │ add condition
         ▼
┌─────────────────┐
│  AND Group      │ ◄── Group multiple conditions
└────────┬────────┘
         │ change logic
         ▼
┌─────────────────┐
│  OR Group       │
└────────┬────────┘
         │ add nested group
         ▼
┌─────────────────┐
│ Nested Groups   │
└────────┬────────┘
         │ save
         ▼
┌─────────────────┐
│ Saved Segment   │
└─────────────────┘
```

### Segment Lifecycle

1. **Draft** - Filter being built, not saved
2. **Valid** - Filter passes validation (has conditions, valid values)
3. **Saved** - Persisted to database as VisitorSegment
4. **Loaded** - Retrieved from database for editing

---

## API Contracts

### Filter Preview Request

```typescript
POST /api/stats/{site_id}/filter-preview
{
  filters: FilterCondition[] | FilterGroup
}
```

### Filter Preview Response

```typescript
{
  visitors: number,
  sample_percent: number | null
}
```

### Segment CRUD Endpoints (Existing)

- `GET /api/sites/{site_id}/segments` - List all segments
- `POST /api/sites/{site_id}/segments` - Create segment
- `PUT /api/sites/{site_id}/segments/{id}` - Update segment
- `DELETE /api/sites/{site_id}/segments/{id}` - Delete segment

---

## Notes

- The existing backend expects flat filter format. Visual filter groups need to be converted to flat format for storage.
- Nested groups require recursive flattening to backend-compatible structure.
- Filter preview endpoint may need to be added if not existing.
