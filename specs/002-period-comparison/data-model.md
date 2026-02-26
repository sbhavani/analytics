# Data Model: Time Period Comparison

## Entities

### Date Range

A defined period with a start date and end date representing a time interval.

| Field | Type | Description |
|-------|------|-------------|
| start_date | Date | Inclusive start of the period |
| end_date | Date | Inclusive end of the period |

**Validation Rules**:
- start_date must be before or equal to end_date
- Date range cannot exceed 366 days (prevent performance issues)

---

### Predefined Period

A named time interval with automatically calculated dates based on current date.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Display name (e.g., "This Week", "Last Month") |
| period_type | Enum | week, month, quarter, year |
| offset | Integer | Offset from current period (0 = current, -1 = previous) |

**Predefined Options**:
| Name | period_type | offset |
|------|--------------|--------|
| This Week | week | 0 |
| Last Week | week | -1 |
| This Month | month | 0 |
| Last Month | month | -1 |
| This Quarter | quarter | 0 |
| Last Quarter | quarter | -1 |
| This Year | year | 0 |
| Last Year | year | -1 |

---

### Metric

A quantifiable measure being tracked in the analytics system.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Metric identifier (e.g., "visitors", "pageviews", "revenue") |
| value | Integer/Float | The aggregated value for the period |

---

### Comparison Result

The calculated difference between two date ranges.

| Field | Type | Description |
|-------|------|-------------|
| primary_date_range | Date Range | The current/primary period |
| comparison_date_range | Date Range | The period being compared against |
| primary_value | Metric | Metric value for primary period |
| comparison_value | Metric | Metric value for comparison period |
| absolute_change | Number | primary_value - comparison_value |
| percentage_change | Number | ((primary - comparison) / comparison) * 100 |
| change_direction | Enum | increase, decrease, no_change, not_applicable |
| status | Enum | success, no_data, division_by_zero |

**Calculated Fields**:
- `absolute_change`: Raw difference between primary and comparison values
- `percentage_change`: Percentage difference, formula: ((primary - comparison) / comparison) * 100
- `change_direction`:
  - increase: percentage_change > 0
  - decrease: percentage_change < 0
  - no_change: percentage_change = 0
  - not_applicable: comparison_value = 0 or missing

---

## State Transitions

### Period Selection Flow

```
User selects predefined period OR custom date range
          │
          ▼
    Validate date range (start <= end, max 366 days)
          │
          ▼
    Query metrics for primary period
          │
          ▼
    Query metrics for comparison period
          │
          ▼
    Calculate comparison (percentage change)
          │
          ▼
    Display results with visual indicators
```

---

## API Contracts (Frontend-Backend)

### GET /api/stats/compare

Query metrics for two date ranges and return comparison.

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| site_id | UUID | Yes | Site identifier |
| metric | String | Yes | Metric name (visitors, pageviews, etc.) |
| period_primary_start | Date | Yes | Primary period start |
| period_primary_end | Date | Yes | Primary period end |
| period_comparison_start | Date | Yes | Comparison period start |
| period_comparison_end | Date | Yes | Comparison period end |

**Response**:
```json
{
  "primary": {
    "date_range": {
      "start_date": "2026-02-17",
      "end_date": "2026-02-23"
    },
    "value": 1000
  },
  "comparison": {
    "date_range": {
      "start_date": "2026-02-10",
      "end_date": "2026-02-16"
    },
    "value": 800
  },
  "comparison_result": {
    "absolute_change": 200,
    "percentage_change": 25.0,
    "change_direction": "increase"
  }
}
```

### GET /api/periods/predefined

Get list of predefined period options with calculated dates.

**Request Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| site_id | UUID | Yes | Site identifier |

**Response**:
```json
{
  "predefined_periods": [
    {
      "name": "This Week",
      "period_type": "week",
      "offset": 0,
      "date_range": {
        "start_date": "2026-02-17",
        "end_date": "2026-02-23"
      }
    },
    {
      "name": "Last Week",
      "period_type": "week",
      "offset": -1,
      "date_range": {
        "start_date": "2026-02-10",
        "end_date": "2026-02-16"
      }
    }
  ]
}
```
