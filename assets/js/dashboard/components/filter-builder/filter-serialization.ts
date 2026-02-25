// Filter serialization utilities for converting between filter builder format and legacy format

import { Filter } from '../../dashboard-state'
import {
  FilterGroup,
  FilterGroupItem,
  FilterCondition,
  isFilterGroup,
  LogicalOperator
} from './types'

// Map filter builder operators to legacy filter operations
const OPERATOR_MAP: Record<string, string> = {
  is: 'is',
  is_not: 'is_not',
  contains: 'contains',
  contains_not: 'contains_not',
  greater_than: 'is',
  less_than: 'is',
  is_set: 'is_not',
  is_not_set: 'is'
}

/**
 * Convert a FilterCondition to legacy filter format [operation, dimension, clauses]
 */
export function conditionToLegacyFilter(condition: FilterCondition): Filter {
  const { field, operator, value } = condition

  let legacyOperator = OPERATOR_MAP[operator] || 'is'
  let legacyValue = value

  // Handle special operators
  if (operator === 'greater_than' || operator === 'less_than') {
    // For numeric comparisons, convert to string and use 'is' operator
    legacyValue = String(value)
  }

  // Handle is_set / is_not_set
  if (operator === 'is_set') {
    return ['is_not', field, ['']] as Filter
  }
  if (operator === 'is_not_set') {
    return ['is', field, ['']] as Filter
  }

  // Standard case: wrap value in array
  return [legacyOperator, field, [legacyValue]] as Filter
}

/**
 * Convert a FilterGroup to legacy filter format
 * Handles AND/OR logic by creating multiple filter entries
 */
export function filterGroupToLegacyFilters(group: FilterGroup, parentOperator: LogicalOperator = 'AND'): Filter[] {
  const { children, operator } = group
  const filters: Filter[] = []

  for (const child of children) {
    if (isFilterGroup(child)) {
      // Recursively convert nested groups
      const childFilters = filterGroupToLegacyFilters(child, operator)
      filters.push(...childFilters)
    } else {
      filters.push(conditionToLegacyFilter(child))
    }
  }

  return filters
}

/**
 * Convert legacy filter format [operation, dimension, clauses] to FilterCondition
 */
export function legacyFilterToCondition(filter: Filter): FilterCondition {
  const [operation, dimension, clauses] = filter
  const values = Array.isArray(clauses) ? clauses : []

  // Determine the operator
  let builderOperator: string
  switch (operation) {
    case 'is':
      builderOperator = values.length === 1 && values[0] === '' ? 'is_set' : 'is'
      break
    case 'is_not':
      builderOperator = values.length === 1 && values[0] === '' ? 'is_not_set' : 'is_not'
      break
    case 'contains':
      builderOperator = 'contains'
      break
    case 'contains_not':
      builderOperator = 'contains_not'
      break
    default:
      builderOperator = 'is'
  }

  return {
    id: `legacy-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    field: dimension,
    operator: builderOperator as FilterCondition['operator'],
    value: values[0] || ''
  }
}

/**
 * Convert legacy filters to FilterGroup format
 */
export function legacyFiltersToFilterGroup(filters: Filter[]): FilterGroup {
  const children: FilterGroupItem[] = filters.map((filter) => legacyFilterToCondition(filter))

  return {
    id: `root-${Date.now()}`,
    type: 'group',
    operator: 'AND',
    children
  }
}

/**
 * Serialize filter group to a string for URL storage
 */
export function serializeFilterGroup(group: FilterGroup): string {
  const filters = filterGroupToLegacyFilters(group)
  return JSON.stringify(filters)
}

/**
 * Deserialize filter group from URL string
 */
export function deserializeFilterGroup(serialized: string): FilterGroup | null {
  try {
    const filters = JSON.parse(serialized) as Filter[]
    return legacyFiltersToFilterGroup(filters)
  } catch {
    return null
  }
}

/**
 * Build a query string from filter group
 */
export function buildQueryFromFilterGroup(group: FilterGroup): Record<string, string> {
  const filters = filterGroupToLegacyFilters(group)

  return {
    filters: JSON.stringify(filters)
  }
}
