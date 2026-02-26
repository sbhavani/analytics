# GraphQL Schema Contract

## Endpoint

```
POST /api/graphql
Content-Type: application/json
Authorization: Bearer <api_key>
```

## Schema

```graphql
# Inputs
input DateRangeInput {
  start_date: Date!
  end_date: Date!
}

input FilterInput {
  date_range: DateRangeInput
  url_pattern: String
  referrer: String
  device_type: DeviceType
  country: String
  region: String
  city: String
}

input AggregationInput {
  type: AggregationType!
  metric: String!
  group_by: String
}

enum DeviceType {
  DESKTOP
  MOBILE
  TABLET
}

enum AggregationType {
  COUNT
  SUM
  AVERAGE
  MIN
  MAX
}

enum TimeGrouping {
  HOUR
  DAY
  WEEK
  MONTH
}

# Types
type PageviewResult {
  url: String!
  visitor_count: Int!
  view_count: Int!
  timestamp: DateTime!
}

type EventResult {
  name: String!
  count: Int!
  timestamp: DateTime!
  properties: JSON
}

type CustomMetricResult {
  name: String!
  value: Float!
  formula: String
}

type AggregateResult {
  metric: String!
  value: Float!
}

type TimeSeriesPoint {
  date: DateTime!
  visitors: Int
  pageviews: Int
  events: Int
}

# Query Root
type Query {
  # Pageview queries
  pageviews(
    site_id: ID!
    filter: FilterInput
    limit: Int
    offset: Int
  ): [PageviewResult!]!

  pageviews_aggregate(
    site_id: ID!
    filter: FilterInput
    aggregation: AggregationInput!
  ): AggregateResult!

  pageviews_timeseries(
    site_id: ID!
    filter: FilterInput
    interval: TimeGrouping!
  ): [TimeSeriesPoint!]!

  # Event queries
  events(
    site_id: ID!
    filter: FilterInput
    event_type: String
    limit: Int
    offset: Int
  ): [EventResult!]!

  events_aggregate(
    site_id: ID!
    filter: FilterInput
    event_type: String
    aggregation: AggregationInput!
  ): AggregateResult!

  # Custom Metrics queries
  custom_metrics(
    site_id: ID!
    filter: FilterInput
  ): [CustomMetricResult!]!

  # Combined analytics
  analytics(
    site_id: ID!
    filter: FilterInput
    metrics: [String!]!
    interval: TimeGrouping
  ): [TimeSeriesPoint!]!
}

# Errors
type Error {
  message: String!
  code: String
}

# Response wrapper
type AnalyticsResponse {
  data: JSON
  errors: [Error!]
}
```

## Example Queries

### Get Pageviews
```graphql
query {
  pageviews(
    site_id: "example.com"
    filter: {
      date_range: { start_date: "2026-01-01", end_date: "2026-01-31" }
    }
    limit: 10
  ) {
    url
    visitor_count
    view_count
  }
}
```

### Get Aggregated Events
```graphql
query {
  events_aggregate(
    site_id: "example.com"
    filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } }
    event_type: "signup"
    aggregation: { type: COUNT, metric: "events" }
  ) {
    metric
    value
  }
}
```

### Get Custom Metrics
```graphql
query {
  custom_metrics(
    site_id: "example.com"
    filter: { date_range: { start_date: "2026-01-01", end_date: "2026-01-31" } }
  ) {
    name
    value
  }
}
```
