# Quickstart: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-27

## Overview

The GraphQL Analytics API provides programmatic access to your analytics data including pageviews, events, and custom metrics. It offers more flexibility than the REST API by allowing you to request exactly the data you need.

## Authentication

All requests require an API key passed in the Authorization header:

```bash
curl -X POST https://your-instance.com/api/graphql \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { pageviewAggregate(siteId: \"site-123\", dateRange: {from: \"2026-01-28T00:00:00Z\", to: \"2026-02-27T23:59:59Z\"}, aggregation: {type: COUNT}) { value } }"}'
```

## Getting Your API Key

1. Log into your Plausible dashboard
2. Go to Settings > API Keys
3. Create a new API key with `analytics:read` scope

## Quick Examples

### 1. Get Total Pageviews

```graphql
query {
  pageviewAggregate(
    siteId: "your-site-id",
    dateRange: {
      from: "2026-01-28T00:00:00Z",
      to: "2026-02-27T23:59:59Z"
    },
    aggregation: { type: COUNT }
  ) {
    value
  }
}
```

### 2. Get Events by Type

```graphql
query {
  events(
    siteId: "your-site-id",
    filter: { name: "signup" },
    dateRange: {
      from: "2026-01-01T00:00:00Z",
      to: "2026-01-31T23:59:59Z"
    },
    limit: 10
  ) {
    name
    timestamp
    properties
  }
}
```

### 3. Get Custom Metrics Sum

```graphql
query {
  customMetricAggregate(
    siteId: "your-site-id",
    filter: { name: "revenue" },
    dateRange: {
      from: "2026-01-01T00:00:00Z",
      to: "2026-01-31T23:59:59Z"
    },
    aggregation: { type: SUM, field: "value" }
  ) {
    value
    type
  }
}
```

### 4. Filter by Multiple Criteria

```graphql
query {
  pageviews(
    siteId: "your-site-id",
    filter: {
      urlPattern: "/blog/*",
      referrer: "google.com"
    },
    dateRange: {
      from: "2026-01-01T00:00:00Z",
      to: "2026-01-31T23:59:59Z"
    },
    limit: 50
  ) {
    url
    timestamp
    referrer
  }
}
```

## Pagination

For queries that return lists, use `limit` and `offset`:

- Default limit: 100
- Maximum limit: 1000

```graphql
query {
  pageviews(
    siteId: "your-site-id",
    dateRange: { from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z" },
    limit: 100,
    offset: 0
  ) {
    url
    timestamp
  }
}
```

## Error Handling

The API returns errors in the standard GraphQL format:

```json
{
  "errors": [
    {
      "message": "Error description",
      "locations": [{ "line": 1, "column": 1 }],
      "path": ["queryName"]
    }
  ]
}
```

Common error codes:
- `401 Unauthorized` - Invalid or missing API key
- `403 Forbidden` - API key doesn't have required scope
- `400 Bad Request` - Invalid query or parameters

## Limits

- Date range: Maximum 12 months
- Rate limit: 100 requests per minute
- Result limit: Maximum 1000 records per query

## Need Help?

- Documentation: [docs.plausible.io]
- Support: [support@plausible.io]
