# Data Model: Advanced Filter Builder

## Entities

### Filter Condition

Represents a single filter rule in the builder.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | UUID | Unique identifier | Auto-generated |
| field | String | Filter field name | Required, must be valid field |
| operator | String | Comparison operator | Required, must be valid operator |
| value | String | Filter value | Required for non-empty operators |
| group_id | UUID | Parent filter group | Foreign key to Filter Group |

**Valid Operators**: equals, not_equals, greater_than, less_than, contains, is_empty, is_not_empty

### Filter Group

Represents a collection of conditions or nested groups with a logical operator.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | UUID | Unique identifier | Auto-generated |
| operator | String | AND or OR | Required, must be AND or OR |
| parent_group_id | UUID | Parent group (for nesting) | Nullable for root groups |
| segment_id | UUID | Parent segment | Foreign key to Visitor Segment |
| sort_order | Integer | Display order | Auto-increment |

### Visitor Segment

Represents a saved filter configuration.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | UUID | Unique identifier | Auto-generated |
| name | String | Segment display name | Required, max 100 chars |
| site_id | UUID | Owning site | Foreign key to Site |
| root_group_id | UUID | Top-level filter group | Foreign key to Filter Group |
| created_at | DateTime | Creation timestamp | Auto-set |
| updated_at | DateTime | Last update timestamp | Auto-set |

### Filter Field

Represents an available visitor attribute for filtering.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Field identifier (e.g., "country") |
| display_name | String | Human-readable name (e.g., "Country") |
| data_type | String | Value type (string, number, date) |
| available_operators | String[] | Valid operators for this field |

**Predefined Fields**:

- country (string): Country
- pages_visited (number): Pages Visited
- session_duration (number): Session Duration (seconds)
- total_spent (number): Total Spent
- device_type (string): Device Type
- referrer_source (string): Referrer Source

## Relationships

```
VisitorSegment (1) ---> (N) FilterGroup
FilterGroup (1) ---> (N) FilterCondition
FilterGroup (1) ---> (N) FilterGroup (nested)
```

## State Transitions

| State | Transition | Trigger |
|-------|------------|---------|
| Empty Builder | Add Condition | User clicks "Add Condition" |
| Single Condition | Add Another | User clicks "Add Condition" |
| Multiple Conditions | Change Connector | User toggles AND/OR |
| Flat Group | Create Nested | User drags condition to group |
| Nested Group | Flatten | User removes parent group |

## Validation Rules

1. At least one condition required to save segment
2. Condition value required unless operator is is_empty/is_not_empty
3. Maximum 10 conditions per segment
4. Maximum 3 nesting levels
5. Segment name required and must be unique per site

## Database Schema (PostgreSQL)

```sql
-- segments table
CREATE TABLE segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL REFERENCES sites(id),
  name VARCHAR(100) NOT NULL,
  root_group_id UUID REFERENCES filter_groups(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- filter_groups table
CREATE TABLE filter_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  segment_id UUID REFERENCES segments(id) ON DELETE CASCADE,
  parent_group_id UUID REFERENCES filter_groups(id),
  operator VARCHAR(3) NOT NULL CHECK (operator IN ('AND', 'OR')),
  sort_order INTEGER DEFAULT 0
);

-- filter_conditions table
CREATE TABLE filter_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES filter_groups(id) ON DELETE CASCADE,
  field VARCHAR(50) NOT NULL,
  operator VARCHAR(20) NOT NULL,
  value TEXT
);
```
