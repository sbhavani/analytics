# API Contracts: Advanced Filter Builder

## Overview

The Advanced Filter Builder extends the existing Segments API to support nested filter groups.

## Endpoints

### Create Segment

Creates a new segment with optional filter group.

**Endpoint**: `POST /api/stats/:site_id/segments`

**Request Body**:
```json
{
  "name": "US Visitors",
  "type": "personal",
  "filters": {
    "operator": "and",
    "children": [
      { "dimension": "country", "operator": "is", "value": "US" }
    ]
  }
}
```

**Response** (201 Created):
```json
{
  "id": "segment_abc123",
  "name": "US Visitors",
  "type": "personal",
  "filters": {
    "operator": "and",
    "children": [
      { "id": "cond_1", "dimension": "country", "operator": "is", "value": "US" }
    ]
  },
  "description": null,
  "created_at": "2026-02-26T10:00:00Z"
}
```

### Update Segment

Updates an existing segment's filters.

**Endpoint**: `PUT /api/stats/:site_id/segments/:segment_id`

**Request Body**:
```json
{
  "name": "US Visitors - Updated",
  "filters": {
    "operator": "or",
    "children": [
      { "id": "cond_1", "dimension": "country", "operator": "is", "value": "US" },
      { "id": "cond_2", "dimension": "country", "operator": "is", "value": "CA" }
    ]
  }
}
```

**Response** (200 OK):
```json
{
  "id": "segment_abc123",
  "name": "US Visitors - Updated",
  "type": "personal",
  "filters": {
    "operator": "or",
    "children": [
      { "id": "cond_1", "dimension": "country", "operator": "is", "value": "US" },
      { "id": "cond_2", "dimension": "country", "operator": "is", "value": "CA" }
    ]
  },
  "updated_at": "2026-02-26T11:00:00Z"
}
```

### List Segments

Retrieves all segments for a site.

**Endpoint**: `GET /api/stats/:site_id/segments`

**Response** (200 OK):
```json
[
  {
    "id": "segment_abc123",
    "name": "US Visitors",
    "type": "personal",
    "filters": { "operator": "and", "children": [...] },
    "description": null,
    "created_at": "2026-02-26T10:00:00Z"
  }
]
```

### Delete Segment

Deletes a segment.

**Endpoint**: `DELETE /api/stats/:site_id/segments/:segment_id`

**Response** (204 No Content)

## Filter Group JSON Structure

The filter group is serialized as JSON with the following structure:

```json
{
  "operator": "and",
  "children": [
    {
      "id": "cond_1",
      "dimension": "country",
      "operator": "is",
      "value": "US"
    },
    {
      "id": "group_1",
      "operator": "or",
      "children": [
        { "id": "cond_2", "dimension": "page", "operator": "contains", "value": "/blog" },
        { "id": "cond_3", "dimension": "source", "operator": "is", "value": "google" }
      ]
    }
  ]
}
```

### Supported Dimensions

- page, entry_page, exit_page
- source, channel, referrer
- country, region, city
- screen, browser, browser_version
- os, os_version
- utm_medium, utm_source, utm_campaign, utm_term, utm_content
- goal, props, hostname

### Supported Operators

- is, is_not
- contains, contains_not
- greater_than, less_than
- between
- has_not_done
