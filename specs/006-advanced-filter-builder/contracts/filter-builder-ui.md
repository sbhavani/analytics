# Filter Builder UI Contract

## Component Structure

### FilterBuilder Component

The main container component managing the filter state.

**Props**:
```typescript
interface FilterBuilderProps {
  initialFilterTree?: FilterTree;
  siteId: string;
  onSave?: (filterTree: FilterTree) => void;
  onPreview?: (filterTree: FilterTree) => Promise<number>;
}
```

### FilterGroup Component

Renders a group of conditions with AND/OR connector.

**Props**:
```typescript
interface FilterGroupProps {
  group: FilterGroupData;
  level: number;
  onAddCondition: (groupId: string) => void;
  onRemoveCondition: (conditionId: string) => void;
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void;
  onChangeOperator: (groupId: string, operator: 'AND' | 'OR') => void;
  onAddGroup: (parentGroupId: string) => void;
  onRemoveGroup: (groupId: string) => void;
}
```

### FilterCondition Component

Renders a single condition row with field, operator, and value inputs.

**Props**:
```typescript
interface FilterConditionProps {
  condition: FilterConditionData;
  availableFields: FilterField[];
  onUpdate: (updates: Partial<FilterCondition>) => void;
  onRemove: () => void;
}
```

### ConditionEditor Component

Input controls for editing a condition.

**Props**:
```typescript
interface ConditionEditorProps {
  field: string;
  operator: string;
  value: string;
  onFieldChange: (field: string) => void;
  onOperatorChange: (operator: string) => void;
  onValueChange: (value: string) => void;
}
```

## Data Types

```typescript
type FilterTree = {
  operator: 'AND' | 'OR';
  conditions: FilterCondition[];
  groups: FilterGroup[];
};

type FilterGroup = {
  id: string;
  operator: 'AND' | 'OR';
  conditions: FilterCondition[];
  groups: FilterGroup[];
};

type FilterCondition = {
  id: string;
  field: string;
  operator: string;
  value: string;
};

type FilterField = {
  name: string;
  displayName: string;
  dataType: 'string' | 'number' | 'date';
  operators: string[];
};
```

## UI States

| State | Description |
|-------|-------------|
| Empty | No conditions - show "Add Condition" button |
| Single Condition | One condition displayed |
| Multiple Conditions | Conditions with AND/OR connector |
| Nested | Groups within groups (max 3 levels) |
| Loading | Preview calculation in progress |
| Error | Invalid filter configuration |

## Interaction Patterns

1. **Add Condition**: Click "Add Condition" button → new condition row appears
2. **Remove Condition**: Click X on condition row → condition removed
3. **Change Connector**: Click AND/OR toggle → connector changes
4. **Group Conditions**: Select conditions → click "Group" → nested group created
5. **Preview**: Click "Preview" → loading state → visitor count displayed
6. **Save**: Click "Save" → modal for naming → segment saved

## Accessibility

- All inputs have associated labels
- Keyboard navigation through conditions
- Screen reader announcements for state changes
- Focus management for modals
