# Quickstart: Advanced Filter Builder

## For Developers

This guide helps developers start implementing the Filter Builder feature.

### Prerequisites

- Elixir 1.15+ with Phoenix Framework
- Node.js 18+ with React 18
- PostgreSQL and ClickHouse running locally
- Existing knowledge of Plausible analytics codebase

### Project Structure

```
lib/plausible/
├── segments/
│   ├── filter_template.ex       # Ecto schema for templates
│   ├── filter_template_repo.ex   # Data access functions
│   └── filter_builder.ex         # Filter tree processing

assets/js/
├── components/
│   └── FilterBuilder/           # React components
│       ├── FilterBuilder.tsx
│       ├── ConditionRow.tsx
│       ├── ConditionGroup.tsx
│       └── FieldSelect.tsx
└── lib/
    └── filterBuilder/
        ├── filterParser.ts       # Parse filter tree
        └── filterSerializer.ts   # Serialize for API
```

### Backend Development

1. **Create database migration**:
   ```bash
   mix ecto.gen.migration create_filter_templates
   ```

2. **Add Ecto schema** in `lib/plausible/segments/filter_template.ex`

3. **Create API controller** for template CRUD operations

4. **Extend WhereBuilder** in `lib/plausible/stats/sql/where_builder.ex`:
   - Add support for new visitor fields if needed
   - Ensure nested filter groups work correctly

5. **Add preview endpoint** to evaluate filter against ClickHouse:
   - Parse filter_tree JSON
   - Build ClickHouse query using existing patterns
   - Return visitor count

### Frontend Development

1. **Create React components**:
   - `FilterBuilder.tsx` - Main container
   - `ConditionRow.tsx` - Single condition UI
   - `ConditionGroup.tsx` - AND/OR group container
   - `FieldSelect.tsx` - Dropdown for field selection
   - `OperatorSelect.tsx` - Dropdown for operators
   - `ValueInput.tsx` - Input for filter value

2. **Add state management**:
   - Filter tree state in React
   - Debounced preview API calls
   - Template save/load functionality

3. **Integrate into dashboard**:
   - Add "Create Segment" button to analytics views
   - Connect to existing site context

### Testing

**Backend Tests** (ExUnit):
- Filter tree parsing/validation
- WhereBuilder integration
- API endpoint tests

**Frontend Tests** (Jest):
- Component rendering
- State management
- User interaction flows

### Key Dependencies

| Package | Purpose |
|---------|---------|
| Phoenix | Web framework |
| Ecto | Database ORM |
| React 18 | UI framework |
| TailwindCSS | Styling |
| ClickHouse | Analytics queries |

### Running Locally

```bash
# Start backend
mix phx.server

# Start frontend
cd assets && npm run dev

# Run migrations
mix ecto.migrate
```

### Common Patterns

**Filter Tree Structure** (matches existing WhereBuilder):
```elixir
# Simple AND
[:and, [filter1, filter2]]

# Simple OR
[:or, [filter1, filter2]]

# Nested
[:and, [
  filter1,
  [:or, [filter2, filter3]]
]]
```

**Frontend State**:
```typescript
interface FilterTree {
  rootGroup: FilterGroup;
}

interface FilterGroup {
  id: string;
  connector: 'AND' | 'OR';
  conditions: Condition[];
  subgroups: FilterGroup[];
}
```

### Next Steps

1. Start with backend schema and migration
2. Implement simple single-condition filter UI
3. Add AND/OR logic
4. Implement nesting support
5. Add template saving
6. Add real-time preview
