/**
 * Filter utility functions for converting between visual and backend filter formats
 */

import type { Filter } from '../../dashboard-state'
import type { FilterCondition, FilterGroup, FilterRoot, FilterOperator } from './types'
import { generateId } from './properties'

/**
 * Convert visual filter group structure to flat backend format
 * This converts the AND/OR group structure to the legacy flat filter array format
 */
export function convertToFlatFilters(root: FilterRoot): Filter[] {
  function processGroup(group: FilterGroup | FilterRoot): Filter[] {
    const groupFilters: Filter[] = []

    // Process nested groups first
    for (const nestedGroup of group.groups) {
      const nestedFilters = processGroup(nestedGroup)
      if (nestedFilters.length > 0) {
        if (nestedGroup.logic === 'OR') {
          // OR groups need to be combined with AND - flatten and wrap
          const flattened = nestedFilters.flat() as unknown as Filter
          groupFilters.push(['and', [flattened]] as unknown as Filter)
        } else {
          // AND groups - just add the filters
          groupFilters.push(...nestedFilters)
        }
      }
    }

    // Process conditions at this level
    for (const condition of group.conditions) {
      const filter = conditionToFilter(condition)
      if (filter) {
        groupFilters.push(filter)
      }
    }

    return groupFilters
  }

  const result = processGroup(root)
  return result
}

/**
 * Convert a single FilterCondition to backend Filter format
 */
function conditionToFilter(condition: FilterCondition): Filter | null {
  const { property, operator, value } = condition

  // Convert operator to backend format
  const backendOperator = operatorToBackend(operator)

  // Handle different value types
  if (Array.isArray(value)) {
    return [backendOperator, property, value]
  } else if (value === '') {
    return null // Skip empty values
  } else {
    return [backendOperator, property, [value]]
  }
}

/**
 * Convert frontend operator to backend format
 */
function operatorToBackend(operator: FilterOperator): string {
  const mapping: Record<FilterOperator, string> = {
    equals: 'is',
    not_equals: 'is_not',
    contains: 'contains',
    does_not_contain: 'does_not_contain',
    greater_than: 'greater',
    less_than: 'less',
    greater_than_or_equals: 'greater',
    less_than_or_equals: 'less',
    is_one_of: 'is'
  }
  return mapping[operator] || 'is'
}

/**
 * Convert backend filter format to visual FilterGroup structure
 */
export function parseFlatFilters(filters: Filter[]): FilterRoot {
  const root: FilterRoot = {
    id: generateId(),
    logic: 'AND',
    conditions: [],
    groups: []
  }

  if (!filters || filters.length === 0) {
    return root
  }

  // Parse filters and create conditions
  for (const filter of filters) {
    if (Array.isArray(filter) && filter.length >= 3) {
      const condition = parseFilterToCondition(filter)
      if (condition) {
        root.conditions.push(condition)
      }
    }
  }

  return root
}

/**
 * Parse a backend filter to a FilterCondition
 */
function parseFilterToCondition(filter: Filter): FilterCondition | null {
  if (!Array.isArray(filter) || filter.length < 3) return null

  const [backendOperator, property, values] = filter
  const operator = backendToFrontend(backendOperator as string, values as (string | number)[])

  if (!operator) return null

  return {
    id: generateId(),
    property: property as string,
    operator,
    value: Array.isArray(values) && values.length === 1 ? String(values[0]) : (values as string[])
  }
}

/**
 * Convert backend operator to frontend format
 */
function backendToFrontend(operator: string, values: unknown): FilterOperator | null {
  if (Array.isArray(values) && values.length > 1 && operator === 'is') {
    return 'is_one_of'
  }

  const mapping: Record<string, FilterOperator | null> = {
    is: 'equals',
    is_not: 'not_equals',
    contains: 'contains',
    does_not_contain: 'does_not_contain',
    greater: 'greater_than',
    less: 'less_than',
    matches: 'contains',
    does_not_match: 'does_not_contain'
  }

  return mapping[operator] || null
}

/**
 * Create a new empty FilterRoot
 */
export function createEmptyFilterRoot(): FilterRoot {
  return {
    id: generateId(),
    logic: 'AND',
    conditions: [],
    groups: []
  }
}

/**
 * Create a new FilterCondition with defaults
 */
export function createFilterCondition(property: string = ''): FilterCondition {
  return {
    id: generateId(),
    property,
    operator: 'equals',
    value: ''
  }
}

/**
 * Create a new FilterGroup with defaults
 */
export function createFilterGroup(logic: 'AND' | 'OR' = 'AND'): FilterGroup {
  return {
    id: generateId(),
    logic,
    conditions: [],
    groups: []
  }
}

/**
 * Validate filter configuration
 */
export function validateFilter(root: FilterRoot): { isValid: boolean; errors: string[] } {
  const errors: string[] = []

  // Check if there are any conditions
  const hasConditions = root.conditions.length > 0 || root.groups.some(g => hasAnyConditions(g))

  if (!hasConditions) {
    errors.push('At least one filter condition is required')
  }

  // Check for empty values
  for (const condition of root.conditions) {
    if (!condition.property) {
      errors.push('Property is required for all conditions')
    }
    if (!condition.value || (typeof condition.value === 'string' && !condition.value.trim())) {
      errors.push(`Value is required for "${condition.property}" condition`)
    }
  }

  // Validate nesting depth
  const maxDepth = 5
  if (getNestingDepth(root) > maxDepth) {
    errors.push(`Maximum nesting depth of ${maxDepth} levels exceeded`)
  }

  return {
    isValid: errors.length === 0,
    errors
  }
}

/**
 * Check if a group has any conditions (recursive)
 */
function hasAnyConditions(group: FilterGroup): boolean {
  if (group.conditions.length > 0) return true
  return group.groups.some(g => hasAnyConditions(g))
}

/**
 * Get the nesting depth of a filter group
 */
export function getNestingDepth(group: FilterGroup | FilterRoot, currentDepth: number = 0): number {
  if (group.groups.length === 0) return currentDepth

  let maxDepth = currentDepth
  for (const nestedGroup of group.groups) {
    const depth = getNestingDepth(nestedGroup, currentDepth + 1)
    maxDepth = Math.max(maxDepth, depth)
  }

  return maxDepth
}

/**
 * Count total number of conditions in a filter group
 */
export function countConditions(root: FilterRoot): number {
  let count = root.conditions.length

  function countInGroup(group: FilterGroup) {
    count += group.conditions.length
    group.groups.forEach(g => countInGroup(g))
  }

  root.groups.forEach(g => countInGroup(g))
  return count
}

/**
 * Check if max conditions limit is reached (20 conditions)
 */
export function hasMaxConditions(root: FilterRoot): boolean {
  return countConditions(root) >= 20
}

/**
 * Sanitize segment name
 */
export function sanitizeSegmentName(name: string): string {
  // Remove potentially dangerous characters
  return name
    .replace(/[<>{}[\]\\]/g, '')
    .replace(/^\s+|\s+$/g, '')
    .slice(0, 255)
}

/**
 * Validate segment name
 */
export function validateSegmentName(name: string): { isValid: boolean; error?: string } {
  const sanitized = sanitizeSegmentName(name)

  if (!sanitized) {
    return { isValid: false, error: 'Segment name is required' }
  }

  if (sanitized.length > 255) {
    return { isValid: false, error: 'Segment name must be 255 characters or less' }
  }

  return { isValid: true }
}
