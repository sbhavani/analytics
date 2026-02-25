# Data Model: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25
**Phase**: 1 - Design

## Overview

This document defines the GraphQL schema types for exposing analytics data. The schema is designed to provide flexible querying capabilities while reusing existing Plausible stats infrastructure.

---

## GraphQL Types

### Core Types

#### Pageview

Represents a single page view record.

```graphql
type Pageview {
  url: String!
  title: String
  visitors: Int!
  viewsPerVisit: Float
  bounceRate: Float
  timestamp: DateTime!
}
```

#### Event

Represents a custom user interaction event.

```graphql
type Event {
  name: String!
  category: String
  timestamp: DateTime!
  properties: JSON
  visitors: Int!
  events: Int!
}
```

#### CustomMetric

Represents a business-specific measurement.

```graphql
type CustomMetric {
  name: String!
  value: Float!
  previousValue: Float
  change: Float
  historicalValues: [MetricDataPoint!]
}

type MetricDataPoint {
  timestamp: DateTime!
  value: Float!
}
```

---

### Input Types

#### DateRangeInput

Filter for date-based queries.

```graphql
input DateRangeInput {
  from: String!  # ISO 8601 date: "2024-01-01"
  to: String!    # ISO 8601 date: "2024-01-31"
}
```

#### PageviewFilter

Filter criteria for pageview queries.

```graphql
input PageviewFilter {
  urlPattern: String
  title: String
}
```

#### EventFilter

Filter criteria for event queries.

```graphql
input EventFilter {
  name: String
  category: String
}
```

#### AggregationInput

Aggregation specification.

```graphql
input AggregationInput {
  type: AggregationType!
  metric: String!
  groupBy: String
}

enum AggregationType {
  COUNT
  SUM
  AVERAGE
  MIN
  MAX
}
```

#### PaginationInput

Cursor-based pagination.

```graphql
input PaginationInput {
  first: Int
  after: String    # Cursor
  last: Int
  before: String   # Cursor
}
```

---

### Connection Types

For cursor-based pagination, each list type uses the Relay connection pattern:

```graphql
type PageviewConnection {
  edges: [PageviewEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PageviewEdge {
  node: Pageview!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

---

### Query Types

#### Root Query

```graphql
type Query {
  # Pageview queries
  pageviews(
    siteId: String!,
    dateRange: DateRangeInput!,
    filter: PageviewFilter,
    pagination: PaginationInput,
    sort: [SortInput!]
  ): PageviewConnection!

  # Event queries
  events(
    siteId: String!,
    dateRange: DateRangeInput!,
    filter: EventFilter,
    pagination: PaginationInput
  ): EventConnection!

  # Custom metrics queries
  customMetrics(
    siteId: String!,
    dateRange: DateRangeInput
  ): [CustomMetric!]!

  # Aggregation queries
  aggregate(
    siteId: String!,
    dateRange: DateRangeInput!,
    metrics: [String!]!,
    filter: EventFilter
  ): AggregateResult!

  # Time series
  timeseries(
    siteId: String!,
    dateRange: DateRangeInput!,
    metrics: [String!]!,
    interval: TimeInterval
  ): TimeseriesResult!
}

enum TimeInterval {
  MINUTE
  HOUR
  DAY
  WEEK
  MONTH
}
```

---

### Response Types

#### AggregateResult

```graphql
type AggregateResult {
  visitors: Int
  pageviews: Int
  events: Int
  bounceRate: Float
  visitDuration: Int
  viewsPerVisit: Float
}
```

#### TimeseriesResult

```graphql
type TimeseriesResult {
  interval: TimeInterval!
  data: [TimeseriesDataPoint!]!
}

type TimeseriesDataPoint {
  date: String!
  visitors: Int
  pageviews: Int
  events: Int
  # ... other metrics
}
```

---

## Entity Relationships

```
Query
├── pageviews → PageviewConnection
│   └── edges → PageviewEdge → Pageview
├── events → EventConnection
│   └── edges → EventEdge → Event
├── customMetrics → [CustomMetric]
│   └── historicalValues → [MetricDataPoint]
├── aggregate → AggregateResult
└── timeseries → TimeseriesResult
        └── data → [TimeseriesDataPoint]
```

---

## Validation Rules

| Field | Validation |
|-------|------------|
| dateRange.from | Valid ISO 8601 date, not after `to` |
| dateRange.to | Valid ISO 8601 date, not before `from` |
| pagination.first | Max 1000, min 1 |
| siteId | Must be valid site domain |
| metrics | Must be valid metric names |

---

## State Transitions

Not applicable - this is a read-only API exposing existing analytics data.

---

## Notes

- All timestamps in UTC
- URL encoding: URLs are percent-encoded in queries
- Empty arrays returned when no data matches filters (not errors)
- Numeric fields return `null` when not applicable (e.g., bounce rate when only 1 visitor)
