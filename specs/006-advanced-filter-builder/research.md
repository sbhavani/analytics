# Research: Advanced Filter Builder for Visitor Segments

## Phase 0: Research Findings

**Date**: 2026-02-26
**Feature**: Advanced Filter Builder

### Technical Stack Decision

| Technology | Decision | Rationale |
|------------|----------|-----------|
| Backend Language | Elixir/Phoenix | Constitution mandates Elixir/Phoenix for backend |
| Frontend | React + TypeScript | Constitution mandates React + TypeScript + TailwindCSS |
| Database | PostgreSQL + ClickHouse | Constitution mandates PostgreSQL for transactional, ClickHouse for analytics |
| Testing | ExUnit + Jest | Constitution mandates ExUnit for Elixir, Jest for JavaScript |

### Clarifications Resolved

No NEEDS CLARIFICATION markers were required. All technical decisions derive from the existing constitution:

- **Privacy compliance**: Filter fields use only aggregated visitor attributes (country, pages visited, device type) - no PII
- **Performance targets**: Derived from SC-003 (5 seconds for 1M visitors)
- **Scale limits**: Derived from FR-014 (3 nesting levels) and FR-015 (10 conditions)

### Best Practices Applied

1. **Query Performance**: Use ClickHouse for segment preview queries (optimized for analytics workloads)
2. **State Management**: React context for filter builder state, server-side persistence for saved segments
3. **Error Handling**: Graceful degradation when preview times out, clear error messages for invalid filters

### Alternatives Considered

- **Elasticsearch for queries**: Rejected - ClickHouse already handles analytics queries in the existing architecture
- **LocalStorage for draft segments**: Rejected - server-side storage ensures consistency across devices

### Research Conclusion

The feature is ready for Phase 1 design. All technical decisions align with the existing architecture and constitution principles.
