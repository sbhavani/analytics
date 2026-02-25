# Data Model: Time Period Comparison

## Entities

### TimePeriod

Represents a date range for metrics comparison.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| start_date | Date | Yes | Inclusive start of the period |
| end_date | Date | Yes | Inclusive end of the period |
| label | String | No | Display name (e.g., "This Week") |
| period_type | Enum | Yes | One of: predefined, custom |

**Validation Rules**:
- start_date must be <= end_date
- Date range cannot exceed 2 years
- Period cannot include future dates beyond today

---

### MetricValue

The numeric value for a specific metric within a time period.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| metric_name | String | Yes | Identifier of the metric type |
| value | Decimal | Yes | The aggregated metric value |
| site_id | UUID | Yes | Reference to the analytics site |
| time_period | TimePeriod | Yes | The period this value belongs to |

**Validation Rules**:
- value must be non-negative for most metrics
- metric_name must match registered metric types

---

### ComparisonResult

The calculated difference between two metric values.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| metric_name | String | Yes | Identifier of the metric being compared |
| current_value | Decimal | Yes | Value for the current period |
| previous_value | Decimal | Yes | Value for the comparison period |
| absolute_change | Decimal | No | Current - Previous |
| percentage_change | Decimal | No | ((Current - Previous) / Previous) * 100 |
| change_direction | Enum | Yes | One of: positive, negative, neutral, no_data |

**Validation Rules**:
- percentage_change calculation handles division by zero
- No_data state when either value is null

**State Transitions**:
- When previous_value = 0 and current_value > 0: change_direction = positive, percentage_change = N/A
- When previous_value = 0 and current_value = 0: change_direction = neutral
- When current_value > previous_value: change_direction = positive
- When current_value < previous_value: change_direction = negative
- When current_value = previous_value: change_direction = neutral

---

### PredefinedPeriodPair

A named pairing of two time periods for quick comparison.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| name | String | Yes | Display name (e.g., "This Week vs Last Week") |
| current_period_type | Enum | Yes | Type of current period |
| comparison_period_type | Enum | Yes | Type of comparison period |
| is_default | Boolean | No | Whether this is the default selection |

**Predefined Period Types**:
- this_week: Current week (Monday to Sunday)
- last_week: Previous week
- this_month: Current calendar month
- last_month: Previous calendar month
- this_quarter: Current quarter (Q1-Q4)
- last_quarter: Previous quarter
- this_year: Current calendar year
- last_year: Previous calendar year

---

## Relationships

```
ComparisonRequest
├── current_period: TimePeriod
├── comparison_period: TimePeriod
├── metrics: MetricValue[] (for current period)
└── comparison_metrics: MetricValue[] (for comparison period)
    │
    └── derived to: ComparisonResult[]
```

---

## Database Considerations

### ClickHouse Schema (Analytics Data)

The existing ClickHouse events table contains:
- `site_id`: UUID
- `timestamp`: DateTime
- Various event columns (visitors, events, etc.)

**Query Pattern for Period Comparison**:

```sql
-- For current period
SELECT
    metric_aggregation
FROM events
WHERE site_id = :site_id
  AND timestamp BETWEEN :current_start AND :current_end

-- For comparison period
SELECT
    metric_aggregation
FROM events
WHERE site_id = :site_id
  AND timestamp BETWEEN :comparison_start AND :comparison_end
```

### PostgreSQL (User Preferences)

Store user's last selected comparison configuration:
- last_selected_pair_id: UUID (reference to PredefinedPeriodPair)
- custom_current_start: Date
- custom_current_end: Date
- custom_comparison_start: Date
- custom_comparison_end: Date
