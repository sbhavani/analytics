# Data Model: Advanced Filter Builder

## Entities

### FilterCondition

A single rule that checks a visitor attribute against a value.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| dimension | string | The visitor attribute to filter on | Required, must be valid dimension |
| operator | string | Comparison operator | Required, one of: is, is-not, contains, greater, less, between, is-set, is-not-set |
| value | string \| number \| string[] | The value(s) to compare against | Required unless operator is is-set/is-not-set |

**Example**:
```json
{ "dimension": "country", "operator": "is", "value": "US" }
```

---

### FilterGroup

A collection of conditions combined with a logical operator.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| operator | 'AND' \| 'OR' | Logical operator for combining children | Required |
| children | Array<FilterCondition \| FilterGroup> | Nested conditions or groups | Required, min 1 item, max 20 total conditions |

**Example**:
```json
{
  "operator": "AND",
  "children": [
    { "dimension": "country", "operator": "is", "value": "US" },
    { "dimension": "device", "operator": "is", "value": "mobile" }
  ]
}
```

---

### FilterExpression

The complete filter configuration including all groups and conditions.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| version | number | Schema version for future compatibility | Default: 1 |
| root | FilterGroup | Root group containing all conditions | Required |
| metadata | object | Optional: created_at, updated_at timestamps | Optional |

**Example**:
```json
{
  "version": 1,
  "root": {
    "operator": "OR",
    "children": [
      {
        "operator": "AND",
        "children": [
          { "dimension": "country", "operator": "is", "value": "US" },
          { "dimension": "device", "operator": "is", "value": "mobile" }
        ]
      },
      {
        "operator": "AND",
        "children": [
          { "dimension": "country", "operator": "is", "value": "UK" },
          { "dimension": "device", "operator": "is", "value": "desktop" }
        ]
      }
    ]
  }
}
```

---

### VisitorSegment (extends existing SavedSegment)

A saved filter expression with a user-defined name for reuse.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | number | Unique identifier | Auto-generated |
| name | string | User-defined segment name | Required, 1-255 chars, unique per user/site |
| filter_expression | FilterExpression | The filter configuration | Required |
| type | 'personal' \| 'site' | Segment visibility scope | Required |
| owner_id | number | User who created the segment | Required |
| site_id | number | Site the segment belongs to | Required for site segments |
| inserted_at | datetime | Creation timestamp | Auto-generated |
| updated_at | datetime | Last modified timestamp | Auto-generated |

---

## Relationships

```
VisitorSegment (1) ---> (1) FilterExpression
FilterExpression (1) ---> (1) FilterGroup (root)
FilterGroup (1) ---> (*) FilterCondition | FilterGroup (children)
```

---

## State Transitions

### Segment Lifecycle

```
Draft --> Active --> Archived
  |         |          |
  +---------+----------+
  (can transition back to Active from Archived)
```

### Filter Builder State

```
Empty --> Editing --> Valid --> Saved
               |
               v
           Invalid (validation errors)
```

---

## Validation Rules

1. **FilterCondition**:
   - dimension must be in the allowed list of visitor attributes
   - operator must be compatible with dimension type (e.g., "greater" not allowed for country)
   - value must not exceed maximum length (255 chars for strings)

2. **FilterGroup**:
   - Maximum 20 total FilterCondition items across all nested groups
   - Maximum nesting depth of 5 levels
   - Minimum 1 child element

3. **VisitorSegment**:
   - name must be unique within the owner/site scope
   - filter_expression must be valid JSON matching schema
   - user must have permission to create segments (not viewer role)

---

## API Contracts

### Create Segment

**Request**:
```http
POST /api/sites/:site_id/segments
Content-Type: application/json

{
  "name": "US Mobile Users",
  "type": "site",
  "filter_expression": { ... }
}
```

**Response** (201):
```json
{
  "id": 123,
  "name": "US Mobile Users",
  "type": "site",
  "filter_expression": { ... },
  "inserted_at": "2026-02-25T10:00:00Z",
  "updated_at": "2026-02-25T10:00:00Z"
}
```

### List Segments

**Request**:
```http
GET /api/sites/:site_id/segments
```

**Response** (200):
```json
{
  "segments": [
    {
      "id": 123,
      "name": "US Mobile Users",
      "type": "site",
      "inserted_at": "2026-02-25T10:00:00Z",
      "updated_at": "2026-02-25T10:00:00Z"
    }
  ]
}
```

### Apply Segment (existing endpoint extends)

The existing filter endpoint accepts an optional `segment_id` parameter to apply a saved segment.
