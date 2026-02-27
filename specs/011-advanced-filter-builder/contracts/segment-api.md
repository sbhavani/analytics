# Segment API Contracts

## Overview

This document defines the API contracts for the Advanced Filter Builder feature. These contracts cover the interfaces between the frontend React components and the Phoenix backend.

## 1. Segment CRUD Operations

### Save Segment

**Endpoint**: `POST /api/sites/:site_id/segments`

**Request Body**:
```json
{
  "name": "US Visitors",
  "filter_tree": {
    "version": 1,
    "root": {
      "id": "root-1",
      "operator": "and",
      "children": [
        {
          "id": "cond-1",
          "type": "condition",
          "attribute": "visit:country",
          "operator": "is",
          "value": "US",
          "negated": false
        }
      ]
    }
  }
}
```

**Response** (201 Created):
```json
{
  "id": "seg-uuid-123",
  "name": "US Visitors",
  "site_id": "site-uuid-456",
  "filter_tree": { /* same as input */ },
  "created_at": "2026-02-26T10:00:00Z",
  "updated_at": "2026-02-26T10:00:00Z"
}
```

### List Segments

**Endpoint**: `GET /api/sites/:site_id/segments`

**Response** (200 OK):
```json
{
  "segments": [
    {
      "id": "seg-uuid-123",
      "name": "US Visitors",
      "created_at": "2026-02-26T10:00:00Z",
      "updated_at": "2026-02-26T10:00:00Z"
    }
  ]
}
```

### Get Segment

**Endpoint**: `GET /api/sites/:site_id/segments/:segment_id`

**Response** (200 OK):
```json
{
  "id": "seg-uuid-123",
  "name": "US Visitors",
  "site_id": "site-uuid-456",
  "filter_tree": {
    "version": 1,
    "root": {
      "id": "root-1",
      "operator": "and",
      "children": [...]
    }
  },
  "created_at": "2026-02-26T10:00:00Z",
  "updated_at": "2026-02-26T10:00:00Z"
}
```

### Update Segment

**Endpoint**: `PATCH /api/sites/:site_id/segments/:segment_id`

**Request Body**:
```json
{
  "name": "US and UK Visitors",
  "filter_tree": { /* updated filter tree */ }
}
```

**Response** (200 OK):
```json
{
  "id": "seg-uuid-123",
  "name": "US and UK Visitors",
  "updated_at": "2026-02-26T11:00:00Z"
}
```

### Delete Segment

**Endpoint**: `DELETE /api/sites/:site_id/segments/:segment_id`

**Response**: 204 No Content

### Duplicate Segment

**Endpoint**: `POST /api/sites/:site_id/segments/:segment_id/duplicate`

**Response** (201 Created):
```json
{
  "id": "seg-uuid-new",
  "name": "US Visitors (Copy)",
  "site_id": "site-uuid-456",
  "filter_tree": { /* same as source */ },
  "created_at": "2026-02-26T12:00:00Z",
  "updated_at": "2026-02-26T12:00:00Z"
}
```

## 2. Preview Query

### Get Segment Preview

**Endpoint**: `POST /api/sites/:site_id/segments/preview`

**Request Body**:
```json
{
  "filter_tree": {
    "version": 1,
    "root": {
      "id": "root-1",
      "operator": "and",
      "children": [
        {
          "id": "cond-1",
          "type": "condition",
          "attribute": "visit:country",
          "operator": "is",
          "value": "US",
          "negated": false
        }
      ]
    }
  },
  "metrics": ["visitors", "pageviews"],
  "date_range": {
    "period": "7d",
    "compare_to": "previous_7d"
  }
}
```

**Response** (200 OK):
```json
{
  "results": [
    { "date": "2026-02-20", "visitors": 1500, "pageviews": 3200 },
    { "date": "2026-02-21", "visitors": 1650, "pageviews": 3500 }
  ],
  "totals": {
    "visitors": 11500,
    "pageviews": 24500
  },
  "sample_percent": 100,
  "warnings": []
}
```

## 3. Filter Suggestions

### Get Attribute Values

**Endpoint**: `GET /api/sites/:site_id/filter-suggestions`

**Query Parameters**:
- `filter_attribute`: The attribute to get suggestions for (e.g., "visit:country")
- `q`: Search query for autocomplete

**Response** (200 OK):
```json
{
  "suggestions": [
    { "value": "US", "label": "United States" },
    { "value": "GB", "label": "United Kingdom" }
  ]
}
```

## Error Responses

All endpoints may return:

**400 Bad Request** - Invalid filter configuration
```json
{
  "error": "Invalid filter: unknown attribute 'visit:invalid_property'"
}
```

**404 Not Found** - Segment or site not found
```json
{
  "error": "Segment not found"
}
```

**422 Unprocessable Entity** - Validation error
```json
{
  "error": "Segment name is required"
}
```
