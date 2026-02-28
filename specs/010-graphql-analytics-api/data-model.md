# Data Model: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-27

## Entities

### Pageview

Represents a single page view event.

| Field | Type | Description |
|-------|------|-------------|
| url | String | Full URL of the page viewed |
| timestamp | DateTime | When the pageview occurred |
| referrer | String | Traffic source (may be empty) |
| visitorId | String | Anonymous visitor identifier |

**Query Operations**:
- List pageviews with filters
- Aggregate pageview counts

---

### Event

Represents a tracked user interaction.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Event type (e.g., "signup", "click") |
| timestamp | DateTime | When the event occurred |
| properties | JSON | Custom event properties |
| visitorId | String | Anonymous visitor identifier |

**Query Operations**:
- List events with filters
- Aggregate event counts by type

---

### Custom Metric

Represents a user-defined business metric.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Metric identifier |
| value | Float | Metric value |
| timestamp | DateTime | When the metric was recorded |
| dimensions | JSON | Additional grouping dimensions |

**Query Operations**:
- List custom metrics
- Filter by name

---

## Input Types

### DateRangeInput

```graphql
input DateRangeInput {
  from: DateTime!
  to: DateTime!
}
```

### PageviewFilterInput

```graphql
input PageviewFilterInput {
  url: String
  urlPattern: String
  referrer: String
}
```

### EventFilterInput

```graphql
input EventFilterInput {
  name: String
}
```

### MetricFilterInput

```graphql
input MetricFilterInput {
  name: String
}
```

### AggregationInput

```graphql
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
```

---

## Query Types

### RootQuery

```graphql
type Query {
  # Pageview queries
  pageviews(siteId: ID!, filter: PageviewFilterInput, dateRange: DateRangeInput!, limit: Int, offset: Int): [Pageview!]!
  pageviewAggregate(siteId: ID!, filter: PageviewFilterInput, dateRange: DateRangeInput!, aggregation: AggregationInput!): AggregateResult!

  # Event queries
  events(siteId: ID!, filter: EventFilterInput, dateRange: DateRangeInput!, limit: Int, offset: Int): [Event!]!
  eventAggregate(siteId: ID!, filter: EventFilterInput, dateRange: DateRangeInput!, aggregation: AggregationInput!): AggregateResult!

  # Custom metric queries
  customMetrics(siteId: ID!, filter: MetricFilterInput, dateRange: DateRangeInput!): [CustomMetric!]!
  customMetricAggregate(siteId: ID!, filter: MetricFilterInput, dateRange: DateRangeInput!, aggregation: AggregationInput!): AggregateResult!
}

type AggregateResult {
  value: Float!
  type: AggregationType!
}
```

---

## Authorization

All queries require:
1. Valid API key with `analytics:read` scope
2. User must have access to the requested `siteId`

---

## Validation Rules

- Date range cannot exceed 12 months
- Limit defaults to 100, max 1000
- Offset must be non-negative
- Aggregation field must be valid for the entity type
