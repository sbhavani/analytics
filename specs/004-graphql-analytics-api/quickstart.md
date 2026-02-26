# Quickstart: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25

## Getting Started

This guide will help you get started with the GraphQL Analytics API.

## Prerequisites

- A Plausible Analytics account
- An API key (generated from your dashboard settings)
- A site ID (from your site settings)

## Making Your First Query

### 1. Find Your Site ID

Navigate to your site settings to find the site ID, or use the site domain as the identifier.

### 2. Generate an API Key

Go to your account settings and generate a new API key with appropriate permissions.

### 3. Make a Request

Send a GraphQL query to the API endpoint:

```bash
curl -X POST https://your-instance.com/api/graphql \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { pageviews(filter: { siteId: \"YOUR_SITE_ID\" }, pagination: { limit: 10 }) { edges { node { url timestamp } } } }"
  }'
```

## Querying Pageviews

Get basic pageview data for your site:

```graphql
query {
  pageviews(
    filter: {
      siteId: "YOUR_SITE_ID"
      dateRange: {
        from: "2026-01-01"
        to: "2026-01-31"
      }
    }
    pagination: { limit: 100 }
  ) {
    edges {
      node {
        url
        timestamp
        browser
        device
        country
      }
    }
  }
}
```

## Querying Events

Get custom event data:

```graphql
query {
  events(
    filter: {
      siteId: "YOUR_SITE_ID"
      eventType: "signup"
    }
  ) {
    edges {
      node {
        name
        timestamp
        properties
      }
    }
  }
}
```

## Using Aggregations

Get daily pageview counts:

```graphql
query {
  pageviewAggregations(
    filter: {
      siteId: "YOUR_SITE_ID"
      dateRange: { from: "2026-01-01", to: "2026-01-31" }
    }
    granularity: DAY
  ) {
    key
    count
  }
}
```

## Filtering

### By URL Pattern (Pageviews)

```graphql
filter: {
  siteId: "YOUR_SITE_ID"
  urlPattern: "/blog/*"
}
```

### By Event Type (Events)

```graphql
filter: {
  siteId: "YOUR_SITE_ID"
  eventType: "button_click"
}
```

### By Metric Name (Custom Metrics)

```graphql
filter: {
  siteId: "YOUR_SITE_ID"
  metricName: "revenue"
}
```

## Pagination

Use cursor-based pagination to navigate through large result sets:

```graphql
pagination: {
  limit: 100
  offset: 0
}
```

## Rate Limiting

The GraphQL API is rate-limited to 100 requests per minute per API key. If you exceed this limit, you'll receive a RATE_LIMITED error.

## Error Handling

The API returns errors in the following format:

```json
{
  "errors": [
    {
      "message": "Error description",
      "path": ["field_name"]
    }
  ]
}
```

Common error codes:
- `UNAUTHENTICATED`: Missing or invalid API key
- `FORBIDDEN`: User does not have access to the requested site
- `NOT_FOUND`: Site does not exist
- `BAD_USER_INPUT`: Invalid filter values or parameters
- `RATE_LIMITED`: Too many requests

## Performance

- Query response time target: < 5 seconds for 90-day ranges
- Aggregation query target: < 10 seconds
- Maximum pagination limit: 1000 records per request

## Next Steps

- Explore the full schema in the API documentation
- Set up integration tests for your queries
- Monitor API usage and performance
