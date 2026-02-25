# Feature Specification: Time Period Comparison

**Feature Branch**: `001-period-comparison`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Implement time period comparison: add ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compare with Previous Period (Priority: P1)

As a user viewing analytics, I want to compare my current selected time period with the immediately preceding period so I can understand how my metrics have changed.

**Why this priority**: This is the most common comparison use case - understanding whether traffic, conversions, or other metrics are up or down compared to the last period.

**Independent Test**: User selects a date range (e.g., "Last 7 days") and enables "Previous period" comparison. The UI displays percentage changes for all metrics. Can be tested by selecting any period and verifying comparison data appears.

**Acceptance Scenarios**:

1. **Given** user has selected "Last 7 days" as the primary period, **When** they enable "Previous period" comparison, **Then** the system automatically selects "7 days before the current selection" as the comparison period and displays percentage change for each metric.

2. **Given** user has selected "This month" as the primary period, **When** they enable "Previous period" comparison, **Then** the system compares with "Last month" and displays percentage changes.

3. **Given** comparison is enabled, **When** metrics load, **Then** each metric displays the current value, the comparison value, and the percentage change with a visual indicator (arrow).

---

### User Story 2 - Compare with Same Period Last Year (Priority: P2)

As a user viewing analytics, I want to compare my current period with the same period from the previous year so I can identify year-over-year trends.

**Why this priority**: Year-over-year comparison is essential for understanding seasonal trends and long-term growth patterns, especially for businesses with significant seasonal variation.

**Independent Test**: User selects a date range and enables "Year over year" comparison. The UI displays percentage changes comparing current period to the same dates in the previous year.

**Acceptance Scenarios**:

1. **Given** user has selected "Last 30 days" and enables "Year over year", **When** the data loads, **Then** the comparison period is "Same 30 days in the previous year" and percentage changes are displayed.

2. **Given** user compares January 2026 with January 2025, **When** "Year over year" is selected, **Then** the system correctly handles leap year differences and displays accurate comparisons.

---

### User Story 3 - Custom Date Range Comparison (Priority: P2)

As a user viewing analytics, I want to compare my selected period with an arbitrary custom date range of my choosing.

**Why this priority**: Allows flexibility to compare any two periods that are relevant to the user's specific analysis needs, beyond the preset previous period or year-over-year options.

**Independent Test**: User selects a custom comparison date range via the date picker. The system uses those exact dates for comparison.

**Acceptance Scenarios**:

1. **Given** user has selected "Last 7 days" as primary period, **When** they choose "Custom period" and select "Jan 1-7, 2026" as comparison, **Then** metrics are compared against Jan 1-7, 2026.

2. **Given** user has selected a custom comparison range, **When** they return to the dashboard later, **Then** the custom comparison dates are preserved in the URL.

---

### User Story 4 - Match Day of Week Option (Priority: P3)

As a user, I want the option to compare the same days of the week (e.g., compare all Mondays with Mondays) so my comparison accounts for day-of-week variations in traffic.

**Why this priority**: Many websites and apps have significant day-of-week patterns. Matching days of the week provides a more accurate comparison when weekday vs weekend behavior differs.

**Independent Test**: User enables "Match day of week" option. The comparison period is adjusted to match the same days of the week as the primary period.

**Acceptance Scenarios**:

1. **Given** primary period is "Mon-Fri of this week", **When** "Match day of week" is enabled, **Then** comparison includes only Mondays through Fridays from the comparison period.

2. **Given** primary period includes weekends, **When** "Match day of week" is enabled, **Then** comparison period is adjusted to include the same weekend days.

---

### User Story 5 - Visual Display of Changes (Priority: P1)

As a user, I want to see percentage changes displayed clearly with visual indicators so I can quickly understand metric trends at a glance.

**Why this priority**: Quick visual comprehension of trends is essential for analytics dashboards. Users need to immediately see whether metrics are up or down.

**Independent Test**: User enables any comparison mode. Each metric displays with a color-coded arrow (green for positive, red for negative) and the percentage change number.

**Acceptance Scenarios**:

1. **Given** a metric has increased, **When** comparison displays, **Then** a green upward arrow appears with the positive percentage (e.g., "+25%").

2. **Given** a metric has decreased, **When** comparison displays, **Then** a red downward arrow appears with the negative percentage (e.g., "-15%").

3. **Given** bounce rate metric, **When** it decreases, **Then** this is displayed as a positive change (green up arrow) because lower bounce rate is desirable.

4. **Given** metric comparison results in no change, **When** displayed, **Then** shows "0%" with neutral styling.

---

### Edge Cases

- What happens when the comparison period has no data? Display "N/A" or "-".
- What happens when comparing a period with zero values against a non-zero period? Display "+100%" or "-100%" as appropriate.
- What happens when both periods have zero values? Display "0%" with neutral styling.
- How does the system handle partial data at period boundaries? Use consistent time boundaries.
- What happens when custom comparison dates overlap with primary dates? Allow but display warning.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to select a comparison mode from: Previous Period, Year over Year, Custom Period, or Off.
- **FR-002**: System MUST automatically calculate the Previous Period dates based on the primary period length.
- **FR-003**: System MUST automatically calculate Year over Year dates by shifting the primary period back one year.
- **FR-004**: System MUST allow users to select custom comparison dates via a date range picker.
- **FR-005**: System MUST display percentage change for each metric when comparison is enabled.
- **FR-006**: System MUST display visual indicators (colored arrows) showing direction of change.
- **FR-007**: System MUST invert bounce rate logic (decrease is positive, increase is negative).
- **FR-008**: System MUST provide a "Match day of week" option to align comparison days.
- **FR-009**: System MUST preserve comparison state in the URL for shareability.
- **FR-010**: System MUST handle edge cases gracefully (no data, zero values, etc.) with appropriate display.

### Key Entities

- **Primary Period**: The main date range selected by the user for analysis.
- **Comparison Period**: The secondary date range used for comparison calculations.
- **Comparison Mode**: The selected comparison strategy (previous_period, year_over_year, custom, off).
- **Metric Value**: The numeric value for a metric within a specific period.
- **Percentage Change**: The calculated difference between primary and comparison values, expressed as a percentage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can enable comparison and see percentage changes displayed within 2 seconds of selecting a comparison mode.
- **SC-002**: 100% of metrics display comparison data when comparison is enabled.
- **SC-003**: Comparison state persists in URL and restores correctly when sharing or reloading the page.
- **SC-004**: Year-over-year comparison correctly handles all month boundaries including February leap year transitions.
- **SC-005**: "Match day of week" option produces accurate comparisons when enabled.

## Assumptions

- The analytics platform already supports date range selection for primary periods.
- Metrics are calculated and returned from the backend with comparison data.
- The UI framework supports the necessary components for dropdowns and date pickers.
- Users have authenticated access to view analytics data.
