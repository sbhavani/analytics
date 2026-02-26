# Data Model: GraphQL Analytics API

## Entity Definitions

### Pageview
Represents a single page view event.

| Field | Type | Description |
|-------|------|-------------|
| url | String | The page URL that was viewed |
| visitor_count | Integer | Number of unique visitors |
| view_count | Integer | Total number of page views |
| timestamp | DateTime | Time of the pageview |

### Event
Represents a custom tracking event.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Event name |
| count | Integer | Number of event occurrences |
| timestamp | DateTime | Time of the event |
| properties | JSON | Custom event properties |

### Custom Metric
Represents a business-defined metric calculation.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Metric identifier |
| value | Float | Calculated metric value |
| formula | String | How the metric is calculated |

### Filter Criteria
Input type for filtering queries.

| Field | Type | Description |
|-------|------|-------------|
| date_range | DateRangeInput | Start and end dates |
| url_pattern | String | URL filter (supports wildcards) |
| referrer | String | Referrer domain |
| device_type | Enum | desktop, mobile, tablet |
| country | String | Country code |
| region | String | Region code |
| city | String | City code |

### Aggregation
Input type for data aggregation.

| Field | Type | Description |
|-------|------|-------------|
| type | Enum | count, sum, average, min, max |
| metric | String | Which metric to aggregate |
| group_by | String | Optional dimension to group by |

### DateRangeInput
Input type for date filtering.

| Field | Type | Description |
|-------|------|-------------|
| start_date | Date | Beginning of range |
| end_date | Date | End of range |

## Relationships

- Site → has many → Pageviews (via Stats query)
- Site → has many → Events (via Stats query)
- Site → has many → Custom Metrics (via Stats query)
- All queries scoped to a Site (identified by domain)

## Validation Rules

- Date range: start_date must be before or equal to end_date
- URL pattern: Valid URL pattern string
- Device type: Must be one of: desktop, mobile, tablet
- Aggregation type: Must be one of: count, sum, average, min, max
- Metrics: Must reference valid metric names from existing Stats module
