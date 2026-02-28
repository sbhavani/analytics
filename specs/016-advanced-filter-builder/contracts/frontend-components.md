# Frontend Component Contract: Filter Builder

This document describes the React component contracts for the Advanced Filter Builder.

## Component Hierarchy

```
FilterBuilder (Container)
├── FilterBuilderHeader
│   ├── Title
│   └── Actions (Clear, Save, Apply)
├── FilterGroup (rootGroup)
│   ├── ConnectorSelector (AND/OR)
│   ├── ConditionList
│   │   └── ConditionRow (repeated)
│   │       ├── AttributeSelect
│   │       ├── OperatorSelect
│   │       ├── ValueInput
│   │       └── DeleteButton
│   ├── AddConditionButton
│   ├── NestedGroupList
│   │   └── NestedGroup (repeated)
│   │       └── FilterGroup (recursive)
│   └── AddGroupButton
├── FilterSummary
└── SegmentPreview
    ├── LoadingIndicator
    ├── VisitorCount
    └── WarningMessage (if zero)
```

## Component Interfaces

### FilterBuilder Props

```typescript
interface FilterBuilderProps {
  isOpen: boolean
  onClose: () => void
  initialFilterTree?: FilterTree
  onApply: (filterTree: FilterTree) => void
  siteId: string
  dateRange: DateRange
}
```

### ConditionRow Props

```typescript
interface ConditionRowProps {
  condition: FilterCondition
  availableAttributes: AttributeDefinition[]
  onUpdate: (updates: Partial<FilterCondition>) => void
  onDelete: () => void
  isFirst: boolean
  isLast: boolean
  connector: 'AND' | 'OR'
}
```

### AttributeDefinition

```typescript
interface AttributeDefinition {
  key: string
  label: string
  type: 'string' | 'number' | 'boolean'
  operators: FilterOperator[]
  suggestions?: string[] // Autocomplete values
}
```

### FilterGroup Props

```typescript
interface FilterGroupProps {
  group: FilterGroup
  level: number
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  onDeleteCondition: (conditionId: string) => void
  onAddCondition: () => void
  onUpdateConnector: (connector: 'AND' | 'OR') => void
  onAddNestedGroup: () => void
  onDeleteNestedGroup: (groupId: string) => void
  availableAttributes: AttributeDefinition[]
}
```

### SegmentPreview Props

```typescript
interface SegmentPreviewProps {
  filterTree: FilterTree
  siteId: string
  dateRange: DateRange
  queryOptions?: {
    debounceMs?: number
    enabled?: boolean
  }
}
```

### SaveSegmentModal Props

```typescript
interface SaveSegmentModalProps {
  isOpen: boolean
  filterTree: FilterTree
  onSave: (name: string, type: 'personal' | 'site') => Promise<void>
  onClose: () => void
}
```

## State Management

### useFilterBuilder Hook

```typescript
function useFilterBuilder(options: {
  siteId: string
  dateRange: DateRange
}): {
  state: FilterBuilderState
  actions: FilterBuilderActions
  // Computed
  isValid: boolean
  filterSummary: string
}
```

### FilterBuilderState

```typescript
interface FilterBuilderState {
  filterTree: FilterTree
  isDirty: boolean
  preview: {
    visitorCount: number | null
    isLoading: boolean
    error: string | null
  }
}
```

### FilterBuilderActions

```typescript
interface FilterBuilderActions {
  addCondition: (groupId: string) => void
  updateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  deleteCondition: (conditionId: string) => void
  addNestedGroup: (parentGroupId: string) => void
  updateConnector: (groupId: string, connector: 'AND' | 'OR') => void
  loadSegment: (segment: SavedSegment) => void
  clearAll: () => void
  apply: () => void
}
```

## Context API

### FilterBuilderProvider

```typescript
interface FilterBuilderProviderProps {
  children: React.ReactNode
  siteId: string
  dateRange: DateRange
}

// Exposes:
// - filterBuilder: useFilterBuilder return value
// - segments: SavedSegments
// - isLoadingSegments: boolean
// - saveSegment: (name: string, type: SegmentType) => Promise<SavedSegment>
// - deleteSegment: (id: number) => Promise<void>
```

## Event Analytics

The filter builder should emit analytics events for observability:

```typescript
type FilterBuilderEvent =
  | { type: 'FILTER_BUILDER_OPENED' }
  | { type: 'CONDITION_ADDED'; attribute: string }
  | { type: 'CONDITION_UPDATED'; attribute: string }
  | { type: 'CONDITION_DELETED'; attribute: string }
  | { type: 'CONNECTOR_CHANGED'; from: 'AND' | 'OR'; to: 'AND' | 'OR' }
  | { type: 'NESTED_GROUP_ADDED'; depth: number }
  | { type: 'SEGMENT_SAVED'; segmentId: number }
  | { type: 'SEGMENT_APPLIED'; hasNestedGroups: boolean; conditionCount: number }
  | { type: 'FILTER_APPLIED'; conditionCount: number; hasOr: boolean; hasNested: boolean }
```

## Accessibility Requirements

1. All interactive elements must be keyboard navigable
2. Focus management when opening/closing modal
3. ARIA labels on all form controls
4. Screen reader announcements for dynamic content changes
5. Color contrast ratio minimum 4.5:1 for text

## Performance Requirements

1. Filter preview debounced at 300ms
2. Condition updates don't trigger preview until user stops typing (500ms)
3. Lazy load segment list (pagination if >20 segments)
4. Virtualized list for 20+ conditions in a group
