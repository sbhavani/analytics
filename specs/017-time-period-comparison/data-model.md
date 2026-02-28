# Data Model: Time Period Comparison

**Feature**: Time Period Comparison

## Key Entities

### 1. DateRange

Represents a time period with a start and end date.

**Attributes**:
- `first` (Date) - Start date of the range
- `last` (Date) - End date of the range
- `timezone` (String, optional) - Timezone for the date range

**Source**: `lib/plausible/stats/datetime_range.ex`

### 2. MetricValue

The numerical value of a metric calculated for a specific date range.

**Attributes**:
- `value` (Float/Integer) - The calculated metric value
- `metric` (Atom) - The metric type (e.g., :visitors, :pageviews)
- `date_range` (DateRange) - The period this value represents

**Source**: Returned from stats queries

### 3. PercentageChange

The calculated difference between two metric values expressed as a percentage.

**Attributes**:
- `value` (Integer) - The percentage change (can be negative)
- `direction` (Atom) - :increase, :decrease, :unchanged
- `old_value` (Float/Integer) - The comparison period value
- `new_value` (Float/Integer) - The current period value

**Calculation**:
```
percentage_change = ((new_value - old_value) / old_value) * 100
```

**Source**: `lib/plausible/stats/compare.ex`

### 4. ComparisonConfiguration

Stores user preferences for comparison mode and date ranges.

**Attributes**:
- `mode` (Atom) - :off, :previous_period, :year_over_year, :custom
- `match_day_of_week` (Boolean) - Whether to match day of week
- `comparison_date_range` (DateRange, optional) - Custom comparison range

**Source**: URL query parameters and dashboard state

## State Transitions

### Comparison Mode

```
off --> previous_period
off --> year_over_year
off --> custom
previous_period --> off
year_over_year --> off
custom --> off
```

## Validation Rules

1. Comparison date range must not overlap with future dates
2. Date ranges must have valid start and end dates (start <= end)
3. Percentage change calculation handles division by zero gracefully

## Relationships

- ComparisonConfiguration has one DateRange (comparison period)
- MetricValue belongs to a DateRange
- PercentageChange is derived from two MetricValues
