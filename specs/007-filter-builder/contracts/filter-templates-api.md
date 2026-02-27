# Filter Templates API Contract

## Overview

REST API endpoints for managing filter templates. All endpoints require authentication and site ownership.

## Base Path

```
/api/v1/sites/:site_id/filter-templates
```

## Common Headers

| Header | Required | Value |
|--------|----------|-------|
| Authorization | Yes | Bearer token |
| Content-Type | Yes | application/json |

---

## Endpoints

### List Filter Templates

**GET** `/api/v1/sites/:site_id/filter-templates`

**Response** (200 OK):
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "US Mobile Users",
      "filter_tree": { ... },
      "inserted_at": "2026-02-27T10:00:00Z",
      "updated_at": "2026-02-27T10:00:00Z"
    }
  ]
}
```

---

### Create Filter Template

**POST** `/api/v1/sites/:site_id/filter-templates`

**Request Body**:
```json
{
  "name": "US Mobile Users",
  "filter_tree": {
    "root_group": {
      "id": "uuid",
      "connector": "AND",
      "conditions": [
        {"id": "c1", "field": "country", "operator": "equals", "value": "US", "negated": false}
      ],
      "subgroups": []
    }
  }
}
```

**Validation**:
- `name`: Required, string, max 100 characters
- `filter_tree`: Required, valid JSON matching FilterTree schema

**Response** (201 Created):
```json
{
  "data": {
    "id": "uuid",
    "name": "US Mobile Users",
    "filter_tree": { ... },
    "inserted_at": "2026-02-27T10:00:00Z",
    "updated_at": "2026-02-27T10:00:00Z"
  }
}
```

**Errors**:
- 400: Invalid request body
- 409: Template name already exists for this site

---

### Get Filter Template

**GET** `/api/v1/sites/:site_id/filter-templates/:id`

**Response** (200 OK):
```json
{
  "data": {
    "id": "uuid",
    "name": "US Mobile Users",
    "filter_tree": { ... },
    "inserted_at": "2026-02-27T10:00:00Z",
    "updated_at": "2026-02-27T10:00:00Z"
  }
}
```

**Errors**:
- 404: Template not found

---

### Update Filter Template

**PUT** `/api/v1/sites/:site_id/filter-templates/:id`

**Request Body**:
```json
{
  "name": "Updated Name",
  "filter_tree": { ... }
}
```

All fields are optional. Only provided fields are updated.

**Response** (200 OK):
```json
{
  "data": {
    "id": "uuid",
    "name": "Updated Name",
    "filter_tree": { ... },
    "inserted_at": "2026-02-27T10:00:00Z",
    "updated_at": "2026-02-27T11:00:00Z"
  }
}
```

---

### Delete Filter Template

**DELETE** `/api/v1/sites/:site_id/filter-templates/:id`

**Response** (204 No Content)

**Errors**:
- 404: Template not found

---

## Filter Preview API

### Get Matching Visitor Count

**POST** `/api/v1/sites/:site_id/segments/preview`

**Request Body**:
```json
{
  "filter_tree": {
    "root_group": {
      "id": "uuid",
      "connector": "AND",
      "conditions": [
        {"id": "c1", "field": "country", "operator": "equals", "value": "US", "negated": false}
      ],
      "subgroups": []
    }
  },
  "date_range": {
    "period": "month",
    "from": "2026-01-01",
    "to": "2026-01-31"
  }
}
```

**Response** (200 OK):
```json
{
  "matching_visitors": 1234,
  "total_visitors": 5000,
  "percentage": 24.68
}
```

**Performance Requirement**: Response within 2 seconds per SC-004.
