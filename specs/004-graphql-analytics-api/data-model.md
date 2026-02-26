# Data Model: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25
**Phase**: 1 - Design

## GraphQL Schema Overview

The GraphQL API exposes analytics data through queries for pageviews, events, and custom metrics with support for filtering and aggregation.

## Types

### Query Types

```graphql
type Query {
  # Pageview queries
  pageviews(filter: PageviewFilter, pagination: Pagination): PageviewConnection!
  pageviewAggregations(filter: PageviewFilter, granularity: TimeGranularity): [AggregationResult!]!

  # Event queries
  events(filter: EventFilter, pagination: Pagination): EventConnection!
  eventAggregations(filter: EventFilter, groupBy: String): [AggregationResult!]!

  # Custom metrics queries
  customMetrics(filter: CustomMetricFilter, pagination: Pagination): CustomMetricConnection!
  customMetricAggregations(filter: CustomMetricFilter): [AggregationResult!]!
}
```

### Object Types

#### Pageview

| Field | Type | Description |
|-------|------|-------------|
| id | ID! | Unique identifier |
| timestamp | DateTime! | When the pageview occurred |
| url | String! | Page URL that was viewed |
| referrer | String | Referring URL (optional) |
| browser | String | Browser name |
| device | String | Device type (desktop/mobile/tablet) |
| country | String | Country code |

#### Event

| Field | Type | Description |
|-------|------|-------------|
| id | ID! | Unique identifier |
| timestamp | DateTime! | When the event occurred |
| name | String! | Event name |
| properties | JSON | Event properties (key-value) |
| browser | String | Browser name |
| device | String | Device type |
| country | String | Country code |

#### CustomMetric

| Field | Type | Description |
|-------|------|-------------|
| id | ID! | Unique identifier |
| timestamp | DateTime! | When the metric was recorded |
| name | String! | Metric name |
| value | Float! | Metric value |
| siteId | ID! | Associated site |

#### AggregationResult

| Field | Type | Description |
|-------|------|-------------|
| key | String | Grouping key (date, event type, metric name) |
| count | Int | Count aggregation |
| sum | Float | Sum aggregation |
| average | Float | Average aggregation |

### Input Types (Filters)

#### PageviewFilter

| Field | Type | Description |
|-------|------|-------------|
| siteId | ID! | Required - Site to query |
| dateRange | DateRange | Filter by date range |
| urlPattern | String | Filter by URL pattern (glob) |

#### EventFilter

| Field | Type | Description |
|-------|------|-------------|
| siteId | ID! | Required - Site to query |
| dateRange | DateRange | Filter by date range |
| eventType | String | Filter by event name |

#### CustomMetricFilter

| Field | Type | Description |
|-------|------|-------------|
| siteId | ID! | Required - Site to query |
| dateRange | DateRange | Filter by date range |
| metricName | String | Filter by metric name |

#### DateRange

| Field | Type | Description |
|-------|------|-------------|
| from | Date! | Start date |
| to | Date! | End date |

#### Pagination

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| limit | Int | 100 | Max records (max 1000) |
| offset | Int | 0 | Record offset |

#### TimeGranularity

| Value | Description |
|-------|-------------|
| hour | Group by hour |
| day | Group by day |
| week | Group by week |
| month | Group by month |

## Relationships

- Site has many Pageviews (via site_id)
- Site has many Events (via site_id)
- Site has many CustomMetrics (via site_id)
- All analytics entities are filtered by authenticated user's site access

## Validation Rules

- `siteId` is required on all queries
- Date range cannot exceed 1 year
- Pagination limit max: 1000
- Aggregations require at least one metric function request
