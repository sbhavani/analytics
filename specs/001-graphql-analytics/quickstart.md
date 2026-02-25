# Quickstart: GraphQL Analytics API

## Prerequisites

- A Plausible Analytics account
- An API key with `stats:read:*` scope

## Step 1: Get Your API Key

1. Log in to your Plausible dashboard
2. Go to Settings > API Keys
3. Create a new API key (copy it immediately - it won't be shown again)

## Step 2: Make Your First Query

### Using cURL

```bash
curl -X POST https://your-plausible-domain.com/api/graphql \
  -H "Authorization: Bearer YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { pageviews(site_id: \"your-site.com\", date_range: { start_date: \"2026-01-01\", end_date: \"2026-01-31\" }) { total data { url_path timestamp } } }"
  }'
```

### Using GraphQL Client

**Introspection**: The API supports GraphQL introspection - you can explore the schema using tools like GraphiQL or Apollo Studio.

## Step 3: Explore Available Queries

### Query Pageviews

Get pageview counts for your site:

```graphql
query {
  pageviews(
    site_id: "your-site.com"
    date_range: {
      start_date: "2026-01-01"
      end_date: "2026-01-31"
    }
  ) {
    total
    data {
      url_path
      timestamp
      referrer
      country
      device
    }
  }
}
```

### Query Events

Get custom events:

```graphql
query {
  events(
    site_id: "your-site.com"
    date_range: {
      start_date: "2026-01-01"
      end_date: "2026-01-31"
    }
    filters: {
      event_name: "signup"
    }
  ) {
    total
    data {
      name
      timestamp
      properties
    }
  }
}
```

### Query Custom Metrics

Get aggregated custom metrics:

```graphql
query {
  metrics(
    site_id: "your-site.com"
    date_range: {
      start_date: "2026-01-01"
      end_date: "2026-01-31"
    }
    filters: {
      metric_name: "revenue"
    }
    aggregation: {
      function: SUM
    }
  ) {
    aggregated
  }
}
```

## Common Use Cases

### Get Top Pages

```graphql
query {
  pageviews(
    site_id: "your-site.com"
    date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
    aggregation: { function: COUNT }
  ) {
    data {
      url_path
    }
  }
}
```

### Filter by Device Type

```graphql
query {
  pageviews(
    site_id: "your-site.com"
    date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
    filters: { device: "mobile" }
  ) {
    total
  }
}
```

### Time-Based Aggregation

```graphql
query {
  pageviews(
    site_id: "your-site.com"
    date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
    aggregation: { function: COUNT, granularity: DAY }
  ) {
    data {
      timestamp
    }
  }
}
```

## Pagination

```graphql
query {
  pageviews(
    site_id: "your-site.com"
    date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
    pagination: { limit: 50, offset: 0 }
  ) {
    data { url_path }
    pagination {
      limit
      offset
      has_more
      total
    }
  }
}
```

## Troubleshooting

### 401 Unauthorized
- Check your API key is correct and has `stats:read:*` scope
- Ensure the `Authorization` header uses `Bearer` prefix

### 404 Not Found
- Verify the `site_id` matches your site's domain exactly

### Rate Limited (429)
- Wait before retrying
- Check `X-RateLimit-Reset` header for when to retry

### Empty Results
- Verify the date range contains data
- Check if filters match existing data patterns
