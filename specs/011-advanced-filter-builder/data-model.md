# Data Model: Advanced Filter Builder

## Entities

### 1. FilterCondition

A single rule defining a visitor attribute, comparison operator, and value.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier for the condition |
| attribute | String | Visitor property to filter (e.g., "visit:country", "event:page") |
| operator | String | Comparison operator (e.g., "is", "contains", "matches_wildcard") |
| value | String | The value to compare against |
| negated | Boolean | Whether this condition is negated (NOT) |

**Relationships**: Belongs to a FilterGroup

### 2. FilterGroup

A collection of conditions and/or nested groups combined with a logical operator.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier for the group |
| operator | Enum | Logical operator combining children: "and", "or" |
| parent_id | UUID (nullable) | Reference to parent group for nesting |
| group_type | Enum | Type of children: "condition" or "group" |

**Relationships**:
- Has many FilterConditions
- Has many FilterGroups (nested)
- Belongs to parent FilterGroup (optional)

### 3. VisitorSegment

A named, saved filter configuration that can be loaded and applied to visitor data.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| name | String (max 100 chars) | User-defined segment name |
| site_id | UUID | Reference to the Plausible site |
| user_id | UUID | Owner of the segment |
| root_group_id | UUID | Reference to the root FilterGroup |
| is_global | Boolean | Whether visible to all site users |
| inserted_at | DateTime | Creation timestamp |
| updated_at | DateTime | Last modification timestamp |

**Relationships**:
- Belongs to Site
- Belongs to User
- Has one root FilterGroup

### 4. SegmentRevision

Tracks changes to segments for edit/discard functionality.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| segment_id | UUID | Reference to VisitorSegment |
| snapshot | JSON | Full filter configuration at this revision |
| created_at | DateTime | When this revision was created |

**Relationships**: Belongs to VisitorSegment

## State Transitions

### VisitorSegment States

```
Draft -> Active (on first save)
Active -> Active (on update)
Active -> Archived (on delete - soft delete)
```

## Validation Rules

1. **FilterCondition**
   - attribute: Required, must match known visitor property pattern
   - operator: Required, must be one of allowed operators
   - value: Required, non-empty for most operators

2. **FilterGroup**
   - operator: Required, must be "and" or "or"
   - children: At least 1 required for non-empty groups

3. **VisitorSegment**
   - name: Required, 1-100 characters, unique per site+user
   - site_id: Required, must exist
   - root_group_id: Required, must reference valid FilterGroup

## Constraints

- Maximum nesting depth: 5 levels
- Maximum conditions per group: 10
- Maximum total conditions per segment: 100

## Data Flow

1. User creates conditions in UI → serialized to JSON tree
2. JSON tree stored in FilterGroup structure
3. VisitorSegment references root FilterGroup
4. Backend converts FilterGroup to ClickHouse query via existing WhereBuilder
5. Results returned to frontend for preview
