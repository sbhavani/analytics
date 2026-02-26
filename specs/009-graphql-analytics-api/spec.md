# Feature Specification: GraphQL Analytics API

**Feature Branch**: `009-graphql-analytics-api`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Add GraphQL API: implement a GraphQL endpoint that exposes analytics data including pageviews, events, and custom metrics with filtering and aggregation."

## User Scenarios & Testing

### User Story 1 - Query Analytics Data Programmatically (Priority: P1)

A developer building a custom dashboard or integration needs to retrieve analytics data programmatically using a flexible query language.

**Why this priority**: This is the core value proposition - enabling programmatic access to analytics data that currently requires using the existing REST APIs or the dashboard UI.

**Independent Test**: Can be fully tested by sending GraphQL queries and receiving correct analytics data for a given site, verifying data matches expected values from the existing stats system.

**Acceptance Scenarios**:

1. **Given** a valid API key and site ID, **When** requesting pageview counts, **Then** the response returns accurate pageview metrics for the specified time period
2. **Given** a valid API key and site ID, **When** requesting custom event data, **Then** the response includes all custom events with their properties
3. **Given** a valid API key, **When** querying metrics for a non-existent site, **Then** the API returns an appropriate error indicating the site was not found
4. **Given** an invalid or missing API key, **When** making any GraphQL request, **Then** the API returns an authentication error

---

### User Story 2 - Filter Analytics Data (Priority: P1)

A data analyst needs to filter analytics data by various dimensions (date range, geography, traffic source, device, URL) to get specific insights.

**Why this priority**: Filtering is essential for meaningful analytics analysis. Without filtering capabilities, users cannot drill down into specific segments of their data.

**Independent Test**: Can be tested by applying various filters to queries and verifying that results are correctly limited to matching records.

**Acceptance Scenarios**:

1. **Given** analytics data exists, **When** filtering by date range, **Then** only data within that date range is returned
2. **Given** analytics data exists, **When** filtering by country code, **Then** only events from that country are included
3. **Given** analytics data exists, **When** filtering by multiple dimensions (date + country + device), **Then** all filters are applied correctly (AND logic)
4. **Given** analytics data exists, **When** filtering by URL path, **Then** only events matching that path are returned

---

### User Story 3 - Aggregate Metrics (Priority: P1)

A product manager needs to aggregate analytics data to see trends and summary statistics over time.

**Why this priority**: Raw event data is rarely useful; aggregation transforms data into actionable insights showing totals, averages, and trends.

**Independent Test**: Can be tested by requesting aggregated metrics and verifying calculations match expected values (e.g., sum of pageviews, average session duration).

**Acceptance Scenarios**:

1. **Given** a time period with multiple events, **When** requesting total pageview count, **Then** the sum of all pageviews in that period is returned
2. **Given** a time period, **When** requesting average engagement time, **Then** the mean engagement time across all sessions is calculated correctly
3. **Given** multiple time periods, **When** requesting timeseries data grouped by day, **Then** data points are returned for each day with correct aggregated values
4. **Given** multiple events, **When** requesting breakdown by a dimension (e.g., country), **Then** results are grouped and sorted by the metric

---

### User Story 4 - Query Custom Metrics (Priority: P2)

A user with custom-defined metrics needs to retrieve these through the GraphQL API.

**Why this priority**: Custom metrics allow users to track business-specific KPIs beyond standard pageviews and events. These must be accessible via the new API.

**Independent Test**: Can be tested by creating a custom metric and querying it via GraphQL, verifying the returned values match calculations from raw data.

**Acceptance Scenarios**:

1. **Given** a custom metric is defined for a site, **When** querying that metric, **Then** the calculated value is returned
2. **Given** a custom metric is requested that does not exist, **Then** the API returns an appropriate error

---

### Edge Cases

- What happens when requesting data for a site with no analytics data?
- How does the system handle extremely large result sets (pagination)?
- What happens when filter values match no data?
- How does the API handle date ranges spanning multiple years?
- What happens when requesting incompatible aggregation types for certain metrics?

## Requirements

### Functional Requirements

- **FR-001**: System MUST provide a GraphQL endpoint accessible at a dedicated URL path
- **FR-002**: System MUST authenticate API requests using API keys tied to user accounts
- **FR-003**: Users MUST be able to query pageview data including count, unique visitors, and page-specific metrics
- **FR-004**: Users MUST be able to query custom event data including event name, properties, and timestamps
- **FR-005**: Users MUST be able to filter queries by date range (start date and end date)
- **FR-006**: Users MUST be able to filter queries by site (site ID)
- **FR-007**: Users MUST be able to filter queries by geographic dimensions (country, region, city)
- **FR-008**: Users MUST be able to filter queries by traffic source (referrer, UTM parameters)
- **FR-009**: Users MUST be able to filter queries by device type (browser, operating system, screen size)
- **FR-010**: Users MUST be able to filter queries by URL path
- **FR-011**: Users MUST be able to aggregate data using count (totals)
- **FR-012**: Users MUST be able to aggregate data using sum
- **FR-013**: Users MUST be able to aggregate data using average
- **FR-014**: Users MUST be able to retrieve time-series data with configurable granularity (hourly, daily, weekly, monthly)
- **FR-015**: Users MUST be able to breakdown data by various dimensions (country, source, page, etc.)
- **FR-016**: Users MUST be able to query custom metrics defined for their sites
- **FR-017**: System MUST support pagination for queries returning multiple records
- **FR-018**: System MUST return meaningful error messages for invalid queries
- **FR-019**: System MUST enforce rate limiting to prevent abuse

### Key Entities

- **Site**: The website being tracked, identified by site ID
- **Pageview Event**: A view of a page, includes URL, referrer, timestamp, user/session identifiers
- **Custom Event**: A named event with optional properties, triggered by site scripts
- **Session**: A user session containing multiple events, with engagement metrics (duration, bounce, pageviews)
- **Custom Metric**: A user-defined calculation based on events or session data
- **Goal**: A target action (page view or custom event) used for conversion tracking

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can retrieve analytics data for a single site in under 5 seconds for typical queries
- **SC-002**: The GraphQL API supports all major filtering dimensions currently available in the existing stats API
- **SC-003**: Users can successfully retrieve pageview counts, unique visitors, and custom event data through GraphQL queries
- **SC-004**: Rate limiting allows at least 100 requests per minute per API key without throttling
- **SC-005**: Invalid GraphQL queries return descriptive error messages within 1 second
- **SC-006**: The API returns accurate data matching the existing REST stats API within 1% variance for aggregated metrics

## Assumptions

- Authentication will use existing API key infrastructure from the codebase
- The GraphQL schema will mirror capabilities of the existing Stats API (lib/plausible_web/controllers/api/stats_controller.ex)
- Custom metrics are pre-defined in the system and associated with sites
- Rate limiting will follow existing patterns used for other API endpoints
- Pagination will use standard cursor-based or offset-based approaches
