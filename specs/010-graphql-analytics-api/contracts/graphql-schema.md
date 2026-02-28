# GraphQL Analytics API Contract

**Version**: 1.0.0
**Date**: 2026-02-27

## Endpoint

```
POST /api/graphql
Content-Type: application/json
Authorization: Bearer <api_key>
```

## Schema

```graphql
scalar DateTime
scalar JSON

input DateRangeInput {
  from: DateTime!
  to: DateTime!
}

input PageviewFilterInput {
  url: String
  urlPattern: String
  referrer: String
}

input EventFilterInput {
  name: String
}

input MetricFilterInput {
  name: String
}

input AggregationInput {
  type: AggregationType!
  field: String
}

enum AggregationType {
  COUNT
  SUM
  AVG
  MIN
  MAX
}

type Pageview {
  url: String!
  timestamp: DateTime!
  referrer: String
  visitorId: String!
}

type Event {
  name: String!
  timestamp: DateTime!
  properties: JSON
  visitorId: String!
}

type CustomMetric {
  name: String!
  value: Float!
  timestamp: DateTime!
  dimensions: JSON
}

type AggregateResult {
  value: Float!
  type: AggregationType!
}

type Query {
  # Pageview queries
  pageviews(
    siteId: ID!,
    filter: PageviewFilterInput,
    dateRange: DateRangeInput!,
    limit: Int = 100,
    offset: Int = 0
  ): [Pageview!]!

  pageviewAggregate(
    siteId: ID!,
    filter: PageviewFilterInput,
    dateRange: DateRangeInput!,
    aggregation: AggregationInput!
  ): AggregateResult!

  # Event queries
  events(
    siteId: ID!,
    filter: EventFilterInput,
    dateRange: DateRangeInput!,
    limit: Int = 100,
    offset: Int = 0
  ): [Event!]!

  eventAggregate(
    siteId: ID!,
    filter: EventFilterInput,
    dateRange: DateRangeInput!,
    aggregation: AggregationInput!
  ): AggregateResult!

  # Custom metric queries
  customMetrics(
    siteId: ID!,
    filter: MetricFilterInput,
    dateRange: DateRangeInput!
  ): [CustomMetric!]!

  customMetricAggregate(
    siteId: ID!,
    filter: MetricFilterInput,
    dateRange: DateRangeInput!,
    aggregation: AggregationInput!
  ): AggregateResult!
}
```

## Example Queries

### Get pageview counts for last 30 days

```json
{
  "query": "query { pageviewAggregate(siteId: \"site-123\", dateRange: {from: \"2026-01-28T00:00:00Z\", to: \"2026-02-27T23:59:59Z\"}, aggregation: {type: COUNT}) { value } }"
}
```

### Get events by type

```json
{
  "query": "query { events(siteId: \"site-123\", filter: {name: \"signup\"}, dateRange: {from: \"2026-01-01T00:00:00Z\", to: \"2026-01-31T23:59:59Z\"}) { name timestamp } }"
}
```

### Get aggregated custom metrics

```json
{
  "query": "query { customMetricAggregate(siteId: \"site-123\", dateRange: {from: \"2026-01-01T00:00:00Z\", to: \"2026-01-31T23:59:59Z\"}, aggregation: {type: SUM, field: \"value\"}) { value type } }"
}
```

## Error Responses

### Authentication Error

```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "locations": [{"line": 1, "column": 1}],
      "path": ["pageviews"]
    }
  ]
}
```

### Validation Error

```json
{
  "errors": [
    {
      "message": "Validation error: date range cannot exceed 12 months",
      "locations": [{"line": 1, "column": 50}],
      "path": ["pageviews"]
    }
  ]
}
```

### Authorization Error

```json
{
  "errors": [
    {
      "message": "Access denied to site: site-123",
      "locations": [{"line": 1, "column": 1}],
      "path": ["pageviews"]
    }
  ]
}
```
