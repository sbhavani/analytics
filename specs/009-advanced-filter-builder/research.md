# Research: Advanced Filter Builder

**Feature**: Advanced Filter Builder for visitor segments
**Date**: 2026-02-26
**Source**: [spec.md](./spec.md)

## Decisions

### D1: Existing Filter System Extension

**Decision**: Extend the existing `WhereBuilder` and filter query system rather than creating a separate filter builder.

**Rationale**: The codebase already has a robust filtering system (`lib/plausible/stats/sql/where_builder.ex`) that handles visitor and session filtering. The new filter builder UI will generate filter payloads compatible with this existing system.

**Alternatives Considered**:
- Create a completely new filter system - REJECTED: Would duplicate existing functionality
- Use a separate microservice for filters - REJECTED: Over-engineering, violates YAGNI principle

---

### D2: Filter Condition Storage

**Decision**: Store filter definitions as JSON in the database.

**Rationale**: Filter conditions can have varying structures (different operators, nested groups), making a flexible JSON column more appropriate than a fixed schema.

**Alternatives Considered**:
- Separate tables for conditions and groups - REJECTED: Over-complexity for this feature
- Serialize to Ecto schema - REJECTED: Adds unnecessary abstraction layer

---

### D3: Real-time Count Updates

**Decision**: Use debounced API polling for real-time visitor count updates.

**Rationale**: The existing stats API can handle the filter query. Debouncing prevents excessive API calls during rapid UI interactions.

**Alternatives Considered**:
- WebSocket connection - REJECTED: Adds infrastructure complexity; not needed for <2s updates
- Server-sent events - REJECTED: Requires new backend infrastructure

---

### D4: UI Component Architecture

**Decision**: Create a composable React component hierarchy for the filter builder.

**Rationale**: The nested group requirement calls for recursive component patterns. React's component model naturally supports this.

**Alternatives Considered**:
- Single monolithic component - REJECTED: Hard to maintain, test, and extend
- Use a third-party filter builder library - REJECTED: Custom requirements and Tailwind styling needs

---

## Architecture Notes

### Existing System Integration Points

1. **Filter Query Generation**: The frontend will build filter objects that match the existing query API schema
2. **Stats API**: Reuse existing `/api/stats` endpoints with filter parameters
3. **Session/Event Tables**: Continue using existing ClickHouse queries with extended filter support
4. **User Context**: Reuse existing authentication and site ownership checks

### Privacy Considerations

- Filter conditions only access aggregate visitor data, not PII
- No new data collection required
- Consistent with privacy-first principles in constitution
