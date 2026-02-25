# API Contracts: Time Period Comparison

## Backend API Endpoints

### Get Period Comparison Data

Retrieve metrics comparison between two time periods.

**Endpoint**: `GET /api/v1/sites/:site_id/analytics/compare`

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| site_id | UUID | Yes | The analytics site identifier |

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| current_start | Date | Yes* | Start date for current period (YYYY-MM-DD) |
| current_end | Date | Yes* | End date for current period (YYYY-MM-DD) |
| comparison_start | Date | Yes* | Start date for comparison period |
| comparison_end | Date | Yes* | End date for comparison period |
| period_pair | String | Yes* | Predefined pair ID (e.g., "this_week_vs_last_week") |
| metrics | String | No | Comma-separated metric names (default: all) |

*Either provide both date ranges OR a period_pair, not both.

**Response** (200 OK):
```json
{
  "data": {
    "current_period": {
      "start": "2026-02-17",
      "end": "2026-02-23",
      "label": "This Week"
    },
    "comparison_period": {
      "start": "2026-02-10",
      "end": "2026-02-16",
      "label": "Last Week"
    },
    "metrics": [
      {
        "name": "visitors",
        "current_value": 1250,
        "comparison_value": 1000,
        "absolute_change": 250,
        "percentage_change": 25.0,
        "change_direction": "positive"
      },
      {
        "name": "pageviews",
        "current_value": 5000,
        "comparison_value": 4200,
        "absolute_change": 800,
        "percentage_change": 19.05,
        "change_direction": "positive"
      }
    ]
  }
}
```

**Error Responses**:
- 400: Invalid date parameters
- 401: Unauthorized
- 403: Site access denied
- 404: Site not found

---

### Get Predefined Period Pairs

Retrieve available predefined period comparison options.

**Endpoint**: `GET /api/v1/sites/:site_id/analytics/period-pairs`

**Response** (200 OK):
```json
{
  "data": [
    {
      "id": "this_week_vs_last_week",
      "name": "This Week vs Last Week",
      "current_period_type": "this_week",
      "comparison_period_type": "last_week"
    },
    {
      "id": "this_month_vs_last_month",
      "name": "This Month vs Last Month",
      "current_period_type": "this_month",
      "comparison_period_type": "last_month"
    },
    {
      "id": "this_quarter_vs_last_quarter",
      "name": "This Quarter vs Last Quarter",
      "current_period_type": "this_quarter",
      "comparison_period_type": "last_quarter"
    },
    {
      "id": "this_year_vs_last_year",
      "name": "This Year vs Last Year",
      "current_period_type": "this_year",
      "comparison_period_type": "last_year"
    }
  ]
}
```

---

### Save User Comparison Preferences

Persist user's last selected comparison configuration.

**Endpoint**: `POST /api/v1/sites/:site_id/analytics/preferences/comparison`

**Request Body**:
```json
{
  "selected_pair_id": "this_week_vs_last_week",
  "custom_current_start": "2026-01-01",
  "custom_current_end": "2026-01-31",
  "custom_comparison_start": "2025-12-01",
  "custom_comparison_end": "2025-12-31"
}
```

**Response** (200 OK):
```json
{
  "data": {
    "saved": true
  }
}
```

---

## Frontend Contracts

### PeriodSelector Component

**Interface**:
```typescript
interface PeriodSelectorProps {
  siteId: string;
  onPeriodChange: (period: PeriodSelection) => void;
  selectedPair?: string;
  selectedCurrentPeriod?: DateRange;
  selectedComparisonPeriod?: DateRange;
}

interface PeriodSelection {
  mode: 'predefined' | 'custom';
  predefinedPairId?: string;
  customCurrentPeriod?: DateRange;
  customComparisonPeriod?: DateRange;
}

interface DateRange {
  startDate: Date;
  endDate: Date;
}
```

### ComparisonTable Component

**Interface**:
```typescript
interface ComparisonTableProps {
  metrics: MetricComparison[];
  loading?: boolean;
  onMetricClick?: (metricName: string) => void;
}

interface MetricComparison {
  name: string;
  displayName: string;
  currentValue: number;
  comparisonValue: number;
  absoluteChange: number;
  percentageChange: number;
  changeDirection: 'positive' | 'negative' | 'neutral' | 'no_data';
}
```

### MetricCard Component

**Interface**:
```typescript
interface MetricCardProps {
  metric: MetricComparison;
  onClick?: () => void;
}
```

---

## Integration Points

### Analytics Query Service

The backend uses ClickHouse for analytics queries. Period comparison requires:
1. Two separate queries (one per period) OR single query with GROUP BY
2. Date range filtering on timestamp column
3. Aggregation functions per metric type

### User Preferences Storage

User preferences stored in PostgreSQL:
- Table: `site_user_preferences`
- Fields: `site_id`, `user_id`, `comparison_preferences` (JSONB)
