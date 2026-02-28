# API Contract: Segments

This document describes the API contracts for segment operations in the Advanced Filter Builder.

## Overview

The filter builder extends existing segment APIs to support the new filter tree structure while maintaining backward compatibility with legacy filter format.

## Endpoints

### 1. List Segments

Get all saved segments for a site.

**Request**

```
GET /api/{site_domain}/segments
Authorization: Bearer {token}
```

**Response (200)**

```json
{
  "segments": [
    {
      "id": 1,
      "name": "US Visitors",
      "type": "personal",
      "segment_data": {
        "filters": [["is", "country", ["US"]]],
        "labels": { "country": "United States" }
      },
      "inserted_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T10:00:00Z",
      "owner_id": 123,
      "owner_name": "John Doe"
    }
  ]
}
```

---

### 2. Get Single Segment

Get details of a specific segment.

**Request**

```
GET /api/{site_domain}/segments/{segment_id}
Authorization: Bearer {token}
```

**Response (200)**

```json
{
  "id": 1,
  "name": "US Visitors",
  "type": "personal",
  "segment_data": {
    "filters": [["is", "country", ["US"]]],
    "labels": { "country": "United States" }
  },
  "inserted_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T10:00:00Z",
  "owner_id": 123,
  "owner_name": "John Doe"
}
```

---

### 3. Create Segment

Save a new segment with filter configuration.

**Request**

```
POST /api/{site_domain}/segments
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "US Mobile Users",
  "type": "personal",
  "segment_data": {
    "filters": [
      ["is", "country", ["US"]],
      ["is", "device", ["mobile"]]
    ],
    "labels": {
      "country": "United States",
      "device": "Mobile"
    }
  }
}
```

**Response (201)**

```json
{
  "id": 2,
  "name": "US Mobile Users",
  "type": "personal",
  "segment_data": {
    "filters": [
      ["is", "country", ["US"]],
      ["is", "device", ["mobile"]]
    ],
    "labels": {
      "country": "United States",
      "device": "Mobile"
    }
  },
  "inserted_at": "2025-01-20T10:00:00Z",
  "updated_at": "2025-01-20T10:00:00Z",
  "owner_id": 123,
  "owner_name": "John Doe"
}
```

---

### 4. Update Segment

Update an existing segment.

**Request**

```
PUT /api/{site_domain}/segments/{segment_id}
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "Updated Name",
  "segment_data": {
    "filters": [["is", "country", ["US", "DE"]]],
    "labels": { "country": "US, Germany" }
  }
}
```

**Response (200)**

```json
{
  "id": 2,
  "name": "Updated Name",
  "type": "personal",
  "segment_data": {
    "filters": [["is", "country", ["US", "DE"]]],
    "labels": { "country": "US, Germany" }
  },
  "inserted_at": "2025-01-20T10:00:00Z",
  "updated_at": "2025-01-20T11:00:00Z",
  "owner_id": 123,
  "owner_name": "John Doe"
}
```

---

### 5. Delete Segment

Delete a segment.

**Request**

```
DELETE /api/{site_domain}/segments/{segment_id}
Authorization: Bearer {token}
```

**Response (204)**

No content.

---

### 6. Preview Segment

Get visitor count for a filter configuration without saving.

**Request**

```
POST /api/{site_domain}/segments/preview
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "filters": [
    ["is", "country", ["US"]],
    ["is", "browser", ["Chrome"]]
  ],
  "date_range": {
    "period": "7d",
    "from": "2025-01-01",
    "to": "2025-01-07"
  }
}
```

**Response (200)**

```json
{
  "visitor_count": 1523,
  "is_exact": true,
  "sample_percent": 100
}
```

---

## Filter Format

### Legacy Format (Backward Compatible)

```
[operator, dimension, values[]]
```

Examples:
- `["is", "country", ["US", "DE"]]` - Country is US or DE
- ["contains", "page", ["/blog"]] - Page contains /blog
- ["is_not", "device", ["mobile"]] - Device is not mobile

### Operators

| Operator | Filter Value | Description |
|----------|--------------|-------------|
| `is` | array | Equals any of the values |
| `is_not` | array | Does not equal any of the values |
| `contains` | array | Contains the substring |
| `does_not_contain` | array | Does not contain the substring |
| `is_set` | empty | Field is set |
| `is_not_set` | empty | Field is not set |

### Dimensions

| Dimension | Type | Example Values |
|-----------|------|----------------|
| `country` | string | "US", "DE", "GB" |
| `region` | string | "CA", "NY" |
| `city` | string | "San Francisco" |
| `browser` | string | "Chrome", "Firefox" |
| `os` | string | "Windows", "macOS" |
| `device` | string | "desktop", "mobile", "tablet" |
| `screen_size` | string | "large", "medium", "small" |
| `source` | string | "Google", "Twitter" |
| `goal` | string | "Signup", "Purchase" |

---

## Error Responses

### 400 Bad Request

```json
{
  "error": "Invalid filter format",
  "details": {
    "filters": "Invalid operator 'unknown'"
  }
}
```

### 401 Unauthorized

```json
{
  "error": "Unauthorized"
}
```

### 403 Forbidden

```json
{
  "error": "Insufficient permissions"
}
```

### 404 Not Found

```json
{
  "error": "Segment not found"
}
```
