# Data Model: Advanced Filter Builder

## Entities

### FilterCondition

A single filter rule that evaluates visitor data against a condition.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | string (UUID) | Unique identifier for the condition | Auto-generated |
| dimension | string | The visitor attribute to filter on (e.g., "visit:country") | Required, valid dimension |
| operator | string | Comparison operator (is, is_not, contains, etc.) | Required, valid operator |
| value | string[] | Values to compare against | Required, non-empty |
| modifier | object (optional) | Additional options (case_sensitive, etc.) | Optional |

**Example:**
```json
{
  "id": "cond-001",
  "dimension": "visit:country",
  "operator": "is",
  "value": ["US", "GB"]
}
```

---

### ConditionGroup

A container for multiple conditions or nested groups with a logical connector.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | string (UUID) | Unique identifier for the group | Auto-generated |
| connector | string | Logical connector: "and" or "or" | Required, "and" or "or" |
| conditions | FilterCondition[] | Array of leaf conditions | At least 1 if no children |
| children | ConditionGroup[] | Nested groups | Optional, max depth 3 |
| isRoot | boolean | Whether this is the root group | Auto-set |

**Example:**
```json
{
  "id": "group-001",
  "connector": "or",
  "conditions": [
    {
      "id": "cond-001",
      "dimension": "visit:country",
      "operator": "is",
      "value": ["US"]
    }
  ],
  "children": [
    {
      "id": "group-002",
      "connector": "and",
      "conditions": [
        { "dimension": "visit:country", "operator": "is", "value": ["GB"] },
        { "dimension": "visit:device", "operator": "is", "value": ["Mobile"] }
      ]
    }
  ],
  "isRoot": true
}
```

---

### FilterTree

The complete filter configuration representing a visitor segment.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| rootGroup | ConditionGroup | The root condition group | Required |
| labels | object | Human-readable labels for conditions | Optional |

**Example:**
```json
{
  "rootGroup": {
    "id": "root",
    "connector": "and",
    "conditions": [],
    "children": [...]
  },
  "labels": {
    "cond-001": "United States Visitors"
  }
}
```

---

## Relationships

```
FilterTree
  └── rootGroup: ConditionGroup
       ├── conditions: FilterCondition[]
       └── children: ConditionGroup[]
            ├── conditions: FilterCondition[]
            └── children: ConditionGroup[]  (max depth 3)
```

---

## State Transitions

### Condition Lifecycle

```
[Empty] -> [Filling] -> [Complete] -> [Validating] -> [Valid] | [Invalid]
                                                      |
                                                      v
                                                   [Removed]
```

### Group Operations

| Operation | Precondition | Postcondition |
|-----------|--------------|---------------|
| Add Condition | Group exists | Condition added to group's conditions array |
| Remove Condition | Condition exists | Condition removed, group remains valid |
| Add Nested Group | Depth < 3 | Child group added to children array |
| Remove Nested Group | Child exists | Child removed |
| Change Connector | Group has multiple items | Connector updated, logic changes |
| Group Conditions | 2+ conditions at same level | New group created containing them |

---

## Persistence Mapping

The FilterTree maps to the existing `segments.segment_data` schema:

| FilterTree Field | Segment Data Field |
|------------------|-------------------|
| rootGroup | filters (list structure) |
| labels | labels (map) |

**Example segment_data:**
```json
{
  "filters": [
    "or", [
      ["and", [
        ["is", "visit:country", ["US"]],
        ["is", "visit:device", ["Mobile"]]
      ]],
      ["is", "visit:country", ["GB"]]
    ]
  ],
  "labels": {
    "0": "US Mobile Users",
    "1": "UK Visitors"
  }
}
```

---

## Validation Rules

1. **Dimension Validation**: Must be a known visitor attribute
2. **Operator Validation**: Must be valid for the dimension type
3. **Value Validation**: Must match expected format (country codes, numeric, etc.)
4. **Depth Validation**: Maximum 3 levels of nesting
5. **Count Validation**: Maximum 20 conditions per segment
6. **Group Validation**: Groups must have at least one condition or child group
