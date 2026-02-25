# Data Model: GraphQL Analytics API

## Entity Overview

This document defines the data model for the GraphQL Analytics API, including the query types, input types, and result structures.

## Core Entities

### 1. Pageview

Represents a single page view in the analytics system.

**Attributes**:
| Field | Type | Description |
|-------|------|-------------|
| url_path | String | The path portion of the URL |
| timestamp | DateTime | When the pageview occurred |
| referrer | String (nullable) | Source that linked to the page |
| user_agent | String (nullable) | Browser/device information |
| country | String (nullable) | Visitor country code |
| device | String | Device type (desktop, mobile, tablet) |

**Query Support**: Filterable by date range, URL path pattern

---

### 2. Event

Represents a user-triggered action beyond pageviews.

**Attributes**:
| Field | Type | Description |
|-------|------|-------------|
| name | String | The event type/category |
| timestamp | DateTime | When the event occurred |
| url_path | String (nullable) | Page where event occurred |
| properties | JSON | Custom event properties |
| country | String (nullable) | Visitor country code |
| device | String | Device type |

**Query Support**: Filterable by date range, event name, event properties

---

### 3. Custom Metric

Represents a business-defined KPI being tracked.

**Attributes**:
| Field | Type | Description |
|-------|------|-------------|
| name | String | Unique metric identifier |
| value | Float | Metric value |
| timestamp | DateTime | When the metric was recorded |
| metadata | JSON (nullable) | Additional context |

**Query Support**: Filterable by date range, metric name, aggregatable by time period

---

## Input Types

### DateRangeInput

Specifies the time period for queries.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| start_date | Date | Yes | Start of date range (inclusive) |
| end_date | Date | Yes | End of date range (inclusive) |

---

### PageviewFilterInput

Filter criteria for pageview queries.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| url_pattern | String | No | Glob pattern to match URL paths |
| referrer | String | No | Filter by referrer source |
| country | String | No | Filter by country code |
| device | String | No | Filter by device type |

---

### EventFilterInput

Filter criteria for event queries.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| event_name | String | No | Filter by event type |
| properties | JSON | No | Filter by event properties (exact match) |
| url_pattern | String | No | Filter by page URL |

---

### MetricFilterInput

Filter criteria for custom metric queries.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| metric_name | String | Yes | Name of the metric to retrieve |

---

### AggregationInput

Specifies how to aggregate data.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| function | Enum | Yes | SUM, COUNT, AVG, MIN, MAX |
| granularity | Enum | No | HOUR, DAY, WEEK, MONTH (default: DAY) |

---

### PaginationInput

Controls result set pagination.

**Fields**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| limit | Integer | No | Number of results (default: 100, max: 1000) |
| offset | Integer | No | Number of results to skip (default: 0) |

---

## Query Result Types

### PageviewResult

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| data | [Pageview] | List of pageview records |
| pagination | PaginationInfo | Pagination metadata |
| total | Integer | Total count matching filters |

---

### EventResult

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| data | [Event] | List of event records |
| pagination | PaginationInfo | Pagination metadata |
| total | Integer | Total count matching filters |

---

### MetricResult

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| data | [CustomMetric] | List of metric data points |
| pagination | PaginationInfo | Pagination metadata |
| aggregated | Float | Aggregated value if aggregation specified |

---

### AggregationResult

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| period | DateTime | Start of the aggregation period |
| value | Float | Aggregated value |
| function | String | Aggregation function used |

---

### PaginationInfo

**Fields**:
| Field | Type | Description |
|-------|------|-------------|
| limit | Integer | Results per page |
| offset | Integer | Current offset |
| has_more | Boolean | Whether more results exist |
| total | Integer | Total count available |

---

## GraphQL Schema Overview

### Root Query Fields

```
type Query {
  pageviews(
    site_id: String!
    date_range: DateRangeInput!
    filters: PageviewFilterInput
    aggregation: AggregationInput
    pagination: PaginationInput
  ): PageviewResult!

  events(
    site_id: String!
    date_range: DateRangeInput!
    filters: EventFilterInput
    aggregation: AggregationInput
    pagination: PaginationInput
  ): EventResult!

  metrics(
    site_id: String!
    date_range: DateRangeInput!
    filters: MetricFilterInput!
    aggregation: AggregationInput
    pagination: PaginationInput
  ): MetricResult!
}
```

---

## Validation Rules

1. **Date Range**: Must not exceed 366 days
2. **URL Pattern**: Must be valid glob pattern
3. **Pagination Limit**: Must be between 1 and 1000
4. **Aggregation Function**: Must be one of: SUM, COUNT, AVG, MIN, MAX
5. **Granularity**: Must be one of: HOUR, DAY, WEEK, MONTH

---

## Error Responses

| Error Code | Description |
|------------|-------------|
| INVALID_DATE_RANGE | Date range exceeds maximum allowed |
| INVALID_FILTER | Filter criteria malformed |
| INVALID_AGGREGATION | Aggregation function not supported |
| RATE_LIMIT_EXCEEDED | Too many requests |
| UNAUTHORIZED | Invalid or missing API key |
| NOT_FOUND | Site not found or no data for criteria |
