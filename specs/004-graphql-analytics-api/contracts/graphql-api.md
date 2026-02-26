# GraphQL Analytics API Contract

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25

## API Endpoint

```
POST /api/graphql
Content-Type: application/json
Authorization: Bearer <api_key>
```

## Authentication

The API uses Bearer token authentication. Include your API key in the Authorization header:

```bash
curl -X POST https://your-instance.com/api/graphql \
  -H "Authorization: Bearer your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ pageviews(filter: { siteId: \"abc123\" }) { edges { node { url timestamp } } } }"}'
```

## Query Examples

### Query Pageviews

```graphql
query {
  pageviews(
    filter: {
      siteId: "site-uuid",
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
      urlPattern: "/blog/*"
    }
    pagination: { limit: 100, offset: 0 }
  ) {
    edges {
      node {
        id
        timestamp
        url
        referrer
        browser
        device
        country
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### Query Events

```graphql
query {
  events(
    filter: {
      siteId: "site-uuid",
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
      eventType: "signup"
    }
    pagination: { limit: 50 }
  ) {
    edges {
      node {
        id
        timestamp
        name
        properties
        browser
        device
      }
    }
  }
}
```

### Query Custom Metrics

```graphql
query {
  customMetrics(
    filter: {
      siteId: "site-uuid",
      metricName: "revenue"
    }
  ) {
    edges {
      node {
        id
        timestamp
        name
        value
      }
    }
  }
}
```

### Pageview Aggregations

```graphql
query {
  pageviewAggregations(
    filter: {
      siteId: "site-uuid",
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
    }
    granularity: DAY
  ) {
    key
    count
  }
}
```

### Event Aggregations

```graphql
query {
  eventAggregations(
    filter: {
      siteId: "site-uuid",
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
    }
    groupBy: "name"
  ) {
    key
    count
  }
}
```

### Custom Metric Aggregations

```graphql
query {
  customMetricAggregations(
    filter: {
      siteId: "site-uuid",
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
      metricName: "revenue"
    }
  ) {
    key
    sum
    average
    count
  }
}
```

## Response Format

### Success Response

```json
{
  "data": {
    "pageviews": {
      "edges": [
        {
          "node": {
            "id": "pv_abc123",
            "timestamp": "2026-01-15T10:30:00Z",
            "url": "https://example.com/blog/post-1",
            "referrer": "https://google.com",
            "browser": "Chrome",
            "device": "desktop",
            "country": "US"
          }
        }
      ],
      "pageInfo": {
        "hasNextPage": false,
        "endCursor": "cursor_string"
      }
    }
  }
}
```

### Error Response

```json
{
  "errors": [
    {
      "message": "Site not found",
      "locations": [{ "line": 1, "column": 2 }],
      "path": ["pageviews"]
    }
  ]
}
```

## Rate Limits

- 100 requests per minute per API key
- Query complexity limits apply to prevent expensive queries

## Errors

| Error Code | Description |
|------------|-------------|
| UNAUTHENTICATED | Missing or invalid API key |
| FORBIDDEN | User does not have access to the requested site |
| NOT_FOUND | Site does not exist |
| BAD_USER_INPUT | Invalid filter values or parameters |
| INTERNAL_ERROR | Server error |
