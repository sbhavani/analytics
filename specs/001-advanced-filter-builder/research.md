# Research: Advanced Filter Builder

## Overview

This document captures design decisions for the Advanced Filter Builder feature based on analysis of the existing Plausible Analytics codebase.

## Key Findings from Codebase Analysis

### Existing Filter System

**Current Implementation** (`assets/js/dashboard/util/filters.js`):
- Filters are represented as arrays: `[operation, dimension, values]`
- Operations: `is`, `is-not`, `contains`, `greater`, `less`
- Dimensions: `country`, `browser`, `device`, `page`, `source`, etc.
- Multiple filters are combined with implicit AND logic

**Existing Segment System** (`assets/js/dashboard/filtering/segments.ts`):
- Segments store filters as `Filter[]` array
- Saved segments have `id`, `name`, `type` (personal/site), ownership
- Segments can be applied as a special filter type
- API stores segment data with filters and labels

### Design Decisions

#### Decision 1: Filter Group Structure

**Chosen Approach**: Nested filter groups with explicit AND/OR operators

```typescript
type FilterCondition = {
  dimension: string
  operator: 'is' | 'is-not' | 'contains' | 'greater' | 'less'
  value: string | number | string[]
}

type FilterGroup = {
  operator: 'AND' | 'OR'
  children: (FilterCondition | FilterGroup)[]
}
```

**Rationale**: This structure is:
- Backward compatible with existing flat filter array format
- Extensible for nested groups
- Natural representation of boolean logic

**Alternatives Considered**:
- Flat array with explicit join operators: Rejected - harder to represent nesting
- Separate condition/group tables in DB: Rejected - over-engineering for UI-driven feature

---

#### Decision 2: UI Component Architecture

**Chosen Approach**: Extend existing FilterModal component with nested group support

**Rationale**:
- Reuses existing modal infrastructure, styling, and state management
- Familiar UX pattern for existing users
- Lower development effort

**Alternatives Considered**:
- Separate AdvancedFilterBuilder page: Rejected - more development, breaks context
- Inline expandable filter builder: Rejected - complex state management

---

#### Decision 3: Filter Expression Storage

**Chosen Approach**: Store as JSON blob in existing segments table

**Rationale**:
- Schema already exists for segments
- No migration needed for new columns
- Flexible schema for evolving filter expressions
- PostgreSQL JSONB handles query patterns adequately

**Alternatives Considered**:
- Separate filter_conditions table: Rejected - premature optimization
- Serialize to string: Rejected - harder to query/debug

---

#### Decision 4: Real-time Preview Count

**Chosen Approach**: Debounced API query on filter change (300ms debounce)

**Rationale**:
- Existing API pattern for filter previews
- 2-second target (SC-004) achievable with debounce
- Avoids rate limiting issues

**Alternatives Considered**:
- WebSocket streaming: Rejected - infrastructure overhead
- Client-side counting: Rejected - requires full dataset access

---

## Implementation Notes

### Privacy Compliance

The feature uses only anonymous visitor attributes:
- Country, region (geo)
- Device type, browser, OS (technical)
- Source, referrer (behavioral)
- No personal data collected per GDPR/CCPA requirements

### Performance Considerations

- Filter evaluation happens in ClickHouse (existing infrastructure)
- Limit of 20 conditions / 5 nesting levels prevents query explosion
- Preview queries should use existing materialized counts where possible
- Consider caching filter value options (countries, sources)

### Testing Strategy

Following TDD principles from constitution:
1. Unit tests for filter expression parsing/serialization
2. Integration tests for segment CRUD via API
3. E2E tests for UI interactions (filter creation, nesting, save)
