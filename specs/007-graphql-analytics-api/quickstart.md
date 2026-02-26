# Quickstart: GraphQL Analytics API

## Authentication

All GraphQL API requests require an API key passed in the Authorization header:

```bash
curl -X POST https://your-plausible-instance/api/graphql \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ pageviews(site_id: \"example.com\") { url view_count } }"}'
```

## Getting Your API Key

1. Log into your Plausible dashboard
2. Go to Settings > API Keys
3. Create a new API key with appropriate permissions

## Basic Examples

### Query Pageviews

```graphql
query {
  pageviews(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
    limit: 10
  ) {
    url
    visitor_count
    view_count
  }
}
```

### Query Events

```graphql
query {
  events(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
    event_type: "signup"
  ) {
    name
    count
  }
}
```

### Get Aggregated Metrics

```graphql
query {
  pageviews_aggregate(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
    aggregation: {
      type: SUM
      metric: "pageviews"
    }
  ) {
    metric
    value
  }
}
```

### Filter by Device

```graphql
query {
  pageviews(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
      device_type: MOBILE
    }
  ) {
    url
    view_count
  }
}
```

### Time Series Data

```graphql
query {
  pageviews_timeseries(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
    interval: DAY
  ) {
    date
    visitors
    pageviews
  }
}
```

### Query Custom Metrics

```graphql
query {
  custom_metrics(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
  ) {
    name
    value
    formula
  }
}
```

### Combined Analytics Query

```graphql
query {
  analytics(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
    }
    metrics: ["visitors", "pageviews", "events"]
    interval: DAY
  ) {
    date
    visitors
    pageviews
    events
  }
}
```

### Filter by Geography

```graphql
query {
  pageviews(
    site_id: "example.com"
    filter: {
      date_range: {
        start_date: "2026-01-01"
        end_date: "2026-01-31"
      }
      country: "US"
      region: "CA"
      city: "5391959"
    }
  ) {
    url
    visitor_count
  }
}
```

## Rate Limits

- 1000 requests per minute per API key
- Rate limit headers included in response:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Error Responses

### Authentication Error
```json
{
  "errors": [
    { "message": "Invalid or missing API key", "code": "UNAUTHORIZED" }
  ]
}
```

### Rate Limited
```json
{
  "errors": [
    { "message": "Rate limit exceeded. Try again later.", "code": "RATE_LIMITED" }
  ]
}
```

### Invalid Query
```json
{
  "errors": [
    { "message": "Field 'invalid_field' is not defined", "code": "VALIDATION_ERROR" }
  ]
}
```
