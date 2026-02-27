# Feature Specification: Advanced Filter Builder

**Feature Branch**: `011-advanced-filter-builder`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Add advanced filter builder: create a UI component that allows users to combine multiple filter conditions (AND/OR) for custom visitor segments."

## Overview

This feature adds a visual filter builder interface that enables users to create complex visitor segments by combining multiple filter conditions using AND/OR logic. Users can define rules based on visitor attributes, combine them into groups, and save the resulting segments for repeated use.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Simple Filter Condition (Priority: P1)

A marketing analyst wants to create a basic segment by applying a single filter condition to identify visitors from a specific country.

**Why this priority**: This is the foundational capability - users must be able to create basic segments before they can use advanced combinations. Without this, the entire feature is unusable.

**Independent Test**: Can be fully tested by applying one filter condition (e.g., "Country = United States") and verifying that only matching visitors are displayed in the segment.

**Acceptance Scenarios**:

1. **Given** the filter builder is empty, **When** the user adds a condition with attribute "Country", operator "equals", and value "United States", **Then** the segment includes only visitors from the United States.

2. **Given** a condition exists, **When** the user removes that condition, **Then** the filter is cleared and all visitors are included.

---

### User Story 2 - Combine Two Conditions with AND Logic (Priority: P1)

A product manager wants to identify visitors who meet BOTH criteria: visited a specific page AND spent more than a certain amount.

**Why this priority**: Combining conditions with AND is the most common use case for segmentation - narrowing down to a specific audience.

**Independent Test**: Can be tested by creating two conditions combined with AND and verifying only visitors meeting both criteria are included.

**Acceptance Scenarios**:

1. **Given** two conditions are added, **When** the user selects AND logic between them, **Then** only visitors matching BOTH conditions are included in the segment.

2. **Given** two conditions with AND logic, **When** neither condition is met by any visitor, **Then** the segment returns zero visitors with an appropriate message.

---

### User Story 3 - Combine Conditions with OR Logic (Priority: P1)

A marketing team member wants to create a segment of visitors who arrived from either social media OR email campaigns.

**Why this priority**: OR logic is essential for broadening segments to include multiple traffic sources.

**Independent Test**: Can be tested by creating two conditions combined with OR and verifying visitors matching either condition are included.

**Acceptance Scenarios**:

1. **Given** two conditions are added, **When** the user selects OR logic between them, **Then** visitors matching EITHER condition are included in the segment.

2. **Given** a visitor matches both conditions in an OR group, **Then** the visitor appears only once in the results.

---

### User Story 4 - Create Nested Filter Groups (Priority: P2)

An analyst wants to create a complex segment: (Country = US AND Page Views > 5) OR (Country = UK AND Conversion = true).

**Why this priority**: Advanced users need nested logic to create sophisticated segments that address complex business questions.

**Independent Test**: Can be tested by creating nested groups with different AND/OR combinations at each level and verifying the results match the expected logic.

**Acceptance Scenarios**:

1. **Given** nested filter groups exist, **When** the user modifies a nested condition, **Then** the outer groups maintain their logic correctly.

2. **Given** a complex nested structure, **When** the user previews the segment, **Then** the result count is accurate according to the defined logic.

---

### User Story 5 - Save and Reuse Segments (Priority: P2)

A recurring user wants to save a frequently-used segment configuration for quick access in the future.

**Why this priority**: Users typically need to apply the same segment multiple times across different analysis sessions.

**Independent Test**: Can be tested by saving a segment, then loading it later and verifying the filter configuration is identical.

**Acceptance Scenarios**:

1. **Given** a filter configuration is complete, **When** the user saves it with a name, **Then** the segment appears in the saved segments list.

2. **Given** a saved segment exists, **When** the user selects it, **Then** all conditions and logic are restored exactly as they were saved.

3. **Given** a saved segment is loaded, **When** the user modifies it, **Then** they can save it as a new segment or update the existing one.

---

### User Story 6 - Edit Existing Segments (Priority: P3)

A user wants to modify a previously created segment without starting from scratch.

**Why this priority**: Improves user efficiency by allowing iterative refinement of segments.

**Independent Test**: Can be tested by loading an existing segment, modifying one condition, and verifying the change is applied.

**Acceptance Scenarios**:

1. **Given** a saved segment is loaded, **When** the user changes an operator, **Then** the segment updates immediately.

2. **Given** a segment is modified, **When** the user discards changes, **Then** the original configuration is restored.

---

### Edge Cases

- What happens when a segment returns zero visitors? - Display a helpful message suggesting the user relax their filter conditions.
- How does the system handle very large result sets? - Implement pagination or sampling to maintain performance.
- What happens when a filter attribute becomes unavailable? - Notify user and allow them to remove or update the affected condition.
- What happens with duplicate condition entries? - Allow them but warn the user about potential redundancy.
- How does the system handle very deep nesting (e.g., 10+ levels)? - Set a reasonable maximum depth and inform users when it's reached.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a visual interface for adding, removing, and modifying filter conditions.
- **FR-002**: The system MUST allow users to combine two or more conditions using AND logic (all conditions must match).
- **FR-003**: The system MUST allow users to combine two or more conditions using OR logic (any condition must match).
- **FR-004**: The system MUST support nested groups where groups can contain both individual conditions and other groups.
- **FR-005**: Users MUST be able to save filter configurations with a custom name for future use.
- **FR-006**: Users MUST be able to load previously saved filter configurations.
- **FR-007**: Users MUST be able to edit existing saved segments.
- **FR-008**: Users MUST be able to delete saved segments.
- **FR-009**: The system MUST display a preview of matching visitors as conditions are added or modified.
- **FR-010**: The system MUST validate filter configurations before saving (e.g., ensure required fields are filled).
- **FR-011**: The system MUST provide a clear visual representation of the filter logic tree.
- **FR-012**: Users MUST be able to duplicate an existing segment.
- **FR-013**: The system MUST support all existing visitor attributes from the Plausible Analytics filter system: visit properties (source, channel, referrer, utm parameters, screen, device, browser, os, country, region, city, entry/exit pages), event properties (name, page, goal, hostname), and custom properties via event:props:* pattern.

### Key Entities

- **Filter Condition**: A single rule defining a visitor attribute, comparison operator, and value (e.g., "Country equals United States").
- **Filter Group**: A collection of conditions and/or nested groups combined with a logical operator (AND or OR).
- **Visitor Segment**: A named, saved filter configuration that can be loaded and applied to visitor data.
- **Operator**: The comparison type used in a condition (equals, not equals, contains, greater than, less than, between, etc.).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a simple single-condition segment in under 30 seconds.
- **SC-002**: Users can create a complex multi-group segment with nested AND/OR logic in under 3 minutes.
- **SC-003**: 95% of users successfully complete basic segment creation (single condition) on their first attempt.
- **SC-004**: 90% of users can create a segment with at least two combined conditions without assistance.
- **SC-005**: Saved segments can be retrieved and applied in under 5 seconds.
- **SC-006**: Users can understand their filter configuration from the visual representation without reading documentation.
- **SC-007**: Segment preview results update within 2 seconds of filter changes for segments returning fewer than 10,000 visitors.

## Assumptions

1. **Assumed**: The application already has visitor data with common attributes (country, device, traffic source, etc.) available for filtering.
2. **Assumed**: There is an existing save/load mechanism for user preferences that can be extended for segments.
3. **Assumed**: The maximum nesting depth for filter groups is 5 levels (to prevent overly complex queries).
4. **Assumed**: Each filter group can contain up to 10 conditions or nested groups.
5. **Assumed**: Segment names are limited to 100 characters and must be unique per user.
