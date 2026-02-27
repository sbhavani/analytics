# Quickstart: Advanced Filter Builder

## Overview

The Advanced Filter Builder is a UI component that allows users to create complex visitor segments by combining multiple filter conditions with AND/OR logic and nested groups.

## For Developers

### Architecture

```
FilterBuilder (React Component)
  └── FilterBuilderModal
       ├── ConditionGroup (recursive)
       │    ├── ConditionRow[]
       │    └── ConditionGroup[] (nested)
       ├── FilterPreview (visitor count)
       └── SaveSegmentForm
```

### Key Integration Points

1. **Filter Parsing**: Uses existing `ApiQueryParser` in backend
2. **Filter Suggestions**: Uses existing `/api/stats/filter-suggestions` endpoint
3. **Segment Storage**: Uses existing `segments` table with `segment_data` JSON
4. **Preview Count**: Uses existing stats query infrastructure

### Data Flow

1. User builds filter in UI
2. UI serializes to filter list format
3. Backend validates via `ApiQueryParser.parse_filters/1`
4. Valid filter stored in `segments.segment_data`
5. Stats queries use segment filter via `QueryBuilder`

### Key Files

| File | Purpose |
|------|---------|
| `lib/plausible/stats/api_query_parser.ex` | Filter parsing |
| `lib/plausible/segments/segment.ex` | Segment schema |
| `assets/js/dashboard/components/FilterBuilder/` | UI components |
| `assets/js/lib/filter-parser.ts` | Serialization utilities |

### Testing Strategy

1. **Backend**: Unit tests for filter parsing via `ApiQueryParser` tests
2. **Frontend**: Component tests for FilterBuilder with Jest
3. **Integration**: E2E tests for full segment creation flow

### Configuration

No new configuration required. Uses existing:
- Segment storage limits (5KB JSON)
- Query validation rules
- User authentication/authorization

## For Stakeholders

### User Flow

1. User clicks "Create Segment" in dashboard
2. Filter Builder modal opens
3. User adds conditions (field, operator, value)
4. User combines conditions with AND/OR
5. User groups conditions for complex logic
6. Preview shows matching visitor count
7. User saves segment with name

### Constraints

- Maximum 20 conditions per segment
- Maximum 3 levels of nested groups
- Valid dimensions: country, device, browser, OS, source, page, goal, custom properties
- Operators: is, is_not, contains, matches, has_done, has_not_done

### Performance

- Filter preview updates within 2 seconds
- Supports segments with 1M+ visitors
- No performance degradation up to 20 conditions
