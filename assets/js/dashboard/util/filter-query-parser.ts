import type { FilterData, FilterGroup, FilterCondition, FilterOperator } from '../../types/filter-builder'

/**
 * Converts filter group format to the existing query API format.
 * Query API format: [[operator, dimension, clauses], ...]
 *
 * Example:
 * Input: { filters: [{ id: '1', logic: 'AND', conditions: [{ id: 'c1', attribute: 'visit:country', operator: 'equals', value: 'US' }] }] }
 * Output: [['is', 'visit:country', ['US']], ...]
 */
export function parseFilterDataToQueryFilters(filterData: FilterData): unknown[] {
  if (!filterData.filters || filterData.filters.length === 0) {
    return []
  }

  return filterData.filters.flatMap(group => parseGroupToQueryFilters(group))
}

function parseGroupToQueryFilters(group: FilterGroup): unknown[] {
  const parsedConditions = group.conditions.map(condition => {
    if ('attribute' in condition) {
      // It's a FilterCondition
      return parseConditionToQueryFilter(condition)
    } else {
      // It's a nested FilterGroup
      return parseGroupToQueryFilters(condition)
    }
  })

  // Flatten nested arrays if there are nested groups
  const flattened = parsedConditions.flat()

  // Combine based on logic
  if (group.logic === 'OR') {
    // For OR logic, we need to create a special filter format
    // The query API uses arrays to represent OR conditions
    return [flattened]
  }

  return flattened as unknown[]
}

function parseConditionToQueryFilter(condition: FilterCondition): unknown[] {
  const { operator, attribute, value } = condition

  // Map our operator to the query API operator
  const queryOperator = mapOperatorToQueryOperator(operator)

  // Handle different value types
  let queryValue: string | string[]

  if (Array.isArray(value)) {
    queryValue = value
  } else if (typeof value === 'string') {
    queryValue = [value]
  } else {
    queryValue = []
  }

  return [queryOperator, attribute, queryValue]
}

function mapOperatorToQueryOperator(operator: FilterOperator): string {
  const operatorMap: Record<FilterOperator, string> = {
    equals: 'is',
    does_not_equal: 'is_not',
    contains: 'contains',
    does_not_contain: 'contains_not',
    matches_regexp: 'matches_regexp',
    does_not_match_regexp: 'matches_regexp',
    is_set: 'is_not_null',
    is_not_set: 'is_null'
  }

  return operatorMap[operator] || 'is'
}

/**
 * Validates that the filter data structure is valid
 */
export function validateFilterData(filterData: FilterData): { valid: boolean; errors: string[] } {
  const errors: string[] = []

  if (!filterData.filters || filterData.filters.length === 0) {
    errors.push('At least one filter group is required')
    return { valid: false, errors }
  }

  // Check each group
  for (const group of filterData.filters) {
    const groupErrors = validateGroup(group, 0)
    errors.push(...groupErrors)
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

function validateGroup(group: FilterGroup, depth: number): string[] {
  const errors: string[] = []

  if (depth > 3) {
    errors.push('Maximum nesting depth of 3 exceeded')
    return errors
  }

  if (!group.conditions || group.conditions.length === 0) {
    errors.push(`Group ${group.id} has no conditions`)
  }

  for (const condition of group.conditions) {
    if ('attribute' in condition) {
      // It's a FilterCondition
      const conditionErrors = validateCondition(condition)
      errors.push(...conditionErrors)
    } else {
      // It's a nested group
      const nestedErrors = validateGroup(condition, depth + 1)
      errors.push(...nestedErrors)
    }
  }

  return errors
}

function validateCondition(condition: FilterCondition): string[] {
  const errors: string[] = []

  if (!condition.attribute) {
    errors.push(`Condition ${condition.id} is missing attribute`)
  }

  if (!condition.operator) {
    errors.push(`Condition ${condition.id} is missing operator`)
  }

  // Check if value is required for the operator
  const operatorsRequiringValue = ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'matches_regexp', 'does_not_match_regexp']

  if (operatorsRequiringValue.includes(condition.operator)) {
    if (!condition.value || (Array.isArray(condition.value) && condition.value.length === 0)) {
      errors.push(`Condition ${condition.id} requires a value`)
    }
  }

  return errors
}

/**
 * Counts total conditions in filter data
 */
export function countConditions(filterData: FilterData): number {
  if (!filterData.filters) return 0

  return filterData.filters.reduce((count, group) => countConditionsInGroup(group), 0)
}

function countConditionsInGroup(group: FilterGroup): number {
  let count = 0

  for (const condition of group.conditions) {
    if ('attribute' in condition) {
      count++
    } else {
      count += countConditionsInGroup(condition)
    }
  }

  return count
}

/**
 * Calculates the nesting depth of filter data
 */
export function getNestingDepth(filterData: FilterData): number {
  if (!filterData.filters) return 0

  return filterData.filters.reduce((maxDepth, group) => Math.max(maxDepth, getGroupDepth(group, 1)), 0)
}

function getGroupDepth(group: FilterGroup, currentDepth: number): number {
  let maxDepth = currentDepth

  for (const condition of group.conditions) {
    if (!('attribute' in condition)) {
      // It's a nested group
      maxDepth = Math.max(maxDepth, getGroupDepth(condition, currentDepth + 1))
    }
  }

  return maxDepth
}
