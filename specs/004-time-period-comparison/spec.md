# Feature Specification: Time Period Comparison

**Feature Branch**: `004-time-period-comparison`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare Current Period to Previous Period (Priority: P1)

As a business analyst, I want to compare my current week's performance metrics against the previous week so I can quickly identify trends and understand if my metrics are improving or declining.

**Why this priority**: This is the core value proposition - users need immediate insight into whether their metrics are trending up or down compared to the previous period.

**Independent Test**: Can be tested by selecting two date ranges and verifying both values and percentage change are displayed correctly for any metric.

**Acceptance Scenarios**:

1. **Given** the user is viewing a metrics dashboard, **When** they select a comparison mode with "this week vs last week" preset, **Then** the dashboard displays both the current period value and the previous period value with an calculated percentage change indicator.

2. **Given** the user is viewing metrics with comparison enabled, **When** the current period value is higher than the previous period, **Then** the percentage change displays as a positive number with an upward indicator (e.g., "+25%").

3. **Given** the user is viewing metrics with comparison enabled, **When** the current period value is lower than the previous period, **Then** the percentage change displays as a negative number with a downward indicator (e.g., "-15%").

---

### User Story 2 - Select Custom Comparison Periods (Priority: P2)

As a user, I want to define custom date ranges for both the current and comparison periods so I can analyze specific timeframes that are relevant to my business needs.

**Why this priority**: While presets are convenient, business users often need to compare non-standard periods (e.g., this month vs. same month last year, or a campaign period vs. pre-campaign).

**Independent Test**: Can be tested by manually selecting different start and end dates for both periods and verifying the correct data is displayed.

**Acceptance Scenarios**:

1. **Given** the comparison feature is enabled, **When** the user selects custom start and end dates for the comparison period, **Then** the system displays metrics for both the primary and comparison date ranges.

2. **Given** the user enters a comparison period that overlaps with the primary period, **When** they apply the selection, **Then** the system displays a validation message indicating the periods cannot overlap.

---

### User Story 3 - View Percentage Change Across Multiple Metrics (Priority: P3)

As a user, I want to see percentage change indicators across all metrics on my dashboard simultaneously so I can quickly assess overall performance at a glance.

**Why this priority**: Users typically monitor multiple KPIs at once and need a quick visual summary of which areas are improving or declining without clicking into each metric individually.

**Independent Test**: Can be tested by enabling comparison mode and verifying all visible metrics display their respective percentage changes.

**Acceptance Scenarios**:

1. **Given** the dashboard displays multiple metrics in a grid, **When** comparison mode is active, **Then** each metric card displays its percentage change alongside the absolute values.

2. **Given** a metric has no data for the comparison period (e.g., new metric), **When** comparison is enabled, **Then** the metric displays "N/A" or "-" for the percentage change instead of a number.

---

### Edge Cases

- What happens when the comparison period has zero values? Display "N/A" for percentage change as division by zero is undefined.
- How does the system handle incomplete periods (e.g., comparing a full week to a partial week)? Display a warning indicator noting the period lengths differ.
- What happens when date ranges span across daylight saving time transitions? Use consistent timezone handling for both periods.
- How does the system handle metrics with negative baseline values? Display percentage change but note that the interpretation differs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a comparison mode toggle or selector that enables dual-period view on metrics displays.
- **FR-002**: The system MUST support predefined period presets including "this week vs last week", "this month vs last month", and "this quarter vs last quarter".
- **FR-003**: The system MUST allow users to define custom date ranges for both the primary and comparison periods.
- **FR-004**: The system MUST calculate percentage change using the formula: ((current - previous) / previous) * 100.
- **FR-005**: The system MUST display percentage change with appropriate visual indicators (up arrow for positive, down arrow for negative).
- **FR-006**: The system MUST validate that comparison periods do not overlap and display an error if they do.
- **FR-007**: The system MUST handle edge cases where the comparison period has zero or missing values by displaying "N/A" instead of calculating invalid percentages.
- **FR-008**: The system MUST maintain the comparison state (selected periods) when the user navigates between different dashboard views or refreshes the page.
- **FR-009**: The system MUST display both the primary value and comparison value so users can see the absolute numbers alongside the percentage change.

### Key Entities *(include if feature involves data)*

- **Date Range Pair**: A data structure containing two date ranges (primary and comparison) that define the time periods being compared.
- **Comparison Result**: The calculated metrics for both periods including absolute values and percentage change.
- **Period Preset**: Predefined comparison options (this week vs last week, etc.) that users can quickly select.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can enable period comparison and see percentage change indicators within 3 clicks from any metrics dashboard view.
- **SC-002**: All predefined period presets (this week/month/quarter vs previous) are available and selectable.
- **SC-003**: Custom date range selection allows users to pick any valid date range for both comparison periods.
- **SC-004**: Percentage change calculations are mathematically correct for all positive baseline values.
- **SC-005**: Invalid comparisons (overlapping dates, zero baseline) are clearly communicated to users with actionable error messages.
- **SC-006**: Dashboard maintains comparison state during a session without requiring re-selection on each page load.

## Assumptions

- The application already has date range selection functionality that can be extended for comparison mode.
- Metrics are stored with timestamp data that allows filtering by arbitrary date ranges.
- The existing dashboard architecture supports displaying additional data points (comparison values) alongside primary metrics.
- Users have appropriate permissions to view the metrics being compared.
- Date/time handling follows consistent timezone rules across the application.
