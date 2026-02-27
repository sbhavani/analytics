# Research: Advanced Filter Builder for Visitor Segments

## Decision: Available Visitor Fields

**Context**: What visitor attributes are available for filtering in ClickHouse?

**Finding**: The `sessions_v2` ClickHouse table contains these filterable fields:

| Field | Type | Alias | Description |
|-------|------|-------|-------------|
| country_code | LowCardinality(FixedString(2)) | country | ISO country code |
| country_name | String | - | Human-readable country name |
| region | LowCardinality(String) | subdivision1_code | Region/state code |
| region_name | String | - | Human-readable region name |
| city_geoname_id | UInt32 | city | GeoName ID |
| city_name | String | - | Human-readable city name |
| device | LowCardinality(String) | screen_size | Device type (Desktop, Mobile, Tablet) |
| operating_system | LowCardinality(String) | os | OS name |
| operating_system_version | LowCardinality(String) | os_version | OS version |
| browser | LowCardinality(String) | - | Browser name |
| browser_version | LowCardinality(String) | - | Browser version |
| referrer | String | - | Full referrer URL |
| referrer_source | String | source | Referrer source |
| utm_medium | String | - | UTM medium |
| utm_source | String | - | UTM source |
| utm_campaign | String | - | UTM campaign |
| utm_content | String | - | UTM content |
| utm_term | String | - | UTM term |
| hostname | String | entry_page_hostname | Visitor hostname |
| entry_page | String | - | Entry page path |
| exit_page | String | - | Exit page path |
| pageviews | Int32 | - | Number of pageviews |
| events | Int32 | - | Number of events |
| duration | UInt32 | - | Session duration in seconds |
| is_bounce | UInt8 | - | Bounce flag |
| channel | LowCardinality(String) | - | Traffic channel |

**Decision**: Use these existing fields. Additional custom event properties can be added via `props_enabled`.

**Alternatives considered**:
- Adding new fields: Not feasible without ClickHouse schema changes
- Using only a subset: Reduces functionality, not recommended

---

## Decision: Filter Evaluation Pattern

**Context**: How are filters evaluated against visitor data in ClickHouse?

**Finding**: Existing pattern in `lib/plausible/stats/sql/where_builder.ex`:

```elixir
# AND logic
[:and, filters] ->
  filters
  |> Enum.map(&add_filter(table, query, &1))
  |> Enum.reduce(fn condition, acc -> dynamic([], ^acc and ^condition) end)

# OR logic
[:or, filters] ->
  filters
  |> Enum.map(&add_filter(table, query, &1))
  |> Enum.reduce(fn condition, acc -> dynamic([], ^acc or ^condition) end)

# Nested groups supported recursively
```

**Decision**: Extend existing WhereBuilder pattern for the filter builder. The filter tree structure matches:
- Simple: `[field, operator, value]`
- AND group: `[:and, [filter1, filter2, ...]]`
- OR group: `[:or, [filter1, filter2, ...]]`
- Nested: `[:and, [filter1, [:or, [filter2, filter3]]]]`

**Alternatives considered**:
- Create new filter evaluation: Would duplicate existing functionality
- Use raw SQL: Less maintainable, security risks

---

## Decision: Template Storage Schema

**Context**: Where are filter templates stored?

**Finding**: Site-related data uses PostgreSQL with Ecto schemas. Example patterns:
- `Plausible.Site` - site configuration
- `Plausible.Goal` - conversion goals
- `Plausible.Site.TrackerScriptConfiguration` - embedded configs

**Decision**: Create new `Plausible.Segments.FilterTemplate` schema in PostgreSQL:
- `site_id` - FK to sites table
- `name` - template name
- `filter_tree` - JSONB storing the filter structure
- `inserted_at`, `updated_at` - timestamps

**Alternatives considered**:
- Store in ClickHouse: Not appropriate for metadata
- Store in config files: Not suitable for multi-tenant SaaS

---

## Decision: Nested Group UI Depth

**Context**: What is the maximum nesting depth for filter groups?

**Finding**: No explicit limit found in existing codebase. User Story 4 specifies "3+ levels deep" in success criteria.

**Decision**: Support minimum 3 levels of nesting in UI. Set maximum depth to 5 to prevent UI overflow (from Edge Case in spec).

---

## Summary

All unknowns resolved:

| Unknown | Resolution |
|---------|------------|
| Available visitor fields | Use existing ClickHouse sessions_v2 fields |
| Filter evaluation API | Extend existing WhereBuilder pattern |
| Template schema | New PostgreSQL schema with JSONB storage |
| Nested group UI depth | Max 5 levels, support 3+ in success criteria |
