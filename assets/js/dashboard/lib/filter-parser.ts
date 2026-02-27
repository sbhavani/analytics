import { Filter } from '../dashboard-state'

// Type definitions for the Advanced Filter Builder

export type FilterOperatorType = 'is' | 'is_not' | 'contains' | 'matches' | 'matches_wildcard' | 'has_done' | 'has_not_done' | 'greater_than' | 'less_than'

export type ConnectorType = 'and' | 'or'

export interface FilterCondition {
  id: string
  dimension: string
  operator: FilterOperatorType
  value: (string | number)[]
  modifier?: {
    case_sensitive?: boolean
  }
}

export interface ConditionGroup {
  id: string
  connector: ConnectorType
  conditions: FilterCondition[]
  children: ConditionGroup[]
  isRoot: boolean
}

export interface FilterTree {
  rootGroup: ConditionGroup
  labels: Record<string, string>
}

// Filter tree to backend format serialization

export function filterTreeToBackend(tree: FilterTree): { filters: unknown[]; labels: Record<string, string> } {
  return {
    filters: groupToBackend(tree.rootGroup),
    labels: tree.labels
  }
}

function groupToBackend(group: ConditionGroup): unknown[] {
  const items: unknown[] = []

  // Add conditions at this level
  for (const condition of group.conditions) {
    items.push(conditionToBackend(condition))
  }

  // Add nested groups
  for (const child of group.children) {
    const childItems = groupToBackend(child)
    // For non-root groups: only wrap if it has multiple conditions or nested children
    // Otherwise return the single condition directly
    if (!child.isRoot && !Array.isArray(childItems) || (Array.isArray(childItems) && childItems.length > 0 && childItems[0] !== 'and' && childItems[0] !== 'or')) {
      items.push(childItems)
    } else {
      items.push(childItems)
    }
  }

  // If there's only one item at root level, return it directly
  if (group.isRoot && items.length === 1) {
    return items[0] as unknown[]
  }

  // For non-root groups with a single condition, return it directly without wrapping
  if (!group.isRoot && items.length === 1) {
    return items[0] as unknown[]
  }

  // Otherwise wrap with connector
  return [group.connector, items]
}

function conditionToBackend(condition: FilterCondition): unknown[] {
  const result: unknown[] = [condition.operator, condition.dimension, condition.value]
  if (condition.modifier) {
    result.push(condition.modifier)
  }
  return result
}

// Backend to filter tree deserialization

export function backendToFilterTree(data: { filters: unknown[]; labels?: Record<string, string> }): FilterTree {
  const labels = data.labels || {}

  // Create root group
  const rootGroup = backendToGroup(data.filters, 'root')

  return {
    rootGroup,
    labels
  }
}

function backendToGroup(filterData: unknown[], id: string): ConditionGroup {
  // Handle different filter structures
  if (!Array.isArray(filterData)) {
    // Single condition without connector
    return {
      id,
      connector: 'and',
      conditions: [backendToCondition(filterData)],
      children: [],
      isRoot: id === 'root'
    }
  }

  // Check if it's a single condition array: [operator, dimension, value]
  // This is distinct from connector groups which have structure [connector, [items]]
  if (filterData.length >= 3 && isConditionArray(filterData)) {
    return {
      id,
      connector: 'and',
      conditions: [backendToCondition(filterData)],
      children: [],
      isRoot: id === 'root'
    }
  }

  // Check if it's a connector group: [connector, [items]]
  if (filterData.length === 2 && (filterData[0] === 'and' || filterData[0] === 'or')) {
    const connector = filterData[0] as ConnectorType
    const items = filterData[1] as unknown[]

    const group: ConditionGroup = {
      id,
      connector,
      conditions: [],
      children: [],
      isRoot: id === 'root'
    }

    for (const item of items) {
      if (isConditionArray(item)) {
        group.conditions.push(backendToCondition(item))
      } else if (Array.isArray(item) && (item[0] === 'and' || item[0] === 'or')) {
        group.children.push(backendToGroup(item, generateId()))
      }
    }

    return group
  }

  // It's a list of conditions
  const group: ConditionGroup = {
    id,
    connector: 'and',
    conditions: [],
    children: [],
    isRoot: id === 'root'
  }

  for (const item of filterData) {
    if (isConditionArray(item)) {
      group.conditions.push(backendToCondition(item))
    } else if (Array.isArray(item) && (item[0] === 'and' || item[0] === 'or')) {
      group.children.push(backendToGroup(item, generateId()))
    }
  }

  return group
}

function backendToCondition(data: unknown): FilterCondition {
  if (!Array.isArray(data)) {
    return createEmptyCondition()
  }

  const [operator, dimension, value, modifier] = data

  return {
    id: generateId(),
    dimension: String(dimension || ''),
    operator: (operator as FilterOperatorType) || 'is',
    value: Array.isArray(value) ? value : [],
    modifier: modifier as FilterCondition['modifier']
  }
}

function isConditionArray(item: unknown): boolean {
  if (!Array.isArray(item)) return false
  const [op] = item
  return typeof op === 'string' && !['and', 'or'].includes(op)
}

// Utility functions

export function createEmptyCondition(): FilterCondition {
  return {
    id: generateId(),
    dimension: '',
    operator: 'is',
    value: [],
    modifier: undefined
  }
}

export function createEmptyGroup(isRoot: boolean = false): ConditionGroup {
  return {
    id: generateId(),
    connector: 'and',
    conditions: [],
    children: [],
    isRoot
  }
}

export function createEmptyFilterTree(): FilterTree {
  return {
    rootGroup: createEmptyGroup(true),
    labels: {}
  }
}

function generateId(): string {
  return `cond-${Math.random().toString(36).substr(2, 9)}`
}

// Convert filter tree to dashboard-state Filter format (for compatibility)

export function filterTreeToDashboardFilters(tree: FilterTree): Filter[] {
  return groupToDashboardFilters(tree.rootGroup)
}

function groupToDashboardFilters(group: ConditionGroup): Filter[] {
  const filters: Filter[] = []

  for (const condition of group.conditions) {
    filters.push([condition.operator, condition.dimension, condition.value] as Filter)
  }

  // For nested groups, we need to flatten - this is a simplified version
  // In a real implementation, you'd handle the nesting properly
  for (const child of group.children) {
    if (child.conditions.length > 0 || child.children.length > 0) {
      const childFilters = groupToDashboardFilters(child)
      if (child.connector === 'or' && childFilters.length > 1) {
        // Wrap with OR connector
        filters.push(['or', childFilters] as unknown as Filter)
      } else {
        filters.push(...childFilters)
      }
    }
  }

  return filters
}

// Validate filter tree

export function validateFilterTree(tree: FilterTree): { valid: boolean; errors: string[] } {
  const errors: string[] = []

  // Count total conditions
  const totalConditions = countConditions(tree.rootGroup)
  if (totalConditions > 20) {
    errors.push('Maximum 20 conditions allowed')
  }

  // Check nesting depth
  const maxDepth = getMaxDepth(tree.rootGroup)
  if (maxDepth > 3) {
    errors.push('Maximum 3 levels of nesting allowed')
  }

  // Validate each condition
  validateConditions(tree.rootGroup, errors)

  return {
    valid: errors.length === 0,
    errors
  }
}

function countConditions(group: ConditionGroup): number {
  let count = group.conditions.length
  for (const child of group.children) {
    count += countConditions(child)
  }
  return count
}

function getMaxDepth(group: ConditionGroup): number {
  if (group.children.length === 0) {
    return 1
  }
  return 1 + Math.max(...group.children.map(getMaxDepth))
}

function validateConditions(group: ConditionGroup, errors: string[]): void {
  for (const condition of group.conditions) {
    if (!condition.dimension) {
      errors.push('Condition missing dimension')
    }
    if (!condition.operator) {
      errors.push('Condition missing operator')
    }
    if (condition.value.length === 0) {
      errors.push('Condition missing value')
    }
  }

  for (const child of group.children) {
    validateConditions(child, errors)
  }
}

// Available dimensions for filter builder

export type FilterDimension = {
  key: string
  type: 'string' | 'numeric' | 'boolean'
  group: string
  label: string
}

export const AVAILABLE_DIMENSIONS: FilterDimension[] = [
  { key: 'visit:country', type: 'string', group: 'location', label: 'Country' },
  { key: 'visit:region', type: 'string', group: 'location', label: 'Region' },
  { key: 'visit:city', type: 'string', group: 'location', label: 'City' },
  { key: 'visit:device', type: 'string', group: 'device', label: 'Device' },
  { key: 'visit:browser', type: 'string', group: 'browser', label: 'Browser' },
  { key: 'visit:browser_version', type: 'string', group: 'browser', label: 'Browser Version' },
  { key: 'visit:os', type: 'string', group: 'os', label: 'Operating System' },
  { key: 'visit:os_version', type: 'string', group: 'os', label: 'OS Version' },
  { key: 'visit:source', type: 'string', group: 'source', label: 'Source' },
  { key: 'visit:channel', type: 'string', group: 'source', label: 'Channel' },
  { key: 'visit:referrer', type: 'string', group: 'source', label: 'Referrer' },
  { key: 'visit:utm_medium', type: 'string', group: 'utm', label: 'UTM Medium' },
  { key: 'visit:utm_source', type: 'string', group: 'utm', label: 'UTM Source' },
  { key: 'visit:utm_campaign', type: 'string', group: 'utm', label: 'UTM Campaign' },
  { key: 'visit:utm_term', type: 'string', group: 'utm', label: 'UTM Term' },
  { key: 'visit:utm_content', type: 'string', group: 'utm', label: 'UTM Content' },
  { key: 'visit:entry_page', type: 'string', group: 'page', label: 'Entry Page' },
  { key: 'visit:exit_page', type: 'string', group: 'page', label: 'Exit Page' },
  { key: 'event:page', type: 'string', group: 'page', label: 'Page' },
  { key: 'event:name', type: 'string', group: 'event', label: 'Event Name' },
  { key: 'event:hostname', type: 'string', group: 'event', label: 'Hostname' },
  { key: 'event:goal', type: 'string', group: 'goal', label: 'Goal' }
]

// Operators by dimension type

export const OPERATORS_BY_TYPE: Record<string, FilterOperatorType[]> = {
  string: ['is', 'is_not', 'contains', 'matches', 'matches_wildcard'],
  numeric: ['is', 'is_not', 'greater_than', 'less_than'],
  boolean: ['is', 'is_not']
}

export function getOperatorsForDimension(dimension: string): FilterOperatorType[] {
  const dim = AVAILABLE_DIMENSIONS.find(d => d.key === dimension)
  if (!dim) return OPERATORS_BY_TYPE.string
  return OPERATORS_BY_TYPE[dim.type] || OPERATORS_BY_TYPE.string
}
