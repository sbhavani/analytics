# Data Model: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-26

## Entities

### FilterCondition

Represents a single filtering rule in the builder UI.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier for the condition |
| dimension | String | Yes | Filter field (e.g., "country", "page_views") |
| operator | String | Yes | Filter operation (e.g., "is", "contains", "greater_than") |
| value | String/Array | Yes | Filter value(s) |

### FilterGroup

Represents a collection of conditions combined with a logical operator.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier for the group |
| operator | Enum | Yes | "and" or "or" - logical combination |
| children | Array | Yes | Array of FilterCondition or nested FilterGroup |

### FilterTemplate

Saved filter configuration for reuse. Extends existing SavedSegment.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| name | String | Yes | User-provided template name |
| type | Enum | Yes | "site" or "personal" |
| filters | JSON | Yes | Serialized filter tree (FilterGroup) |
| description | String | No | Optional description |

## Validation Rules

1. **FilterCondition**
   - dimension: Must be one of supported filter fields
   - operator: Must be valid for the dimension type
   - value: Required unless operator is "is_not" with no value

2. **FilterGroup**
   - operator: Must be "and" or "or"
   - children: Minimum 1 child required

3. **FilterTemplate**
   - name: 1-255 characters, required
   - filters: Must be valid FilterGroup structure
   - type: Required, determines visibility (site-wide vs personal)

## State Transitions

### Filter Builder State Machine

```
[Empty] --add condition--> [Single Condition]
[Single Condition] --add condition--> [Multiple Conditions]
[Multiple Conditions] --group selected--> [Nested Group]
[Nested Group] --change operator--> [Updated Group]
[Any State] --remove condition--> [Updated State]
[Any State] --save template--> [Template Saved]
```

## Relationships

- FilterTemplate 1:N FilterGroup (serialized)
- FilterGroup 1:N FilterCondition (nested)
- FilterGroup can contain nested FilterGroup (recursive)

## API Contracts

### Create Segment (extends existing)

```
POST /api/stats/:site_id/segments
Body: { name, type, filters: { operator: "and", children: [...] } }
Response: { id, name, type, filters, ... }
```

### Update Segment

```
PUT /api/stats/:site_id/segments/:id
Body: { name?, type?, filters? }
Response: { id, name, type, filters, ... }
```

### List Segments

```
GET /api/stats/:site_id/segments
Response: [{ id, name, type, filters, ... }]
```

### Query with Segment

```
GET /api/stats/:site_id/main?segment=<segment_id>
Response: { ... analytics data ... }
```
