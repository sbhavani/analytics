// Filter builder types for the Advanced Filter Builder feature

export type FilterOperator =
  | 'is'
  | 'is_not'
  | 'contains'
  | 'contains_not'
  | 'greater_than'
  | 'less_than'
  | 'is_set'
  | 'is_not_set'

export type LogicalOperator = 'AND' | 'OR'

export interface FilterCondition {
  id: string
  field: string
  operator: FilterOperator
  value: string | number | boolean
}

export interface FilterGroup {
  id: string
  type: 'group'
  operator: LogicalOperator
  children: FilterGroupItem[]
}

export type FilterGroupItem = FilterCondition | FilterGroup

export interface FilterBuilderState {
  rootGroup: FilterGroup
  isValid: boolean
  isDirty: boolean
}

export interface VisitorAttribute {
  key: string
  label: string
  type: 'string' | 'number' | 'boolean' | 'enum'
  operators: FilterOperator[]
  values?: string[]
}

export interface FilterBuilderContextValue {
  state: FilterBuilderState
  addCondition: (parentId: string | null) => void
  removeCondition: (conditionId: string) => void
  updateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  addGroup: (parentId: string | null) => void
  removeGroup: (groupId: string) => void
  updateGroupOperator: (groupId: string, operator: LogicalOperator) => void
  clearAll: () => void
  applyFilter: () => void
  loadSegment: (filterGroup: FilterGroup) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  isLoading: boolean
  error: string | null
}

// Generate unique IDs for filter elements
let idCounter = 0
export function generateId(): string {
  return `fb-${Date.now()}-${++idCounter}`
}

// Create a new empty condition
export function createEmptyCondition(): FilterCondition {
  return {
    id: generateId(),
    field: '',
    operator: 'is',
    value: ''
  }
}

// Create a new empty group
export function createEmptyGroup(operator: LogicalOperator = 'AND'): FilterGroup {
  return {
    id: generateId(),
    type: 'group',
    operator,
    children: []
  }
}

// Create initial filter builder state
export function createInitialState(): FilterBuilderState {
  return {
    rootGroup: createEmptyGroup('AND'),
    isValid: false,
    isDirty: false
  }
}

// Check if a filter item is a group
export function isFilterGroup(item: FilterGroupItem): item is FilterGroup {
  return 'type' in item && item.type === 'group'
}

// Get the depth of nested groups
export function getGroupDepth(group: FilterGroup, parentId: string | null = null, currentDepth: number = 0): number {
  let maxDepth = currentDepth
  for (const child of group.children) {
    if (isFilterGroup(child)) {
      const childDepth = getGroupDepth(child, child.id, currentDepth + 1)
      maxDepth = Math.max(maxDepth, childDepth)
    }
  }
  return maxDepth
}

// Find an item by ID in the filter tree
export function findItemById(
  group: FilterGroup,
  id: string
): FilterGroupItem | null {
  if (group.id === id) return group

  for (const child of group.children) {
    if (child.id === id) return child
    if (isFilterGroup(child)) {
      const found = findItemById(child, id)
      if (found) return found
    }
  }

  return null
}

// Find parent group containing an item
export function findParentGroup(
  rootGroup: FilterGroup,
  itemId: string,
  parent: FilterGroup | null = null
): { parent: FilterGroup; childIndex: number } | null {
  for (let i = 0; i < rootGroup.children.length; i++) {
    const child = rootGroup.children[i]
    if (child.id === itemId) {
      return { parent: rootGroup, childIndex: i }
    }
    if (isFilterGroup(child)) {
      const found = findParentGroup(child, itemId, rootGroup)
      if (found) return found
    }
  }
  return null
}

// Validate a filter condition
export function validateCondition(condition: FilterCondition): string[] {
  const errors: string[] = []

  if (!condition.field) {
    errors.push('Field is required')
  }

  if (!condition.operator) {
    errors.push('Operator is required')
  }

  const needsValue = condition.operator !== 'is_set' && condition.operator !== 'is_not_set'
  if (needsValue && (condition.value === '' || condition.value === undefined)) {
    errors.push('Value is required')
  }

  return errors
}

// Validate entire filter structure
export function validateFilterStructure(group: FilterGroup): { isValid: boolean; errors: string[] } {
  const errors: string[] = []

  if (group.children.length === 0) {
    errors.push('At least one condition is required')
  }

  for (const child of group.children) {
    if (isFilterGroup(child)) {
      const childValidation = validateFilterStructure(child)
      errors.push(...childValidation.errors)
    } else {
      const conditionErrors = validateCondition(child)
      errors.push(...conditionErrors)
    }
  }

  return {
    isValid: errors.length === 0,
    errors
  }
}
