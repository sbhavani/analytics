# Quickstart: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Branch**: 009-graphql-analytics-api
**Date**: 2026-02-26

## Overview

The GraphQL Analytics API provides programmatic access to your analytics data using a flexible query language. Instead of multiple REST endpoints, you can request exactly the data you need in a single query.

## Quick Start

### 1. Get Your API Key

Generate an API key from your Plausible dashboard under **Settings > API Keys**.

### 2. Make Your First Query

```bash
curl -X POST https://your-plausible-instance/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "query": "query { aggregate(siteId: \"your-site-id\", input: { metrics: [VISITORS, PAGEVIEWS], dateRange: { startDate: \"2026-01-01\", endDate: \"2026-01-31\" } }) { visitors pageviews } }"
  }'
```

### 3. Example Responses

**Aggregate Response:**
```json
{
  "data": {
    "aggregate": {
      "visitors": 15420,
      "pageviews": 42850
    }
  }
}
```

**Time Series Response:**
```json
{
  "data": {
    "timeseries": [
      { "date": "2026-01-01", "visitors": 450 },
      { "date": "2026-01-02", "visitors": 520 }
    ]
  }
}
```

## Common Queries

### Get Top Countries
```graphql
query {
  breakdown(
    siteId: "your-site-id",
    input: {
      dimension: COUNTRY,
      metrics: [VISITORS],
      dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
      limit: 10
    }
  ) {
    dimension
    visitors
  }
}
```

### Get Daily Trends
```graphql
query {
  timeseries(
    siteId: "your-site-id",
    input: {
      metrics: [VISITORS, PAGEVIEWS],
      dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
      granularity: DAILY
    }
  ) {
    date
    visitors
    pageviews
  }
}
```

### Filter by Device
```graphql
query {
  aggregate(
    siteId: "your-site-id",
    input: {
      metrics: [VISITORS],
      dateRange: { startDate: "2026-01-01", endDate: "2026-01-31" },
      filters: [{ device: "Desktop" }]
    }
  ) {
    visitors
  }
}
```

## Rate Limits

- **100 requests per minute** per API key
- Rate limit headers are included in responses:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Unix timestamp when limit resets

## Error Handling

| Error | Code | Description |
|-------|------|-------------|
| Unauthorized | `UNAUTHORIZED` | Invalid or missing API key |
| Not Found | `NOT_FOUND` | Site does not exist |
| Validation Error | `VALIDATION_ERROR` | Invalid query or parameters |
| Rate Limited | `RATE_LIMITED` | Too many requests |

## Next Steps

- See [contracts/graphql-api.md](./contracts/graphql-api.md) for full schema
- See [data-model.md](./data-model.md) for entity definitions
- See [research.md](./research.md) for implementation decisions
