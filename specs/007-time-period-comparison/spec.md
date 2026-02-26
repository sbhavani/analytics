# Feature Specification: Time Period Comparison

**Feature Branch**: `007-time-period-comparison`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare Metrics Between Predefined Periods (Priority: P1)

As an analytics user, I want to quickly compare my current period metrics against a similar previous period using preset options, so I can instantly see how my metrics have changed without manually selecting dates.

**Why this priority**: This is the primary use case that provides immediate value to users. Predefined comparisons (this week vs last week, this month vs last month) are the most common comparison patterns in analytics.

**Independent Test**: Can be tested by selecting a predefined comparison option and verifying that metrics display for both periods with percentage change indicators.

**Acceptance Scenarios**:

1. **Given** the user is on a metrics dashboard, **When** they select "This Week vs Last Week" from the comparison selector, **Then** the dashboard displays current week metrics alongside last week metrics, with a percentage change indicator showing the difference.

2. **Given** the user has selected a predefined comparison, **When** they view any metric card, **Then** they see the metric value for both periods and a percentage change displayed prominently (e.g., "+23%" in green for increase, "-15%" in red for decrease).

3. **Given** the user selects "This Month vs Last Month", **When** the dashboard loads, **Then** metrics are aggregated for the current month and previous month respectively, with accurate percentage change calculations.

---

### User Story 2 - Compare Metrics Between Custom Date Ranges (Priority: P2)

As an analytics user, I want to compare metrics between any two custom date ranges I choose, so I can analyze performance for specific periods that aren't covered by predefined options.

**Why this priority**: Provides flexibility for users who need to compare non-standard periods (e.g., Q1 2024 vs Q1 2023, or a specific campaign period against a baseline).

**Independent Test**: Can be tested by selecting custom date pickers for both the current and comparison periods and verifying accurate metric calculations.

**Acceptance Scenarios**:

1. **Given** the user clicks on custom date range option, **When** they select a start and end date for the current period and a separate range for the comparison period, **Then** metrics are calculated for each selected range.

2. **Given** the user selects overlapping date ranges, **When** they attempt to confirm the selection, **Then** the system displays a clear error message explaining that date ranges cannot overlap.

3. **Given** the user has selected custom date ranges, **When** they change one of the date ranges, **Then** the comparison automatically updates to reflect the new selection.

---

### User Story 3 - Understand Percentage Change Indicators (Priority: P3)

As an analytics user, I want clear visual indicators that show the direction and magnitude of metric changes, so I can quickly interpret whether changes are positive or negative without doing mental math.

**Why this priority**: Clear visual communication of change direction is essential for usability. Users should instantly understand if metrics are up or down, and by how much.

**Independent Test**: Can be tested by creating scenarios with positive, negative, and zero changes and verifying correct display.

**Acceptance Scenarios**:

1. **Given** a metric has increased from the comparison period to the current period, **When** the percentage is calculated, **Then** the indicator shows a positive percentage with a green color and upward arrow.

2. **Given** a metric has decreased from the comparison period to the current period, **When** the percentage is calculated, **Then** the indicator shows a negative percentage with a red color and downward arrow.

3. **Given** a metric has remained exactly the same between periods, **When** the comparison is calculated, **Then** the indicator shows "0%" with a neutral color.

4. **Given** the comparison period has zero value for a metric, **When** calculating percentage change, **Then** the system displays "N/A" or "New" instead of dividing by zero.

---

### Edge Cases

- What happens when the comparison period has no data for a metric? (Display "No data" or "N/A")
- How does the system handle timezone differences when comparing periods across timezones?
- What if the selected date range includes future dates? (Should exclude future dates or show partial data with warning)
- How are partial periods handled (e.g., selecting "This Week" on a Wednesday)? (Should include only days through current day)
- What happens when comparing periods of different lengths (e.g., 28 days vs 31 days)? (Should either normalize or clearly display the actual periods used)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide predefined comparison options including at minimum: This Week vs Last Week, This Month vs Last Month, This Quarter vs Last Quarter, This Year vs Last Year.
- **FR-002**: System MUST allow users to select custom date ranges for both the current period and the comparison period using date picker controls.
- **FR-003**: System MUST display percentage change for each metric, calculated as: ((Current Value - Comparison Value) / Comparison Value) * 100.
- **FR-004**: System MUST visually distinguish positive changes (increases) from negative changes (decreases) using color coding.
- **FR-005**: System MUST show both the raw metric values for each period alongside the percentage change.
- **FR-006**: System MUST validate that selected date ranges do not overlap and display an error if they do.
- **FR-007**: System MUST handle division by zero gracefully when comparison period has zero value, displaying appropriate messaging.
- **FR-008**: System MUST persist the user's selected comparison preference so it remains set when returning to the dashboard.
- **FR-009**: System MUST update all metrics on the dashboard when the user changes the comparison selection.
- **FR-010**: System MUST provide a way to disable or hide the comparison view to see only current period metrics.

### Key Entities

- **Date Range**: Represents a selected time period with start and end dates
- **Metric Value**: The calculated value for a specific metric within a date range
- **Comparison Result**: Contains both period values, the calculated percentage change, and direction indicator
- **Comparison Preset**: Predefined pairs of date ranges (e.g., "This Week vs Last Week")

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can select a predefined period comparison and see results within 2 seconds of selection.
- **SC-002**: 95% of users can successfully complete a period comparison task without requiring assistance.
- **SC-003**: Percentage change calculations are accurate to 2 decimal places for all numeric metrics.
- **SC-004**: Users can switch between comparison views and single-period views without page reload.
- **SC-005**: The comparison feature works across all metric types displayed on the dashboard (revenue, users, sessions, conversions, etc.).
- **SC-006**: Custom date range selection prevents overlapping periods and provides clear validation feedback.
