# Feature Specification: Time Period Comparison

**Feature Branch**: `005-time-period-comparison`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## Important Context

This feature already exists in the codebase. The specification below documents the current implementation for verification purposes.

## User Scenarios & Testing

### User Story 1 - Compare with Previous Period (Priority: P1)

As a website analytics user, I want to compare my current period metrics with the immediately preceding period of equal length, so I can see how my site performance has changed.

**Why this priority**: This is the most common comparison mode for understanding short-term trends and identifying sudden changes in traffic or engagement.

**Independent Test**: User can select "Previous period" from the comparison dropdown and see metrics compared to the immediately preceding date range with percentage change indicators.

**Acceptance Scenarios**:

1. **Given** user is viewing analytics for "Last 7 days", **When** they enable "Previous period" comparison, **Then** metrics are displayed for both "Last 7 days" and "7 days prior to that", with percentage change shown between them
2. **Given** user selects a single day view, **When** they enable previous period comparison, **Then** metrics compare that specific day with the day immediately before
3. **Given** comparison is enabled, **When** user changes the main date period, **Then** the comparison period automatically adjusts to maintain the same duration

---

### User Story 2 - Compare with Year-over-Year (Priority: P2)

As a website analytics user, I want to compare my current period metrics with the same period from the previous year, so I can identify yearly trends and seasonal patterns.

**Why this priority**: Year-over-year comparisons eliminate seasonal variations and provide context for annual performance patterns.

**Independent Test**: User can select "Year over year" from the comparison dropdown and see metrics compared to the same dates from the previous year.

**Acceptance Scenarios**:

1. **Given** user is viewing analytics for "January 2026", **When** they enable "Year over year" comparison, **Then** metrics are compared with "January 2025"
2. **Given** user is viewing "Last 7 days" ending on a Sunday, **When** they enable year-over-year comparison, **Then** metrics compare with the same 7-day period from the previous year (same start day of week if day-of-week matching is enabled)

---

### User Story 3 - Custom Period Comparison (Priority: P2)

As a website analytics user, I want to compare my current metrics with a custom-selected date range, so I can benchmark against any specific period I choose.

**Why this priority**: Provides flexibility for ad-hoc comparisons against campaigns, product launches, or other significant events.

**Independent Test**: User can select "Custom period" and pick specific dates for comparison.

**Acceptance Scenarios**:

1. **Given** comparison mode is set to "Custom", **When** user selects a custom date range, **Then** metrics are compared against that selected range
2. **Given** user has a custom main period selected, **When** they enable custom comparison, **Then** both periods are displayed with percentage change

---

### User Story 4 - Day-of-Week Matching (Priority: P3)

As a website analytics user, I want comparison periods to align by day of the week rather than exact dates, so weekday-to-weekend comparisons are accurate.

**Why this priority**: Improves comparison accuracy for businesses with strong day-of-week patterns (e.g., retail sites with weekend spikes).

**Independent Test**: User can toggle "Match day of week" option and see comparison period adjust accordingly.

**Acceptance Scenarios**:

1. **Given** main period starts on Sunday, **When** "Match day of week" is enabled, **Then** comparison period also starts on the same day of the week
2. **Given** "Match day of week" is disabled, **Then** comparison uses exact date matching

---

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to compare metrics between two date ranges (source period and comparison period)
- **FR-002**: System MUST support three comparison modes: Previous period, Year-over-year, and Custom date range
- **FR-003**: System MUST display percentage change between the two periods alongside each metric
- **FR-004**: System MUST indicate direction of change with visual arrows (up for increase, down for decrease)
- **FR-005**: System MUST apply appropriate color coding to changes (green for positive, red for negative - with inversion for metrics like bounce rate where decrease is positive)
- **FR-006**: System MUST support "Match day of week" option to align comparison periods by weekday rather than exact dates
- **FR-007**: System MUST automatically adjust comparison period when user changes the main date period
- **FR-008**: System MUST persist user's comparison mode preference in local storage
- **FR-009**: System MUST disable comparison option for "Realtime" and "All time" periods where it doesn't make sense

### Key Entities

- **ComparisonPeriod**: Represents the date range being compared against the main period
- **ComparisonMode**: Enum defining comparison type (off, previous_period, year_over_year, custom)
- **ComparisonMatchMode**: Option for day-of-week alignment (MatchExactDate, MatchDayOfWeek)
- **MetricChange**: Represents the difference between two period values, including percentage change and direction

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can enable period comparison and see metrics for two date ranges within 2 seconds of interaction
- **SC-002**: Percentage change is displayed for all comparable metrics in the dashboard
- **SC-003**: Comparison mode preference persists across browser sessions
- **SC-004**: All three comparison modes (previous_period, year_over_year, custom) function correctly
- **SC-005**: Day-of-week matching correctly aligns comparison periods when enabled

## Assumptions

- Comparison functionality applies to historical data only (not realtime/24h periods where comparison is less meaningful)
- Metric comparison requires both periods to have data available
- Custom date range comparison requires user to explicitly select both comparison dates
