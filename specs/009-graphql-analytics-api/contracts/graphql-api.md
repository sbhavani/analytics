# Contract: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Branch**: 009-graphql-analytics-api
**Date**: 2026-02-26

## API Endpoint

```
POST /api/graphql
Content-Type: application/json
Authorization: Bearer <API_KEY>
```

## GraphQL Schema

```graphql
type Query {
  # Aggregate metrics for a site
  aggregate(
    siteId: ID!
    input: AggregateInput!
  ): AggregateResult!

  # Breakdown by dimension
  breakdown(
    siteId: ID!
    input: BreakdownInput!
  ): [BreakdownResult!]!

  # Time series data
  timeseries(
    siteId: ID!
    input: TimeSeriesInput!
  ): [TimeSeriesPoint!]!

  # Custom metrics for a site
  customMetrics(
    siteId: ID!
  ): [CustomMetric!]!
}

# Input Types
input AggregateInput {
  metrics: [Metric!]!
  dateRange: DateRangeInput!
  filters: [FilterInput!]
}

input BreakdownInput {
  dimension: Dimension!
  metrics: [Metric!]!
  dateRange: DateRangeInput!
  filters: [FilterInput!]
  limit: Int
  sortBy: SortBy
}

input TimeSeriesInput {
  metrics: [Metric!]!
  dateRange: DateRangeInput!
  filters: [FilterInput!]
  granularity: Granularity!
}

input DateRangeInput {
  startDate: Date!
  endDate: Date!
}

input FilterInput {
  country: String
  region: String
  city: String
  referrer: String
  utmMedium: String
  utmSource: String
  utmCampaign: String
  device: String
  browser: String
  operatingSystem: String
  pathname: String
}

# Enums
enum Metric {
  VISITORS
  PAGEVIEWS
  EVENTS
  BOUNCE_RATE
  VISIT_DURATION
}

enum Dimension {
  COUNTRY
  REGION
  CITY
  REFERRER
  UTMMEDIUM
  UTMSOURCE
  UTMCAMPAIGN
  DEVICE
  BROWSER
  OPERATINGSYSTEM
  PATHNAME
}

enum Granularity {
  HOURLY
  DAILY
  WEEKLY
  MONTHLY
}

enum SortBy {
  VISITORS_DESC
  VISITORS_ASC
  PAGEVIEWS_DESC
  PAGEVIEWS_ASC
}

# Response Types
type AggregateResult {
  visitors: Int!
  pageviews: Int
  events: Int
  bounceRate: Float
  visitDuration: Int
}

type TimeSeriesPoint {
  date: DateTime!
  visitors: Int
  pageviews: Int
  events: Int
}

type BreakdownResult {
  dimension: String!
  visitors: Int
  pageviews: Int
  events: Int
}

type CustomMetric {
  name: String!
  value: Float!
}
```

## Example Queries

### Aggregate Request
```json
{
  "query": "query { aggregate(siteId: \"abc123\", input: { metrics: [VISITORS, PAGEVIEWS], dateRange: { startDate: \"2026-01-01\", endDate: \"2026-01-31\" } }) { visitors pageviews } }"
}
```

### Time Series Request
```json
{
  "query": "query { timeseries(siteId: \"abc123\", input: { metrics: [VISITORS], dateRange: { startDate: \"2026-01-01\", endDate: \"2026-01-31\" }, granularity: DAILY }) { date visitors } }"
}
```

### Breakdown Request
```json
{
  "query": "query { breakdown(siteId: \"abc123\", input: { dimension: COUNTRY, metrics: [VISITORS], dateRange: { startDate: \"2026-01-01\", endDate: \"2026-01-31\" }, limit: 10 }) { dimension visitors } }"
}
```

## Error Responses

### Authentication Error
```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "extensions": {
        "code": "UNAUTHORIZED"
      }
    }
  ]
}
```

### Validation Error
```json
{
  "errors": [
    {
      "message": "Invalid date range",
      "path": ["input", "dateRange"],
      "extensions": {
        "code": "VALIDATION_ERROR",
        "details": "Start date must be before end date"
      }
    }
  ]
}
```

### Rate Limiting
```json
{
  "errors": [
    {
      "message": "Rate limit exceeded",
      "extensions": {
        "code": "RATE_LIMITED",
        "retryAfter": 60
      }
    }
  ]
}
```
