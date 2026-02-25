# Feature Specification: Time Period Comparison

**Feature Branch**: `001-time-period-comparison`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare Metrics Between Two Time Periods (Priority: P1)

As a user viewing analytics, I want to compare metrics between two different date ranges so that I can understand how my performance has changed over time.

**Why this priority**: This is the core functionality that enables users to derive insights from their data. Without period comparison, users cannot measure growth, identify trends, or assess the impact of changes.

**Independent Test**: Can be fully tested by selecting two date ranges and verifying that metrics display for both periods with correct percentage change calculations.

**Acceptance Scenarios**:

1. **Given** a user has metrics available for "this week" and "last week", **When** they select both periods for comparison, **Then** they see the current period value, previous period value, and percentage change displayed together.

2. **Given** a user is viewing a metric dashboard, **When** they choose to compare this week to last week, **Then** the system displays both values and shows a percentage change indicator (e.g., "+25%" or "-15%").

3. **Given** a user selects two identical date ranges, **When** they view the comparison, **Then** the percentage change displays as "0%" or "No change".

---

### User Story 2 - Select Predefined Time Period Pairs (Priority: P2)

As a user, I want to quickly select from predefined period pairs so that I don't have to manually configure date ranges for common comparisons.

**Why this priority**: Predefined pairs reduce friction and make the most common comparison types (week-over-week, month-over-month) accessible with minimal effort.

**Independent Test**: Can be tested by verifying all predefined pairs are available and correctly calculate the expected date ranges.

**Acceptance Scenarios**:

1. **Given** the comparison interface, **When** a user clicks the period selector, **Then** they see predefined options including "This Week vs Last Week", "This Month vs Last Month", "This Quarter vs Last Quarter", and "This Year vs Last Year".

2. **Given** a user selects "This Week vs Last Week", **When** the comparison loads, **Then** the current week includes today's date and the previous week is the 7 days immediately preceding the current week.

3. **Given** a user selects "This Month vs Last Month", **When** the comparison loads, **Then** the system compares the current calendar month to the immediately preceding calendar month.

---

### User Story 3 - Define Custom Date Ranges (Priority: P3)

As a user, I want to define custom date ranges for comparison so that I can analyze any two periods of interest.

**Why this priority**: Not all comparisons fit predefined patterns. Custom ranges enable users to compare any two arbitrary periods (e.g., a specific campaign period vs. a baseline).

**Independent Test**: Can be tested by selecting custom start and end dates for both periods and verifying the comparison reflects those exact dates.

**Acceptance Scenarios**:

1. **Given** the comparison interface, **When** a user chooses "Custom" mode, **Then** they can independently select a start date and end date for both the current period and comparison period.

2. **Given** a user selects a custom range that includes dates with no data, **When** the comparison displays, **Then** the system shows available data for the dates that have data, with a note indicating partial data availability.

3. **Given** a user selects a custom range where the comparison period has zero values for all metrics, **When** the comparison displays, **Then** the percentage change shows as "N/A" or "No data to compare" rather than an error.

---

### Edge Cases

- What happens when the comparison period has no data at all?
- How does the system handle timezone differences for date range calculations?
- What if the user selects future dates in either period?
- How does the system behave when comparing periods of different lengths (e.g., 4 weeks vs. 5 weeks)?
- What happens when percentage change is extremely large (positive or negative) - is there a display cap?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to select two distinct date ranges for comparison: a "current" period and a "comparison" period.
- **FR-002**: System MUST display each metric's value for both selected periods side by side in a clear visual format.
- **FR-003**: System MUST calculate and display percentage change between the two periods for each metric.
- **FR-004**: System MUST provide predefined period pair options including at minimum: This Week vs Last Week, This Month vs Last Month, This Quarter vs Last Quarter, This Year vs Last Year.
- **FR-005**: System MUST allow users to define custom date ranges for both the current and comparison periods.
- **FR-006**: System MUST clearly indicate positive changes (e.g., green color, "+" prefix) and negative changes (e.g., red color, "-" prefix).
- **FR-007**: System MUST handle cases where one or both periods have no data by displaying appropriate messaging instead of errors.
- **FR-008**: System MUST handle division by zero scenarios (when comparison period value is zero) by displaying appropriate messaging.
- **FR-009**: System MUST persist the user's selected comparison configuration so it remains when returning to the dashboard.
- **FR-010**: System MUST support comparison across all available metric types in the analytics dashboard.

### Key Entities

- **TimePeriod**: Represents a date range with a start date, end date, and optional label. Used for both the current period and comparison period.
- **MetricValue**: The numeric value for a specific metric within a time period.
- **ComparisonResult**: The calculated difference between two metric values, expressed as both an absolute difference and percentage change.
- **PredefinedPeriodPair**: A named pairing of two time periods (e.g., "This Week vs Last Week") with calculated date ranges.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete a time period comparison task in under 30 seconds from initial selection to seeing results.
- **SC-002**: 95% of users successfully complete a period comparison on their first attempt without requiring assistance.
- **SC-003**: Percentage change calculations are accurate 100% of the time (verified against manual calculation).
- **SC-004**: All predefined period pairs correctly calculate their respective date ranges based on the current date.
- **SC-005**: Users can compare any two custom date ranges without system errors or crashes.
- **SC-006**: The comparison feature works across all metric types available in the analytics dashboard.

## Assumptions

- The analytics dashboard already exists and has a way to display metrics.
- The system has access to historical data for all time periods users might select.
- Users have appropriate permissions to view the metrics being compared.
- The application supports date range selection in other parts of the system (can be reused).
- Metrics are stored with timestamps that allow filtering by date range.
