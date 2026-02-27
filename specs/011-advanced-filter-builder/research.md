# Research: Advanced Filter Builder

## Research Questions

### Q1: Which visitor attributes should the filter builder support?

**Decision**: Support all existing visit and event properties from the Plausible Analytics codebase.

**Rationale**: The codebase already has comprehensive filter support for 24 visit properties and multiple event properties. Building a UI that only supports a subset would require users to learn which attributes work in the UI vs. the API. Supporting all existing properties provides consistency.

**Alternatives considered**:
- Option A (Subset): Only support common attributes (country, device, browser, source) - REJECTED because it limits the power of the feature
- Option B (All existing): Support all 24+ visit properties and event properties - ACCEPTED for consistency
- Option C (Core + custom): Support core now, add more later - REJECTED because the codebase already has all we need

## Findings

### Available Visit Properties (from `lib/plausible/stats/filters/filters.ex`)

| Property | Description | Example |
|----------|-------------|---------|
| visit:source | Traffic source | Google, Direct |
| visit:channel | Acquisition channel | Paid Search, Organic |
| visit:referrer | Full referrer URL | example.com |
| visit:utm_medium | UTM medium | cpc, email |
| visit:utm_source | UTM source | google, newsletter |
| visit:utm_campaign | UTM campaign | spring_sale |
| visit:utm_content | UTM content | banner_1 |
| visit:utm_term | UTM term | running+shoes |
| visit:screen | Screen size | Desktop, Mobile |
| visit:device | Device type | Desktop, Mobile, Tablet |
| visit:browser | Browser name | Chrome, Firefox |
| visit:browser_version | Browser version | 120 |
| visit:os | Operating system | Windows, macOS |
| visit:os_version | OS version | 14 |
| visit:country | Country code | US, GB |
| visit:region | Region code | CA, NY |
| visit:city | City ID | 12345 |
| visit:country_name | Country name | United States |
| visit:region_name | Region name | California |
| visit:city_name | City name | San Francisco |
| visit:entry_page | Entry page | /pricing |
| visit:exit_page | Exit page | /thank-you |
| visit:entry_page_hostname | Entry hostname | example.com |
| visit:exit_page_hostname | Exit hostname | example.com |

### Available Event Properties

| Property | Description |
|----------|-------------|
| event:name | Pageview or custom event |
| event:page | Page pathname |
| event:goal | Goal name |
| event:hostname | Hostname |
| event:props:* | Custom properties |

### Available Operators

| Operator | Description |
|----------|-------------|
| is | Exact match |
| is_not | Not equal |
| matches | Regex match |
| matches_not | Regex no match |
| matches_wildcard | Wildcard pattern |
| matches_wildcard_not | Wildcard no match |
| contains | Substring contains |
| contains_not | No substring |
| has_done | Goal completed |
| has_not_done | Goal not completed |

### Logical Operators

| Operator | Description |
|----------|-------------|
| and | All conditions must match |
| or | Any condition must match |
| not | Negation |

## Implementation Considerations

1. **Session-only properties**: Some visit properties (entry_page, exit_page) are session-only and cannot be used for individual events
2. **Custom properties**: Use `event:props:<property_name>` pattern
3. **Existing backend**: The filter parsing and SQL generation already exists in `lib/plausible/stats/`
4. **Maximum nesting**: User stories specify 5 levels max (from spec)
5. **Conditions per group**: User stories specify 10 max per group

## References

- Filter definitions: `lib/plausible/stats/filters/filters.ex`
- Filter parser: `lib/plausible/stats/api_query_parser.ex`
- SQL builder: `lib/plausible/stats/sql/where_builder.ex`
- JSON Schema: `priv/json-schemas/query-api-schema.json`
