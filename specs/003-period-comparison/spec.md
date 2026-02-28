# Feature Specification: Time Period Comparison

**Feature Branch**: `003-period-comparison`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare metrics between current and previous period (Priority: P1)

As a website analyst, I want to compare my current period metrics (e.g., this week) against a previous period (e.g., last week) so that I can understand how my metrics have changed over time.

**Why this priority**: This is the primary use case for time period comparison - understanding trends and growth/decline in key metrics like visitors, pageviews, and conversions.

**Independent Test**: Can be tested by selecting a date range, enabling comparison mode, and verifying that both current and previous period data are displayed with percentage changes.

**Acceptance Scenarios**:

1. **Given** a user has data for the current week, **When** they enable comparison to "previous period" (last week), **Then** the dashboard displays both current week metrics and last week metrics with percentage change indicators.

2. **Given** a user views a metric card, **When** comparison is enabled, **Then** the metric shows: current value, previous period value in parentheses, and percentage change with directional arrow (up green, down red).

3. **Given** a user selects a custom date range, **When** they choose "compare to previous period", **Then** the system automatically calculates and displays the equivalent previous period based on the selected range duration.

---

### User Story 2 - Year-over-year comparison (Priority: P2)

As a website analyst, I want to compare metrics against the same period last year so that I can identify annual trends and seasonality in my data.

**Why this priority**: Year-over-year analysis is critical for understanding long-term trends and accounting for seasonal variations.

**Independent Test**: Can be tested by selecting a date range and enabling year-over-year comparison, verifying that data from 12 months prior is displayed alongside current data.

**Acceptance Scenarios**:

1. **Given** a user has data from the previous year, **When** they enable "year-over-year" comparison, **Then** the dashboard displays current period metrics alongside metrics from the same dates in the previous year.

2. **Given** a user selects January 2026, **When** they enable year-over-year comparison, **Then** the comparison shows January 2025 data as the baseline.

---

### User Story 3 - Compare against custom date range (Priority: P3)

As a website analyst, I want to compare my current metrics against a specific custom date range of my choosing so that I can benchmark performance against any historical period.

**Why this priority**: Provides maximum flexibility for analysts who need to compare against non-standard periods (e.g., campaign periods, special events).

**Independent Test**: Can be tested by manually selecting a custom comparison date range and verifying the comparison data displays correctly.

**Acceptance Scenarios**:

1. **Given** a user wants to compare against a specific period, **When** they select "custom range" as comparison type, **Then** they can specify exact start and end dates for comparison.

2. **Given** a user has selected a comparison range, **When** they navigate to different dashboard pages, **Then** the comparison selection persists across all pages.

---

### Edge Cases

- What happens when there is no data for the comparison period? The system should display "N/A" or "-" for percentage change with a neutral indicator.
- What happens when comparing against a period with zero values? The system should handle division by zero gracefully, displaying appropriate messaging like "No previous data" instead of an error.
- How does the system handle timezone differences when calculating previous periods? The comparison should use consistent timezone interpretation.
- What happens when comparing a period that partially overlaps with available data? The system should use only the available data for each period.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow users to select a comparison mode: previous period, year-over-year, or custom date range.
- **FR-002**: The system MUST automatically calculate the previous period dates based on the selected date range (e.g., selecting "this week" compares to "last week").
- **FR-003**: The system MUST display percentage change for all key metrics when comparison is enabled.
- **FR-004**: The system MUST use color-coded directional indicators: green arrow up for positive change, red arrow down for negative change.
- **FR-005**: The system MUST allow users to manually specify custom comparison date ranges.
- **FR-006**: The system MUST persist comparison selection across dashboard navigation within the same session.
- **FR-007**: The system MUST display both current and comparison values in metric cards when comparison is active.
- **FR-008**: The system MUST handle cases where comparison period has no data gracefully without displaying errors.
- **FR-009**: The system MUST support comparison across all standard date period types: day, week, month, and custom ranges.

### Key Entities

- **Date Range**: Represents the time period being analyzed (start date, end date, period type)
- **Comparison Period**: Represents the baseline period for comparison (can be auto-calculated or user-specified)
- **Metric Value**: Contains current value, comparison value, and calculated percentage change
- **Comparison Mode**: Enum representing the comparison strategy (previous_period, year_over_year, custom)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can enable period comparison and see percentage changes within 2 clicks from the main dashboard.
- **SC-002**: All displayed metrics show both current and comparison values with percentage change when comparison is enabled.
- **SC-003**: Comparison selection persists correctly across at least 5 page navigations within a session.
- **SC-004**: System handles missing comparison data gracefully - users see clear "no data" indicators rather than errors.
- **SC-005**: Year-over-year comparison correctly identifies and displays data from 12 months prior to the selected period.

## Assumptions

- The analytics platform already stores historical data and can retrieve data for any past date range.
- The existing metric calculation infrastructure can be reused for comparison calculations.
- The UI already has components for displaying metrics that can be extended to show comparison values.
- Users have appropriate permissions to view analytics data (authentication/authorization already handled).
