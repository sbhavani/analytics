# GraphQL API Contract

## Endpoint

```
POST /api/graphql
```

## Authentication

All requests require a Bearer token in the Authorization header:

```
Authorization: Bearer <your-api-key>
```

## Headers

| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes | Bearer token with API key |
| Content-Type | Yes | Must be `application/json` |

## Request Format

```json
{
  "query": "query string",
  "operationName": "optional operation name",
  "variables": { "variable": "values" }
}
```

## Response Format

### Success Response

```json
{
  "data": {
    "pageviews": { ... }
  }
}
```

### Error Response

```json
{
  "errors": [
    {
      "message": "Error description",
      "locations": [{ "line": 1, "column": 1 }],
      "path": ["fieldName"]
    }
  ]
}
```

## Example Queries

### Query 1: Get Pageviews

```graphql
query GetPageviews($siteId: String!, $dateRange: DateRangeInput!) {
  pageviews(site_id: $siteId, date_range: $dateRange) {
    data {
      url_path
      timestamp
      referrer
      country
      device
    }
    pagination {
      limit
      offset
      has_more
      total
    }
  }
}
```

Variables:
```json
{
  "siteId": "example.com",
  "dateRange": {
    "start_date": "2026-01-01",
    "end_date": "2026-01-31"
  }
}
```

### Query 2: Get Events with Aggregation

```graphql
query GetEvents($siteId: String!, $dateRange: DateRangeInput!) {
  events(
    site_id: $siteId
    date_range: $dateRange
    filters: { event_name: "cta_click" }
    aggregation: { function: COUNT, granularity: DAY }
  ) {
    data {
      name
      timestamp
      properties
    }
    pagination {
      total
    }
  }
}
```

### Query 3: Get Custom Metrics

```graphql
query GetMetrics($siteId: String!, $dateRange: DateRangeInput!) {
  metrics(
    site_id: $siteId
    date_range: $dateRange
    filters: { metric_name: "revenue" }
    aggregation: { function: SUM }
  ) {
    aggregated
    data {
      name
      value
      timestamp
    }
  }
}
```

### Query 4: Combined Query

```graphql
query GetAnalytics($siteId: String!, $dateRange: DateRangeInput!) {
  pageviews(site_id: $siteId, date_range: $dateRange, pagination: { limit: 10 }) {
    total
    data {
      url_path
      timestamp
    }
  }
  events(site_id: $siteId, date_range: $dateRange) {
    total
  }
  metrics(site_id: $siteId, date_range: $dateRange, filters: { metric_name: "conversion_rate" }) {
    aggregated
  }
}
```

## Rate Limits

- **Default**: 600 requests per hour per API key
- **Burst**: 60 requests per 10 seconds
- Rate limit headers returned in response:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Requests remaining in window
  - `X-RateLimit-Reset`: Unix timestamp when window resets

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INVALID_DATE_RANGE | 400 | Date range exceeds 366 days |
| INVALID_FILTER | 400 | Filter criteria malformed |
| INVALID_AGGREGATION | 400 | Unsupported aggregation |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| UNAUTHORIZED | 401 | Invalid or missing API key |
| NOT_FOUND | 404 | Site not found |
