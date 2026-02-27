// Filter serialization utilities for converting between flat and nested filter formats

import { Filter } from '../dashboard-state'

// Filter operation types matching the backend
export type FilterOperation =
  | 'is'
  | 'is_not'
  | 'contains'
  | 'contains_not'
  | 'has_not_done'
  | 'matches'
  | 'matches_not'
  | 'matches_wildcard'
  | 'matches_wildcard_not'

// Single filter condition [operation, dimension, clauses]
export type FilterCondition = [FilterOperation, string, string[]]

// Filter group with children
export interface FilterGroup {
  filter_type: 'and' | 'or'
  children: FilterComposite[]
}

// Filter composite - either a condition or a group
export type FilterComposite = FilterCondition | FilterGroup

// Maximum nesting depth
export const MAX_NESTING_DEPTH = 2

// Maximum children per group
export const MAX_CHILDREN_PER_GROUP = 10

/**
 * Converts the flat filter array format to nested filter format
 * Flat: [[op, dim, clauses], [op, dim, clauses], ...]
 * Nested: { filter_type: 'and', children: [[op, dim, clauses], ...] }
 */
export function flatToNested(filters: Filter[]): FilterGroup {
  return {
    filter_type: 'and',
    children: filters as FilterComposite[]
  }
}

/**
 * Converts nested filter format to flat array format
 * Only flattens top-level AND groups (for backward compatibility)
 */
export function nestedToFlat(filter: FilterComposite): Filter[] {
  if (isFilterGroup(filter)) {
    if (filter.filter_type === 'and') {
      // For AND groups, we can flatten to the legacy flat array format
      return flattenFilterComposite(filter)
    }
    // For OR groups, we need to keep the nested structure
    return [filter as Filter]
  }
  // Single condition
  return [filter as Filter]
}

/**
 * Flattens a filter composite into a flat array of conditions
 */
function flattenFilterComposite(filter: FilterComposite): Filter[] {
  if (isFilterGroup(filter)) {
    return filter.children.flatMap(child => flattenFilterComposite(child))
  }
  return [filter as Filter]
}

/**
 * Checks if a filter is a FilterGroup
 */
export function isFilterGroup(filter: FilterComposite | Filter): filter is FilterGroup {
  return (
    typeof filter === 'object' &&
    'filter_type' in filter &&
    (filter.filter_type === 'and' || filter.filter_type === 'or')
  )
}

/**
 * Checks if a filter is a simple condition (not a group)
 */
export function isFilterCondition(filter: FilterComposite | Filter): filter is FilterCondition {
  return (
    Array.isArray(filter) &&
    filter.length >= 3 &&
    typeof filter[0] === 'string' &&
    typeof filter[1] === 'string' &&
    Array.isArray(filter[2])
  )
}

/**
 * Gets the nesting depth of a filter
 */
export function getNestingDepth(filter: FilterComposite | Filter): number {
  if (isFilterGroup(filter)) {
    const childDepths = filter.children.map(child => getNestingDepth(child))
    return 1 + Math.max(...childDepths, 0)
  }
  return 0
}

/**
 * Validates that the filter doesn't exceed maximum nesting depth
 */
export function isValidNestingDepth(filter: FilterComposite): boolean {
  return getNestingDepth(filter) <= MAX_NESTING_DEPTH
}

/**
 * Gets the number of children in a group
 */
export function getChildCount(filter: FilterComposite | Filter): number {
  if (isFilterGroup(filter)) {
    return filter.children.length
  }
  return 1
}

/**
 * Validates that the filter doesn't exceed maximum children per group
 */
export function isValidChildCount(filter: FilterComposite): boolean {
  if (isFilterGroup(filter)) {
    if (filter.children.length > MAX_CHILDREN_PER_GROUP) {
      return false
    }
    return filter.children.every(child => isValidChildCount(child))
  }
  return true
}

/**
 * Creates a new empty filter group
 */
export function createEmptyFilterGroup(): FilterGroup {
  return {
    filter_type: 'and',
    children: []
  }
}

/**
 * Creates a new filter condition
 */
export function createFilterCondition(
  dimension: string,
  operation: FilterOperation = 'is',
  clauses: string[] = []
): FilterCondition {
  return [operation, dimension, clauses]
}

/**
 * Adds a condition to a filter group
 */
export function addConditionToGroup(
  group: FilterGroup,
  condition: FilterComposite
): FilterGroup {
  return {
    ...group,
    children: [...group.children, condition]
  }
}

/**
 * Removes a condition from a filter group by index
 */
export function removeConditionFromGroup(
  group: FilterGroup,
  index: number
): FilterGroup {
  return {
    ...group,
    children: group.children.filter((_, i) => i !== index)
  }
}

/**
 * Updates a condition in a filter group by index
 */
export function updateConditionInGroup(
  group: FilterGroup,
  index: number,
  condition: FilterComposite
): FilterGroup {
  return {
    ...group,
    children: group.children.map((child, i) => (i === index ? condition : child))
  }
}

/**
 * Changes the filter type (AND/OR) of a group
 */
export function changeGroupFilterType(
  group: FilterGroup,
  filterType: 'and' | 'or'
): FilterGroup {
  return {
    ...group,
    filter_type: filterType
  }
}

/**
 * Wraps conditions in a nested group
 */
export function wrapInGroup(
  children: FilterComposite[],
  filterType: 'and' | 'or'
): FilterGroup {
  return {
    filter_type: filterType,
    children
  }
}

/**
 * Serializes a filter to JSON string for URL storage
 */
export function serializeFilter(filter: FilterComposite): string {
  return JSON.stringify(filter)
}

/**
 * Deserializes a filter from JSON string
 */
export function deserializeFilter(json: string): FilterComposite | null {
  try {
    const parsed = JSON.parse(json)
    if (isFilterGroup(parsed) || isFilterCondition(parsed)) {
      return parsed
    }
    return null
  } catch {
    return null
  }
}

/**
 * Validates a filter structure
 * Returns true if valid, false otherwise
 */
export function isValidFilter(filter: unknown): filter is FilterComposite {
  if (isFilterGroup(filter)) {
    return (
      (filter.filter_type === 'and' || filter.filter_type === 'or') &&
      Array.isArray(filter.children) &&
      filter.children.length > 0 &&
      filter.children.every(child => isValidFilter(child))
    )
  }
  if (isFilterCondition(filter)) {
    const validOperations = [
      'is',
      'is_not',
      'contains',
      'contains_not',
      'has_not_done',
      'matches',
      'matches_not',
      'matches_wildcard',
      'matches_wildcard_not'
    ]
    return (
      validOperations.includes(filter[0]) &&
      typeof filter[1] === 'string' &&
      Array.isArray(filter[2])
    )
  }
  return false
}

/**
 * Gets all leaf conditions from a filter (for counting, etc.)
 */
export function getAllLeafConditions(filter: FilterComposite): FilterCondition[] {
  if (isFilterGroup(filter)) {
    return filter.children.flatMap(child => getAllLeafConditions(child))
  }
  return [filter as FilterCondition]
}
