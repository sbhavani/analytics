# Research: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments
**Date**: 2026-02-25

## Overview

This document contains research findings to inform the implementation of an advanced filter builder that allows users to combine multiple filter conditions with AND/OR logic for custom visitor segments.

## Existing System Analysis

### Current Filter Implementation

The codebase already has a filter system with the following characteristics:

1. **Filter Format**: Filters are stored as arrays: `[operation, dimension, clauses]`
   - Example: `['is', 'country', ['US']]`
   - Operations: `is`, `is_not`, `contains`, `contains_not`

2. **Filter Groups**: Related filters are grouped by category (page, source, location, etc.)

3. **Segments**: Already exist as saved filter configurations with metadata:
   - `SavedSegment` type with id, name, type (personal/site), timestamps
   - Stored in PostgreSQL with ClickHouse for analytics queries

4. **Key Files**:
   - `assets/js/dashboard/util/filters.js` - Filter utilities and operations
   - `assets/js/dashboard/filtering/segments.ts` - Segment types and logic
   - `assets/js/dashboard/stats/modals/filter-modal.js` - Current filter UI
   - `lib/plausible/segments.ex` - Backend segment storage

## Technology Stack

- **Frontend**: React 18.3, TypeScript 5.5, TailwindCSS
- **UI Components**: Headless UI, Heroicons
- **State Management**: React Context + TanStack Query
- **Testing**: Jest

## Implementation Approach

### Decision: Extend Existing Filter System

**Rationale**: The existing filter infrastructure (filter format, segment storage, URL serialization) is well-established. Adding AND/OR logic and nested groups can be done by:

1. **Filter Condition Format**: Extend to include optional `logicalOperator` field
   - Current: `[operation, dimension, clauses]`
   - Extended: `{ filter: [operation, dimension, clauses], operator: 'AND' | 'OR' }`

2. **Group Format**: Add a `type` field to distinguish between single conditions and groups
   - Condition: `{ type: 'condition', ... }`
   - Group: `{ type: 'group', operator: 'AND' | 'OR', children: [] }`

3. **UI Components**:
   - `FilterBuilder` - Main container component
   - `FilterConditionRow` - Individual filter row
   - `FilterGroup` - Container for nested conditions
   - `LogicalOperatorSelector` - AND/OR toggle between conditions

### Alternatives Considered

1. **Separate Filter Builder Modal**: Create entirely new modal for advanced filters
   - Rejected: Duplicates code, confusing UX

2. **Query String Format Change**: Modify URL serialization for nested groups
   - Rejected: Would break backward compatibility with existing shared links

## Performance Considerations

- **Filter Evaluation**: Must remain efficient for preview queries (target: 3s for 10 conditions)
- **State Updates**: Use React.memo and proper state batching
- **Lazy Evaluation**: For large result sets, use pagination

## Privacy Compliance

- No personal data collection added
- All filters operate on anonymous visitor attributes
- Existing GDPR/CCPA compliance maintained

## Notes

- The existing filter modal can be enhanced with an "Advanced" toggle to switch to the builder mode
- Saved segments already support complex filter configurations; this feature makes them easier to create
