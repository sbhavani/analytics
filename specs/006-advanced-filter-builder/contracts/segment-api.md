# Segment API Contract

## Overview

The Segment API provides endpoints for creating, managing, and querying visitor segments.

## Endpoints

### List Segments

```
GET /api/sites/:site_id/segments
```

**Response**:
```json
{
  "segments": [
    {
      "id": "uuid",
      "name": "High Value US Users",
      "visitor_count": 1250,
      "created_at": "2026-02-26T10:00:00Z",
      "updated_at": "2026-02-26T10:00:00Z"
    }
  ]
}
```

### Get Segment

```
GET /api/sites/:site_id/segments/:segment_id
```

**Response**:
```json
{
  "id": "uuid",
  "name": "High Value US Users",
  "filter_tree": {
    "operator": "AND",
    "conditions": [
      { "field": "country", "operator": "equals", "value": "US" },
      { "field": "pages_visited", "operator": "greater_than", "value": "5" }
    ],
    "groups": []
  }
}
```

### Create Segment

```
POST /api/sites/:site_id/segments
```

**Request**:
```json
{
  "name": "High Value US Users",
  "filter_tree": {
    "operator": "AND",
    "conditions": [
      { "field": "country", "operator": "equals", "value": "US" },
      { "field": "pages_visited", "operator": "greater_than", "value": "5" }
    ]
  }
}
```

**Response** (201 Created):
```json
{
  "id": "uuid",
  "name": "High Value US Users",
  "visitor_count": 1250,
  "created_at": "2026-02-26T10:00:00Z"
}
```

### Update Segment

```
PUT /api/sites/:site_id/segments/:segment_id
```

**Request**:
```json
{
  "name": "Updated Name",
  "filter_tree": { ... }
}
```

### Delete Segment

```
DELETE /api/sites/:site_id/segments/:segment_id
```

**Response** (204 No Content)

### Preview Segment

```
POST /api/sites/:site_id/segments/preview
```

**Request**:
```json
{
  "filter_tree": {
    "operator": "AND",
    "conditions": [
      { "field": "country", "operator": "equals", "value": "US" }
    ]
  }
}
```

**Response**:
```json
{
  "visitor_count": 12500,
  "sample_visitors": []
}
```

## Error Responses

All endpoints may return:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Segment name is required",
    "details": { "field": "name" }
  }
}
```

**Error Codes**:
- `VALIDATION_ERROR`: Invalid input
- `NOT_FOUND`: Segment not found
- `UNAUTHORIZED`: User does not have access
- `RATE_LIMITED`: Too many requests
