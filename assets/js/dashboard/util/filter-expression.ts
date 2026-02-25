// Utility functions for filter expression validation, serialization, and parsing
import {
  FilterExpression,
  FilterGroup,
  FilterCondition,
  filterExpressionToLegacyFilters,
  legacyFiltersToFilterExpression
} from '../types/filter-expression'

// Validation constants
const MAX_CONDITIONS = 20
const MAX_NESTING_LEVELS = 5

export interface ValidationResult {
  valid: boolean
  errors: string[]
}

// Validate a filter expression
export function validateFilterExpression(expression: FilterExpression): ValidationResult {
  const errors: string[] = []

  if (!expression || !expression.root) {
    return { valid: false, errors: ['Filter expression is empty'] }
  }

  // Count total conditions
  let conditionCount = 0
  let maxDepth = 0

  function traverseGroup(group: FilterGroup, depth: number) {
    maxDepth = Math.max(maxDepth, depth)

    for (const child of group.children) {
      if ('dimension' in child) {
        // It's a FilterCondition
        conditionCount++

        // Validate condition
        if (!child.dimension) {
          errors.push('Condition has no dimension')
        }
        if (!child.operator) {
          errors.push('Condition has no operator')
        }
        if (child.operator !== 'is-set' && child.operator !== 'is-not-set' && !child.value) {
          errors.push(`Condition for ${child.dimension} has no value`)
        }
      } else {
        // It's a nested group
        traverseGroup(child, depth + 1)
      }
    }
  }

  traverseGroup(expression.root, 1)

  // Check condition count
  if (conditionCount === 0) {
    errors.push('Filter must have at least one condition')
  }
  if (conditionCount > MAX_CONDITIONS) {
    errors.push(`Filter cannot have more than ${MAX_CONDITIONS} conditions`)
  }

  // Check nesting depth
  if (maxDepth > MAX_NESTING_LEVELS) {
    errors.push(`Filter cannot nest more than ${MAX_NESTING_LEVELS} levels`)
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

// Count total conditions in an expression
export function countConditions(expression: FilterExpression): number {
  let count = 0

  function traverseGroup(group: FilterGroup) {
    for (const child of group.children) {
      if ('dimension' in child) {
        count++
      } else {
        traverseGroup(child)
      }
    }
  }

  traverseGroup(expression.root)
  return count
}

// Get the nesting depth of an expression
export function getNestingDepth(expression: FilterExpression): number {
  let maxDepth = 0

  function traverseGroup(group: FilterGroup, depth: number) {
    maxDepth = Math.max(maxDepth, depth)

    for (const child of group.children) {
      if (!('dimension' in child)) {
        traverseGroup(child, depth + 1)
      }
    }
  }

  traverseGroup(expression.root, 1)
  return maxDepth
}

// Serialize filter expression to JSON string
export function serializeFilterExpression(expression: FilterExpression): string {
  return JSON.stringify(expression)
}

// Parse filter expression from JSON string
export function parseFilterExpression(json: string): FilterExpression | null {
  if (!json || typeof json !== 'string') {
    return null
  }

  try {
    const parsed = JSON.parse(json)

    // Validate basic structure
    if (!parsed || typeof parsed !== 'object') {
      return null
    }

    if (!parsed.root || typeof parsed.root !== 'object') {
      return null
    }

    // Validate the root group
    const rootValidation = validateGroup(parsed.root)
    if (!rootValidation.valid) {
      return null
    }

    return parsed as FilterExpression
  } catch {
    return null
  }
}

// Validate a filter group structure
function validateGroup(group: any): ValidationResult {
  const errors: string[] = []

  if (!group.id || typeof group.id !== 'string') {
    errors.push('Group missing valid id')
  }

  if (!group.operator || !['AND', 'OR'].includes(group.operator)) {
    errors.push('Group missing valid operator')
  }

  if (!Array.isArray(group.children)) {
    errors.push('Group missing children array')
    return { valid: false, errors }
  }

  for (const child of group.children) {
    if ('dimension' in child) {
      // Validate FilterCondition
      if (!child.id || typeof child.id !== 'string') {
        errors.push('Condition missing valid id')
      }
      if (!child.dimension || typeof child.dimension !== 'string') {
        errors.push('Condition missing valid dimension')
      }
      if (!child.operator || typeof child.operator !== 'string') {
        errors.push('Condition missing valid operator')
      }
      // Value can be null, string, number, or array
      if (child.value !== null &&
          typeof child.value !== 'string' &&
          typeof child.value !== 'number' &&
          !Array.isArray(child.value)) {
        errors.push('Condition has invalid value type')
      }
    } else {
      // Validate nested FilterGroup
      const nestedValidation = validateGroup(child)
      errors.push(...nestedValidation.errors)
    }
  }

  return { valid: errors.length === 0, errors }
}

// Convert from/to legacy filter format
export {
  filterExpressionToLegacyFilters,
  legacyFiltersToFilterExpression
}

// Add a condition to a filter group
export function addConditionToGroup(group: FilterGroup, condition: FilterCondition): FilterGroup {
  return {
    ...group,
    children: [...group.children, condition]
  }
}

// Remove a condition from a filter group by ID
export function removeConditionFromGroup(group: FilterGroup, conditionId: string): FilterGroup {
  return {
    ...group,
    children: group.children.filter(child => {
      if ('dimension' in child) {
        return child.id !== conditionId
      }
      return child.id !== conditionId
    })
  }
}

// Update a condition in a filter group
export function updateConditionInGroup(group: FilterGroup, conditionId: string, updates: Partial<FilterCondition>): FilterGroup {
  return {
    ...group,
    children: group.children.map(child => {
      if ('dimension' in child && child.id === conditionId) {
        return { ...child, ...updates }
      }
      if (!('dimension' in child) && child.id === conditionId) {
        return child
      }
      return child
    })
  }
}

// Change the operator of a group
export function changeGroupOperator(group: FilterGroup, newOperator: 'AND' | 'OR'): FilterGroup {
  return {
    ...group,
    operator: newOperator
  }
}

// Create a nested group from selected conditions
export function createNestedGroup(
  parentGroup: FilterGroup,
  conditionIds: string[],
  newOperator: 'AND' | 'OR'
): FilterGroup {
  const selectedChildren: (FilterCondition | FilterGroup)[] = []
  const remainingChildren: (FilterCondition | FilterGroup)[] = []

  for (const child of parentGroup.children) {
    if ('dimension' in child) {
      if (conditionIds.includes(child.id)) {
        selectedChildren.push(child)
      } else {
        remainingChildren.push(child)
      }
    } else {
      if (conditionIds.includes(child.id)) {
        selectedChildren.push(child)
      } else {
        remainingChildren.push(child)
      }
    }
  }

  const nestedGroup: FilterGroup = {
    id: generateId(),
    operator: newOperator,
    children: selectedChildren
  }

  return {
    ...parentGroup,
    children: [...remainingChildren, nestedGroup]
  }
}

function generateId(): string {
  return Math.random().toString(36).substring(2, 11)
}

// Flatten a nested filter expression (for legacy systems)
export function flattenFilterExpression(expression: FilterExpression): FilterCondition[] {
  const conditions: FilterCondition[] = []

  function traverseGroup(group: FilterGroup) {
    for (const child of group.children) {
      if ('dimension' in child) {
        conditions.push(child)
      } else {
        traverseGroup(child)
      }
    }
  }

  traverseGroup(expression.root)
  return conditions
}

// Get all conditions as a flat array with their parent group info
export function getAllConditionsWithContext(
  expression: FilterExpression
): Array<{ condition: FilterCondition; parentOperator: 'AND' | 'OR'; depth: number }> {
  const results: Array<{ condition: FilterCondition; parentOperator: 'AND' | 'OR'; depth: number }> = []

  function traverseGroup(group: FilterGroup, depth: number) {
    for (const child of group.children) {
      if ('dimension' in child) {
        results.push({
          condition: child,
          parentOperator: group.operator,
          depth
        })
      } else {
        traverseGroup(child, depth + 1)
      }
    }
  }

  traverseGroup(expression.root, 1)
  return results
}
