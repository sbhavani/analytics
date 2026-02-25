# Data Model: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments
**Date**: 2026-02-25

## Entities

### FilterCondition

A single rule consisting of a field, operator, and value.

**Fields**:
- `id`: string (unique identifier for UI rendering)
- `field`: string (visitor attribute to filter on, e.g., "country", "device")
- `operator`: string (comparison operator: "is", "is_not", "contains", "greater_than", "less_than", "is_set", "is_not_set")
- `value`: string | number | boolean (the value to compare against)

**Validation**:
- `field` must be a valid visitor attribute
- `operator` must be supported for the given field
- `value` is required unless operator is "is_set" or "is_not_set"

---

### FilterGroup

A collection of conditions combined with AND/OR logic, optionally nested.

**Fields**:
- `id`: string (unique identifier for UI rendering)
- `type`: "group" (distinguishes groups from conditions)
- `operator`: "AND" | "OR" (logical operator for combining children)
- `children`: Array<FilterCondition | FilterGroup> (nested conditions or groups)

**Validation**:
- `children` must contain at least one item
- Nested groups limited to maximum depth of 3 levels

---

### VisitorSegment

A saved filter configuration with a user-defined name for reuse.

**Fields** (extending existing SavedSegment type):
- `id`: number (unique identifier)
- `name`: string (user-defined name)
- `type`: "personal" | "site" (ownership type)
- `filterStructure`: FilterGroup (the root group containing all conditions)
- `inserted_at`: string (creation timestamp)
- `updated_at`: string (last modified timestamp)
- `owner_id`: number | null (user who created)
- `owner_name`: string | null

**Validation**:
- `name` must be 1-255 characters
- `filterStructure` must be valid and non-empty

---

### VisitorAttribute

A data field available for filtering.

**Fields**:
- `key`: string (internal identifier)
- `label`: string (display name)
- `type`: "string" | "number" | "boolean" | "enum"
- `operators`: string[] (supported operators)
- `values`: string[] | null (predefined values for enum type)

---

## Relationships

```
VisitorSegment (1) ──────< FilterGroup (root)
                               │
                               ├─< FilterCondition
                               └─< FilterGroup (nested)
```

---

## State Transitions

### FilterBuilder State

1. **Empty**: No conditions added
   - Initial state, user can add first condition

2. **Building**: Conditions being added/modified
   - User adds, edits, or removes conditions

3. **Valid**: All conditions have valid configuration
   - Can apply filter or save segment

4. **Applied**: Filter applied to visitor list
   - Results displayed, can modify and re-apply

---

## API Integration Points

### Load Saved Segments
- Endpoint: `GET /api/stats/:domain/segments`
- Returns: Array of VisitorSegment

### Save New Segment
- Endpoint: `POST /api/stats/:domain/segments`
- Body: `{ name, type, filterStructure }`

### Update Segment
- Endpoint: `PUT /api/stats/:domain/segments/:id`
- Body: `{ name, filterStructure }`

### Delete Segment
- Endpoint: `DELETE /api/stats/:domain/segments/:id`

---

## Backward Compatibility

The existing filter format `['is', 'dimension', ['value']]` is preserved for:
- URL serialization in query params
- Shared links andbookmarks
- API communication with backend

The new FilterGroup structure is used only in the UI builder and converted to the existing format before API calls.
