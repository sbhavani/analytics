# Data Model: Advanced Filter Builder

## Entities

### FilterCondition

Represents a single filter rule in the builder.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | UUID | Unique identifier | Auto-generated |
| field | String | Visitor attribute to filter on | Required, must be valid field |
| operator | String | Comparison operator | Required, valid operator for field type |
| value | String | Filter value | Required, valid for operator |
| negated | Boolean | Whether condition is negated (NOT) | Default: false |

**Valid Fields** (from ClickHouse sessions_v2):
- `country` - Country code/name
- `region` - Region/state
- `city` - City name
- `device` - Device type (Desktop, Mobile, Tablet)
- `browser` - Browser name
- `os` / `operating_system` - Operating system
- `source` / `referrer_source` - Traffic source
- `utm_medium`, `utm_source`, `utm_campaign`, `utm_content`, `utm_term` - UTM parameters
- `hostname` - Visitor hostname
- `entry_page`, `exit_page` - Page paths
- `pageviews` - Pageview count
- `events` - Event count
- `duration` - Session duration (seconds)
- `is_bounce` - Bounce flag
- `channel` - Traffic channel

**Valid Operators by Field Type**:

| Field Type | Operators |
|------------|-----------|
| String (equals) | `equals`, `does_not_equal`, `contains`, `does_not_contain`, `matches_regex` |
| String (set) | `is_one_of`, `is_not_one_of` |
| Number | `equals`, `not_equals`, `greater_than`, `less_than`, `greater_or_equal`, `less_or_equal` |
| Boolean | `is_true`, `is_false` |

---

### FilterGroup

Represents a collection of conditions with a common logical connector.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| connector | Enum | `AND`, `OR` |
| conditions | Array<FilterCondition> | Child conditions |
| subgroups | Array<FilterGroup> | Nested groups (for complex nesting) |

**Constraints**:
- Maximum nesting depth: 5 levels
- Minimum 1 condition or 1 subgroup in a group

---

### FilterTree

The complete filter structure stored as JSON.

| Field | Type | Description |
|-------|------|-------------|
| root_group | FilterGroup | Top-level group |

**JSON Structure Example**:
```json
{
  "root_group": {
    "id": "uuid",
    "connector": "AND",
    "conditions": [
      {"id": "c1", "field": "country", "operator": "equals", "value": "US", "negated": false}
    ],
    "subgroups": [
      {
        "id": "g1",
        "connector": "OR",
        "conditions": [
          {"id": "c2", "field": "device", "operator": "equals", "value": "Mobile", "negated": false},
          {"id": "c3", "field": "device", "operator": "equals", "value": "Tablet", "negated": false}
        ],
        "subgroups": []
      }
    ]
  }
}
```

---

### FilterTemplate (PostgreSQL)

Saved filter configuration for reuse.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| id | UUID | Unique identifier | Auto-generated |
| site_id | UUID | Owner site | Required, FK to sites |
| name | String | Template name | Required, max 100 chars |
| filter_tree | JSONB | Serialized filter structure | Required, valid JSON |
| inserted_at | DateTime | Creation timestamp | Auto |
| updated_at | DateTime | Last modified | Auto |

**Relationships**:
- Belongs to Site (many templates per site)

---

## State Transitions

### Filter Builder States

```
[Empty] --> [Condition Added] --> [Multiple Conditions] --> [Grouped]
    |           |                      |
    |                      v           v                      v                      v
[Invalid]   [Valid Single]        [Valid Multi]         [Valid Nested]
```

### Validation States

| State | Conditions | Save Allowed |
|-------|------------|--------------|
| Empty | No conditions | No (validation error) |
| Valid | All conditions have valid field/operator/value | Yes |
| Invalid | Any condition missing required fields | No |

---

## Database Schema (PostgreSQL)

```sql
CREATE TABLE filter_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    filter_tree JSONB NOT NULL,
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_filter_templates_site_id ON filter_templates(site_id);
CREATE UNIQUE INDEX idx_filter_templates_site_name ON filter_templates(site_id, name);
```

---

## API Contracts (Summary)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sites/:site_id/filter-templates` | GET | List templates for site |
| `/api/sites/:site_id/filter-templates` | POST | Create new template |
| `/api/sites/:site_id/filter-templates/:id` | GET | Get single template |
| `/api/sites/:site_id/filter-templates/:id` | PUT | Update template |
| `/api/sites/:site_id/filter-templates/:id` | DELETE | Delete template |
| `/api/sites/:site_id/segments/preview` | POST | Get matching visitor count |
