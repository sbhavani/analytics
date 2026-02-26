# Data Model: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Branch**: 009-graphql-analytics-api
**Date**: 2026-02-26

## Entities

### Site
- **Description**: The website being tracked
- **Identifier**: site_id (UUID)
- **Fields**:
  - id: ID!
  - domain: String!
  - name: String

### PageviewEvent
- **Description**: A view of a page on the tracked site
- **Source**: ClickHouse (ClickhouseEventV2)
- **Fields**:
  - id: ID!
  - site: Site!
  - pathname: String
  - hostname: String
  - referrer: String
  - timestamp: DateTime!
  - userId: String
  - sessionId: String
  - utmMedium: String
  - utmSource: String
  - utmCampaign: String
  - countryCode: String
  - device: String
  - browser: String
  - operatingSystem: String

### CustomEvent
- **Description**: A named event triggered on the site
- **Source**: ClickHouse (ClickhouseEventV2 with non-null name)
- **Fields**:
  - id: ID!
  - site: Site!
  - name: String!
  - properties: JSON
  - timestamp: DateTime!
  - userId: String
  - sessionId: String

### Session
- **Description**: A user session containing multiple events
- **Source**: ClickHouse (ClickhouseSessionV2)
- **Fields**:
  - id: ID!
  - site: Site!
  - userId: String
  - start: DateTime!
  - duration: Int
  - pageviews: Int
  - events: Int
  - isBounce: Boolean
  - entryPage: String
  - exitPage: String

### CustomMetric
- **Description**: A user-defined calculation based on events or sessions
- **Source**: Calculated from ClickHouse queries
- **Fields**:
  - name: String!
  - value: Float!
  - formula: String (internal representation)

### AggregateResult
- **Description**: Aggregated analytics metrics
- **Fields**:
  - visitors: Int
  - pageviews: Int
  - events: Int
  - bounceRate: Float
  - visitDuration: Int

### TimeSeriesPoint
- **Description**: A single data point in a time series
- **Fields**:
  - date: DateTime!
  - visitors: Int
  - pageviews: Int
  - events: Int

### BreakdownResult
- **Description**: Aggregated results grouped by a dimension
- **Fields**:
  - dimension: String!
  - visitors: Int
  - pageviews: Int
  - events: Int

## Input Types (GraphQL)

### DateRangeInput
- **Fields**:
  - startDate: Date!
  - endDate: Date!

### FilterInput
- **Fields**:
  - country: String
  - region: String
  - city: String
  - referrer: String
  - utmMedium: String
  - utmSource: String
  - utmCampaign: String
  - device: String
  - browser: String
  - operatingSystem: String
  - pathname: String

### AggregateInput
- **Fields**:
  - metrics: [Metric!]!
  - dateRange: DateRangeInput!
  - filters: [FilterInput!]

### BreakdownInput
- **Fields**:
  - dimension: Dimension!
  - metrics: [Metric!]!
  - dateRange: DateRangeInput!
  - filters: [FilterInput!]
  - limit: Int
  - sortBy: SortBy

### TimeSeriesInput
- **Fields**:
  - metrics: [Metric!]!
  - dateRange: DateRangeInput!
  - filters: [FilterInput!]
  - granularity: Granularity!

## Enums

### Metric
- VISITORS
- PAGEVIEWS
- EVENTS
- BOUNCE_RATE
- VISIT_DURATION
- CUSTOM_METRIC

### Dimension
- COUNTRY
- REGION
- CITY
- REFERRER
- UTMMEDIUM
- UTMSOURCE
- UTMCAMPAIGN
- DEVICE
- BROWSER
- OPERATINGSYSTEM
- PATHNAME

### Granularity
- HOURLY
- DAILY
- WEEKLY
- MONTHLY

## Validation Rules

1. Date range must be valid (start <= end)
2. Date range cannot exceed 1 year
3. Breakdown limit must be between 1 and 1000
4. At least one metric required for aggregate/breakdown/timeseries
5. API key must be valid and have access to requested site
