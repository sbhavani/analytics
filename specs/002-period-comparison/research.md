# Research: Time Period Comparison Feature

## Decision: Division by Zero Handling

**Question**: How should the system handle the case when the comparison period value is zero (which would cause division by zero in the percentage change calculation)?

**Decision**: Display "N/A" (Not Applicable) when comparison period value is zero

**Rationale**:
- Industry standard in analytics tools (Google Analytics, Mixpanel, etc.)
- Clearly communicates that comparison isn't possible
- Prevents misleading interpretations (e.g., "infinite increase" when going from 0 to any positive number)
- User must select a different comparison period to see meaningful percentage

**Alternatives Considered**:
- Display as "∞" - Can be misleading and confusing to non-technical users
- Show raw value only - Loses the comparison context entirely
- Block the comparison entirely - Too restrictive, users may still want to see absolute values

---

## Decision: Predefined Period Options

**Question**: What predefined period options should be available?

**Decision**: Implement standard set of predefined periods:
- This Week vs Last Week
- This Month vs Last Month
- This Quarter vs Last Quarter
- This Year vs Last Year

**Rationale**:
- Matches common analytics use cases
- Aligns with Google Analytics and similar tools
- Covers the most common time-based comparisons users want to make

---

## Decision: Date Range Calculation

**Question**: Should periods use calendar dates predefined or business days?

**Decision**: Calendar dates (start on Monday/Sunday based on locale, end on Saturday/Sunday)

**Rationale**:
- Spec explicitly states "Date ranges are based on calendar dates"
- Simplifies implementation
- Most common default in analytics tools

---

## Research: ClickHouse Query Patterns

For analytics comparison queries, the typical pattern in ClickHouse:

1. Filter events by date range using WHERE clause with >= and < operators
2. Aggregate using GROUP BY with the metric being calculated
3. Use -1 to subtract previous period values when using date arithmetic

**Key Insight**: Period comparisons in ClickHouse are typically done by:
- Running two separate queries (one for each period) and calculating in application layer
- Or using ClickHouse's dateDiff functions for period-over-period calculations

The application-layer approach is simpler and aligns with the YAGNI principle.

---

## Dependencies and Integration Points

Based on the existing Plausible Analytics codebase:

1. **Existing metrics retrieval**: Uses ClickHouse adapter to query aggregate statistics
2. **Date picker UI**: Need to check if existing date picker supports range selection
3. **Dashboard integration**: Comparison will likely be added to existing dashboard views

No new external dependencies are required for this feature.
