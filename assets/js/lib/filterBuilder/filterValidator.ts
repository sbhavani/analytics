import { FilterCondition, FilterGroup, FilterTree } from './types'

export interface ValidationResult {
  isValid: boolean
  errors: string[]
}

export function validateFilterTree(tree: FilterTree): ValidationResult {
  const errors: string[] = []

  if (!tree.rootGroup) {
    errors.push('Filter tree is missing root group')
    return { isValid: false, errors }
  }

  validateGroup(tree.rootGroup, errors)

  return { isValid: errors.length === 0, errors }
}

function validateGroup(group: FilterGroup, errors: string[]): void {
  if (!group.id) {
    errors.push('Group is missing ID')
  }

  if (!group.connector || !['AND', 'OR'].includes(group.connector)) {
    errors.push('Group has invalid connector')
  }

  const conditions = group.conditions || []
  const subgroups = group.subgroups || []

  if (conditions.length === 0 && subgroups.length === 0) {
    errors.push('Group must have at least one condition or subgroup')
  }

  for (const condition of conditions) {
    validateCondition(condition, errors)
  }

  for (const subgroup of subgroups) {
    validateGroup(subgroup, errors)
  }
}

function validateCondition(condition: FilterCondition, errors: string[]): void {
  if (!condition.id) {
    errors.push('Condition is missing ID')
  }

  if (!condition.field) {
    errors.push('Condition is missing field')
  }

  if (!condition.operator) {
    errors.push('Condition is missing operator')
  }

  if (!condition.value && condition.operator !== 'is_true' && condition.operator !== 'is_false') {
    errors.push('Condition is missing value')
  }
}

export function validateConditionComplete(condition: FilterCondition): boolean {
  return !!(
    condition.id &&
    condition.field &&
    condition.operator &&
    (condition.value || condition.operator === 'is_true' || condition.operator === 'is_false')
  )
}

export function getOperatorType(operator: string): 'string' | 'number' | 'boolean' | 'set' {
  const numberOperators = ['equals', 'not_equals', 'greater_than', 'less_than', 'greater_or_equal', 'less_or_equal']
  const booleanOperators = ['is_true', 'is_false']

  if (numberOperators.includes(operator)) return 'number'
  if (booleanOperators.includes(operator)) return 'boolean'

  const setOperators = ['is_one_of', 'is_not_one_of']
  if (setOperators.includes(operator)) return 'set'

  return 'string'
}
