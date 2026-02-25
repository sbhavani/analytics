# GraphQL Analytics API Contract

## Endpoint

```
POST /api/graphql
Content-Type: application/json
Authorization: Bearer <api_key>
```

## Schema

```graphql
type Query {
  # Pageview queries
  pageviews(
    siteId: ID!
    filter: PageviewFilter
    pagination: Pagination
    aggregation: AggregationInput
  ): [PageviewResult!]!

  # Event queries
  events(
    siteId: ID!
    filter: EventFilter
    pagination: Pagination
    aggregation: AggregationInput
  ): [EventResult!]!

  # Custom metric queries
  metrics(
    siteId: ID!
    filter: MetricFilter
    timeSeries: Boolean
    interval: TimeInterval
  ): [CustomMetric!]!
}

# Input Types
input PageviewFilter {
  dateRange: DateRangeInput!
  url: String
  country: String
  device: DeviceType
  referrer: String
}

input EventFilter {
  dateRange: DateRangeInput!
  eventName: String
  property: PropertyFilter
}

input MetricFilter {
  dateRange: DateRangeInput!
  metricNames: [String!]
}

input DateRangeInput {
  from: DateTime!
  to: DateTime!
}

input PropertyFilter {
  field: String!
  operator: FilterOperator!
  value: String!
}

enum FilterOperator {
  EQ
  NEQ
  CONTAINS
  GT
  GTE
  LT
  LTE
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

input Pagination {
  limit: Int
  offset: Int
}

enum TimeInterval {
  MINUTE
  HOUR
  DAY
  WEEK
  MONTH
}

enum DeviceType {
  DESKTOP
  MOBILE
  TABLET
}

# Result Types
type PageviewResult {
  url: String!
  viewCount: Int!
  uniqueVisitors: Int!
  timestamp: DateTime
  referrer: String
  country: String
  device: DeviceType
}

type EventResult {
  name: String!
  count: Int!
  properties: JSON
  timestamp: DateTime
}

type CustomMetric {
  name: String!
  value: Float!
  historical: [MetricDataPoint!]
}

type MetricDataPoint {
  timestamp: DateTime!
  value: Float!
}

scalar DateTime
scalar JSON
```

## Example Queries

### Query pageviews with date range

```json
{
  "query": "query { pageviews(siteId: \"abc123\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" } }) { url, viewCount, uniqueVisitors } }"
}
```

### Query events with aggregation

```json
{
  "query": "query { events(siteId: \"abc123\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" }, eventName: \"button_click\" }, aggregation: { type: COUNT }) { name, count } }"
}
```

### Query custom metrics with time series

```json
{
  "query": "query { metrics(siteId: \"abc123\", filter: { dateRange: { from: \"2026-01-01\", to: \"2026-01-31\" }, metricNames: [\"revenue\"] }, timeSeries: true, interval: DAY) { name, historical { timestamp, value } } }"
}
```

## Error Responses

```json
{
  "errors": [
    {
      "message": "Authentication required",
      "locations": [{ "line": 1, "column": 1 }],
      "path": ["pageviews"]
    }
  ]
}
```

```json
{
  "errors": [
    {
      "message": "Invalid date range: maximum 1 year allowed",
      "locations": [{ "line": 1, "column": 45 }],
      "path": ["pageviews"]
    }
  ]
}
```
