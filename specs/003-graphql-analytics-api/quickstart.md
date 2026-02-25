# Quickstart: GraphQL Analytics API

## Overview

The GraphQL Analytics API provides a flexible way to query pageviews, events, and custom metrics from your Plausible analytics data.

## Endpoint

```
POST /api/graphql
Content-Type: application/json
```

## Authentication

All requests require an API key passed in the `Authorization` header:

```bash
curl -X POST https://your-plausible-instance.com/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{"query":"query { pageviews(siteId: \"site-id\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" } }) { url, viewCount } }"}'
```

## Your First Query

### Get Pageview Data

```bash
curl -X POST https://your-plausible-instance.com/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "query": "query { pageviews(siteId: \"your-site-id\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" } }) { url, viewCount, uniqueVisitors } }"
  }'
```

Response:

```json
{
  "data": {
    "pageviews": [
      {
        "url": "https://example.com/",
        "viewCount": 1500,
        "uniqueVisitors": 1200
      },
      {
        "url": "https://example.com/about",
        "viewCount": 450,
        "uniqueVisitors": 380
      }
    ]
  }
}
```

### Get Events with Filtering

```bash
curl -X POST https://your-plausible-instance.com/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "query": "query { events(siteId: \"your-site-id\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" }, eventName: \"signup\" }) { name, count } }"
  }'
```

### Get Custom Metrics with Time Series

```bash
curl -X POST https://your-plausible-instance.com/api/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "query": "query { metrics(siteId: \"your-site-id\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" }, metricNames: [\"revenue\"] }, timeSeries: true, interval: DAY) { name, historical { timestamp, value } } }"
  }'
```

## Filtering

### Date Range (Required)

All queries require a date range:

```graphql
filter: {
  dateRange: {
    from: "2026-01-01",
    to: "2026-01-31"
  }
}
```

### Property Filters

Filter by country, device, or referrer:

```graphql
filter: {
  dateRange: { from: "2026-01-01", to: "2026-01-31" },
  country: "US",
  device: MOBILE
}
```

### Event Property Filters

```graphql
filter: {
  dateRange: { from: "2026-01-01", to: "2026-01-31" },
  eventName: "button_click",
  property: {
    field: "label",
    operator: CONTAINS,
    value: "pricing"
  }
}
```

## Aggregation

Use aggregation to compute values instead of returning raw records:

```graphql
aggregation: {
  type: COUNT
}
```

Available aggregation types: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`

## Pagination

```graphql
pagination: {
  limit: 100,
  offset: 0
}
```

Maximum 10,000 records per query.

## Rate Limits

- 1000 queries per minute per API key
- Responses include rate limit headers

## Errors

Invalid queries return clear error messages:

```json
{
  "errors": [
    {
      "message": "Invalid date range: maximum 1 year allowed",
      "locations": [{ "line": 1, "column": 45 }]
    }
  ]
}
```
