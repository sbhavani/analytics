# GraphQL Analytics API - Quick Start Guide

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25
**Phase**: 1 - Design

---

## Overview

The GraphQL Analytics API provides a flexible way to query analytics data (pageviews, events, custom metrics) with support for filtering, aggregation, and pagination.

---

## Making Your First Request

### 1. Endpoint

```
POST https://your-instance.com/api/graphql
```

### 2. Authentication

Include your API key in the Authorization header:

```bash
curl -X POST https://your-instance.com/api/graphql \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { pageviews(siteId: \"example.com\", dateRange: {from: \"2024-01-01\", to: \"2024-01-31\"}) { edges { node { url visitors } } } }"}'
```

### 3. Date Format

Use ISO 8601 format for dates: `YYYY-MM-DD`

---

## Example Queries

### Get Pageviews

```graphql
query {
  pageviews(
    siteId: "example.com",
    dateRange: { from: "2024-01-01", to: "2024-01-31" }
  ) {
    edges {
      node {
        url
        title
        visitors
        timestamp
      }
    }
    totalCount
  }
}
```

### Get Events with Filters

```graphql
query {
  events(
    siteId: "example.com",
    dateRange: { from: "2024-01-01", to: "2024-01-31" },
    filter: { category: "signup" }
  ) {
    edges {
      node {
        name
        category
        timestamp
        visitors
      }
    }
  }
}
```

### Get Aggregate Metrics

```graphql
query {
  aggregate(
    siteId: "example.com",
    dateRange: { from: "2024-01-01", to: "2024-01-31" },
    metrics: ["visitors", "pageviews", "bounce_rate"]
  ) {
    visitors
    pageviews
    bounceRate
  }
}
```

### Get Timeseries Data

```graphql
query {
  timeseries(
    siteId: "example.com",
    dateRange: { from: "2024-01-01", to: "2024-01-31" },
    metrics: ["visitors", "pageviews"],
    interval: DAY
  ) {
    data {
      date
      visitors
      pageviews
    }
  }
}
```

### Pagination

```graphql
query {
  pageviews(
    siteId: "example.com",
    dateRange "2024-: { from:01-01", to: "2024-01-31" },
    pagination: { first: 20, after: "cursor_from_previous_request" }
  ) {
    edges {
      cursor
      node {
        url
        visitors
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

---

## Available Metrics

| Metric | Description |
|--------|-------------|
| `visitors` | Unique visitors |
| `pageviews` | Total page views |
| `events` | Total events |
| `bounce_rate` | Bounce rate percentage |
| `visit_duration` | Average visit duration in seconds |
| `views_per_visit` | Average page views per visit |

---

## Filtering

### Pageview Filters

- `urlPattern`: Filter by URL pattern (supports wildcards)
- `title`: Filter by page title

### Event Filters

- `name`: Filter by event name
- `category`: Filter by event category

---

## Pagination

The API uses cursor-based pagination:

- `first`: Number of items to return (max 1000)
- `after`: Cursor from previous request

Response includes:
- `pageInfo.hasNextPage`: Whether more pages exist
- `pageInfo.endCursor`: Cursor for next page
- `totalCount`: Total items matching query

---

## Error Handling

### Successful Response

```json
{
  "data": {
    "pageviews": {
      "edges": [...],
      "totalCount": 150
    }
  }
}
```

### Error Response

```json
{
  "errors": [
    {
      "message": "Invalid date range",
      "locations": [{ "line": 2, "column": 3 }]
    }
  ]
}
```

### Empty Data (No Matching Results)

```json
{
  "data": {
    "pageviews": {
      "edges": [],
      "totalCount": 0
    }
  }
}
```

---

## Rate Limits

- Standard rate limits apply (same as REST API)
- Query complexity analysis prevents expensive queries

---

## Next Steps

- See [Schema Contract](./contracts/schema.graphql) for complete type definitions
- See [Data Model](./data-model.md) for detailed type documentation
