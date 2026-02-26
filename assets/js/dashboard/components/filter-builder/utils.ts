/**
 * Filter Builder Utility Functions
 *
 * Helper functions for the Advanced Filter Builder
 */

import {
  FilterExpression,
  FilterCondition,
  ConditionGroup,
  FilterBuilderError,
  FilterBuilderErrorType,
  LogicalOperator,
  generateId
} from './types'

/**
 * Maximum nesting depth allowed for condition groups
 */
export const MAX_NESTING_DEPTH = 5

/**
 * Maximum total number of conditions allowed
 */
export const MAX_TOTAL_CONDITIONS = 50

/**
 * Validate a filter expression
 */
export function validateExpression(expression: FilterExpression): FilterBuilderError[] {
  const errors: FilterBuilderError[] = []

  // Check root group exists
  if (!expression.rootGroup) {
    errors.push({
      type: 'field_required',
      path: '/rootGroup',
      message: 'Root group is required'
    })
    return errors
  }

  // Validate the root group
  validateGroup(expression.rootGroup, '/rootGroup', errors)

  // Count total conditions
  const totalConditions = countConditions(expression.rootGroup)
  if (totalConditions > MAX_TOTAL_CONDITIONS) {
    errors.push({
      type: 'max_conditions_exceeded',
      path: '/',
      message: `Maximum number of conditions (${MAX_TOTAL_CONDITIONS}) exceeded`
    })
  }

  // Check nesting depth
  const depth = getNestingDepth(expression.rootGroup)
  if (depth > MAX_NESTING_DEPTH) {
    errors.push({
      type: 'max_depth_exceeded',
      path: '/',
      message: `Maximum nesting depth (${MAX_NESTING_DEPTH}) exceeded`
    })
  }

  return errors
}

/**
 * Validate a condition group
 */
function validateGroup(group: ConditionGroup, path: string, errors: FilterBuilderError[]): void {
  if (!group.operator || !['AND', 'OR'].includes(group.operator)) {
    errors.push({
      type: 'operator_required',
      path: `${path}/operator`,
      message: 'Group operator is required (AND or OR)'
    })
  }

  if (!group.conditions || group.conditions.length === 0) {
    errors.push({
      type: 'field_required',
      path: `${path}/conditions`,
      message: 'At least one condition is required'
    })
    return
  }

  // Validate each condition/group
  group.conditions.forEach((condition, index) => {
    if ('field' in condition) {
      // It's a condition
      validateCondition(condition as FilterCondition, `${path}/conditions/${index}`, errors)
    } else {
      // It's a nested group
      validateGroup(condition as ConditionGroup, `${path}/conditions/${index}`, errors)
    }
  })
}

/**
 * Validate a single filter condition
 */
function validateCondition(
  condition: FilterCondition,
  path: string,
  errors: FilterBuilderError[]
): void {
  // Check field is present
  if (!condition.field || condition.field.trim() === '') {
    errors.push({
      type: 'field_required',
      path: `${path}/field`,
      message: 'Field is required'
    })
  }

  // Check operator is present
  if (!condition.operator) {
    errors.push({
      type: 'operator_required',
      path: `${path}/operator`,
      message: 'Operator is required'
    })
  }

  // Check value for operators that require it
  const needsValue = ['equals', 'not_equals', 'contains', 'not_contains', 'greater_than', 'less_than', 'matches_regex'].includes(condition.operator)

  if (needsValue && (condition.value === undefined || condition.value === null || condition.value === '')) {
    errors.push({
      type: 'value_required',
      path: `${path}/value`,
      message: 'Value is required for this operator'
    })
  }
}

/**
 * Count total number of conditions in an expression
 */
export function countConditions(group: ConditionGroup): number {
  let count = 0

  for (const condition of group.conditions) {
    if ('field' in condition) {
      count++
    } else {
      count += countConditions(condition as ConditionGroup)
    }
  }

  return count
}

/**
 * Get the nesting depth of an expression
 */
export function getNestingDepth(group: ConditionGroup, currentDepth: number = 1): number {
  let maxDepth = currentDepth

  for (const condition of group.conditions) {
    if (!('field' in condition)) {
      const nestedDepth = getNestingDepth(condition as ConditionGroup, currentDepth + 1)
      maxDepth = Math.max(maxDepth, nestedDepth)
    }
  }

  return maxDepth
}

/**
 * Check if an expression is valid (has no validation errors)
 */
export function isExpressionValid(expression: FilterExpression): boolean {
  return validateExpression(expression).length === 0
}

/**
 * Add a condition to a group
 */
export function addConditionToGroup(
  group: ConditionGroup,
  condition: FilterCondition
): ConditionGroup {
  return {
    ...group,
    conditions: [...group.conditions, condition]
  }
}

/**
 * Remove a condition from a group by ID
 */
export function removeConditionFromGroup(
  group: ConditionGroup,
  conditionId: string
): ConditionGroup {
  return {
    ...group,
    conditions: group.conditions.filter((condition) => {
      if ('field' in condition) {
        return (condition as FilterCondition).id !== conditionId
      } else {
        return (condition as ConditionGroup).id !== conditionId
      }
    })
  }
}

/**
 * Update a condition in a group by ID
 */
export function updateConditionInGroup(
  group: ConditionGroup,
  conditionId: string,
  updates: Partial<FilterCondition>
): ConditionGroup {
  return {
    ...group,
    conditions: group.conditions.map((condition) => {
      if ('field' in condition && (condition as FilterCondition).id === conditionId) {
        return { ...condition, ...updates }
      }
      return condition
    })
  }
}

/**
 * Add a nested group to a group
 */
export function addNestedGroup(
  group: ConditionGroup,
  nestedGroup: ConditionGroup
): ConditionGroup {
  return {
    ...group,
    conditions: [...group.conditions, nestedGroup]
  }
}

/**
 * Update the operator of a group
 */
export function updateGroupOperator(
  group: ConditionGroup,
  operator: LogicalOperator
): ConditionGroup {
  return {
    ...group,
    operator
  }
}

/**
 * Convert expression to a human-readable string
 */
export function expressionToHumanString(expression: FilterExpression): string {
  return groupToHumanString(expression.rootGroup)
}

function groupToHumanString(group: ConditionGroup): string {
  const parts = group.conditions.map((condition) => {
    if ('field' in condition) {
      return conditionToHumanString(condition as FilterCondition)
    } else {
      return `(${groupToHumanString(condition as ConditionGroup)})`
    }
  })

  const connector = group.operator === 'AND' ? ' and ' : ' or '
  return parts.join(connector)
}

function conditionToHumanString(condition: FilterCondition): string {
  const { field, operator, value } = condition

  let operatorText: string
  switch (operator) {
    case 'equals':
      operatorText = 'is'
      break
    case 'not_equals':
      operatorText = 'is not'
      break
    case 'contains':
      operatorText = 'contains'
      break
    case 'not_contains':
      operatorText = 'does not contain'
      break
    case 'greater_than':
      operatorText = 'is greater than'
      break
    case 'less_than':
      operatorText = 'is less than'
      break
    case 'matches_regex':
      operatorText = 'matches'
      break
    case 'is_set':
      operatorText = 'is set'
      break
    case 'is_not_set':
      operatorText = 'is not set'
      break
    default:
      operatorText = operator
  }

  if (operator === 'is_set' || operator === 'is_not_set') {
    return `${field} ${operatorText}`
  }

  return `${field} ${operatorText} ${value}`
}

/**
 * Check if a field requires a value input
 */
export function fieldRequiresValue(operator: string): boolean {
  return ['equals', 'not_equals', 'contains', 'not_contains', 'greater_than', 'less_than', 'matches_regex'].includes(operator)
}

/**
 * Get validation errors for a specific condition by its path
 */
export function getConditionErrors(errors: FilterBuilderError[], conditionPath: string): FilterBuilderError[] {
  return errors.filter((error) => error.path.startsWith(conditionPath))
}

/**
 * Check if a specific field in a condition has an error
 */
export function hasFieldError(errors: FilterBuilderError[], conditionPath: string, field: string): boolean {
  return errors.some((error) => error.path === `${conditionPath}/${field}`)
}

