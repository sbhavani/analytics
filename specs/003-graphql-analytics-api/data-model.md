# Data Model: GraphQL Analytics API

## Entities

### Pageview

Represents a single page view in the analytics system.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| url | String | The full URL of the page viewed | Required, valid URL format |
| viewCount | Integer | Number of times the page was viewed | Required, >= 0 |
| uniqueVisitors | Integer | Number of unique visitors | Required, >= 0 |
| timestamp | DateTime | Time of the pageview | Required |
| referrer | String? | Source of the visit | Optional |
| country | String? | Visitor country code | Optional |
| device | String | Device type (desktop/mobile/tablet) | Required |

### Event

Represents a custom tracking event.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| name | String | Event name | Required, max 100 chars |
| count | Integer | Number of occurrences | Required, >= 0 |
| properties | JSON | Event-specific properties | Optional |
| timestamp | DateTime | Time of event | Required |
| visitorId | String | Anonymous visitor identifier | Required |

### CustomMetric

Represents a business-level metric being tracked.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| name | String | Metric identifier | Required |
| value | Float | Current metric value | Required |
| historical | [MetricDataPoint] | Historical values | Optional |

### MetricDataPoint

| Field | Type | Description |
|-------|------|-------------|
| timestamp | DateTime | Time of measurement |
| value | Float | Metric value at this time |

## Input Types (Filters)

### DateRangeFilter

| Field | Type | Description |
|-------|------|-------------|
| from | DateTime | Start of range |
| to | DateTime | End of range |

### PropertyFilter

| Field | Type | Description |
|-------|------|-------------|
| field | String | Property name (country, device, referrer) |
| operator | String | eq, neq, contains |
| value | String | Filter value |

### AggregationInput

| Field | Type | Description |
|-------|------|-------------|
| type | String | count, sum, avg, min, max |
| field | String | Field to aggregate |

## Relationships

```
Query
  ├── pageviews(filter: PageviewFilter): [Pageview]
  ├── events(filter: EventFilter): [Event]
  └── metrics(filter: MetricFilter): [CustomMetric]
```

## State Transitions

Not applicable - this is a read-only API exposing existing data.

## Validation Rules

1. Date range cannot exceed 1 year
2. Maximum 10000 records per query (pagination required)
3. API key required for all queries
4. Filter operators: eq, neq, contains, gt, gte, lt, lte
