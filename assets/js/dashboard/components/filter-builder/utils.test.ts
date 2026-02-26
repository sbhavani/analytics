/**
 * Filter Builder Utils Tests
 *
 * Tests for utility functions in the Advanced Filter Builder
 */

import {
  createEmptyExpression,
  createCondition,
  createConditionGroup,
  generateId,
  FilterExpression,
  FilterCondition,
  ConditionGroup
} from './types'
import {
  expressionToHumanString,
  validateExpression,
  isExpressionValid,
  countConditions,
  getNestingDepth,
  addConditionToGroup,
  removeConditionFromGroup,
  updateConditionInGroup,
  updateGroupOperator,
  addNestedGroup,
  fieldRequiresValue,
  MAX_NESTING_DEPTH,
  MAX_TOTAL_CONDITIONS
} from './utils'

describe('Filter Builder Utils', () => {
  describe('createEmptyExpression', () => {
    it('creates an empty expression with version 1', () => {
      const expression = createEmptyExpression()
      expect(expression.version).toBe(1)
      expect(expression.rootGroup).toBeDefined()
      expect(expression.rootGroup.operator).toBe('AND')
      expect(expression.rootGroup.conditions).toEqual([])
    })

    it('generates a unique ID for the root group', () => {
      const expression1 = createEmptyExpression()
      const expression2 = createEmptyExpression()
      expect(expression1.rootGroup.id).not.toBe(expression2.rootGroup.id)
    })
  })

  describe('createCondition', () => {
    it('creates a condition with defaults', () => {
      const condition = createCondition()
      expect(condition.id).toBeDefined()
      expect(condition.field).toBe('')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBeNull()
    })

    it('creates a condition with provided values', () => {
      const condition = createCondition('country', 'equals', 'US')
      expect(condition.field).toBe('country')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBe('US')
    })
  })

  describe('createConditionGroup', () => {
    it('creates a group with defaults', () => {
      const group = createConditionGroup()
      expect(group.id).toBeDefined()
      expect(group.operator).toBe('AND')
      expect(group.conditions).toEqual([])
    })

    it('creates a group with OR operator', () => {
      const group = createConditionGroup('OR')
      expect(group.operator).toBe('OR')
    })
  })

  describe('countConditions', () => {
    it('counts single condition', () => {
      const expression = createEmptyExpression()
      expression.rootGroup.conditions.push(createCondition('country', 'equals', 'US') as FilterCondition)
      expect(countConditions(expression.rootGroup)).toBe(1)
    })

    it('counts multiple conditions in a group', () => {
      const group = createConditionGroup('AND')
      group.conditions = [
        createCondition('country', 'equals', 'US'),
        createCondition('browser', 'equals', 'Chrome')
      ] as FilterCondition[]
      expect(countConditions(group)).toBe(2)
    })

    it('counts conditions in nested groups', () => {
      const group = createConditionGroup('AND')
      const nestedGroup = createConditionGroup('OR')
      nestedGroup.conditions = [
        createCondition('country', 'equals', 'US'),
        createCondition('country', 'equals', 'UK')
      ] as FilterCondition[]
      group.conditions = [
        createCondition('browser', 'equals', 'Chrome'),
        nestedGroup
      ] as (FilterCondition | ConditionGroup)[]
      expect(countConditions(group)).toBe(3)
    })
  })

  describe('getNestingDepth', () => {
    it('returns 1 for a flat group', () => {
      const group = createConditionGroup('AND')
      group.conditions.push(createCondition('country', 'equals', 'US') as FilterCondition)
      expect(getNestingDepth(group)).toBe(1)
    })

    it('returns correct depth for nested groups', () => {
      const group = createConditionGroup('AND')
      const nestedGroup1 = createConditionGroup('OR')
      const nestedGroup2 = createConditionGroup('AND')

      nestedGroup2.conditions.push(createCondition('browser', 'equals', 'Chrome') as FilterCondition)
      nestedGroup1.conditions.push(nestedGroup2 as ConditionGroup)
      group.conditions.push(nestedGroup1 as ConditionGroup)

      expect(getNestingDepth(group)).toBe(3)
    })

    it('respects MAX_NESTING_DEPTH constant', () => {
      expect(MAX_NESTING_DEPTH).toBe(5)
    })
  })

  describe('validateExpression', () => {
    it('validates a valid expression', () => {
      const expression = createEmptyExpression()
      expression.rootGroup.conditions.push(createCondition('country', 'equals', 'US') as FilterCondition)
      const errors = validateExpression(expression)
      expect(errors.length).toBe(0)
    })

    it('reports error for missing root group', () => {
      const expression = { version: 1 } as FilterExpression
      const errors = validateExpression(expression)
      expect(errors.length).toBeGreaterThan(0)
      expect(errors[0].type).toBe('field_required')
    })

    it('reports error for group without operator', () => {
      const group = { id: '1', operator: '' as any, conditions: [] }
      const expression: FilterExpression = {
        version: 1,
        rootGroup: group
      }
      const errors = validateExpression(expression)
      expect(errors.some(e => e.type === 'operator_required')).toBe(true)
    })

    it('reports error for empty group', () => {
      const expression = createEmptyExpression()
      const errors = validateExpression(expression)
      expect(errors.some(e => e.type === 'field_required')).toBe(true)
    })

    it('reports error when MAX_TOTAL_CONDITIONS exceeded', () => {
      const expression = createEmptyExpression()
      // Add MAX_TOTAL_CONDITIONS + 1 conditions
      for (let i = 0; i <= MAX_TOTAL_CONDITIONS; i++) {
        expression.rootGroup.conditions.push(createCondition(`field${i}`, 'equals', 'value') as FilterCondition)
      }
      const errors = validateExpression(expression)
      expect(errors.some(e => e.type === 'max_conditions_exceeded')).toBe(true)
    })

    it('reports error when MAX_NESTING_DEPTH exceeded', () => {
      const expression = createEmptyExpression()
      let currentGroup = expression.rootGroup

      // Create nested groups beyond MAX_NESTING_DEPTH
      for (let i = 0; i < MAX_NESTING_DEPTH; i++) {
        const newGroup = createConditionGroup('AND')
        currentGroup.conditions.push(newGroup as unknown as FilterCondition)
        currentGroup = newGroup
      }

      const errors = validateExpression(expression)
      expect(errors.some(e => e.type === 'max_depth_exceeded')).toBe(true)
    })
  })

  describe('isExpressionValid', () => {
    it('returns true for valid expression', () => {
      const expression = createEmptyExpression()
      expression.rootGroup.conditions.push(createCondition('country', 'equals', 'US') as FilterCondition)
      expect(isExpressionValid(expression)).toBe(true)
    })

    it('returns false for invalid expression', () => {
      const expression = createEmptyExpression()
      expect(isExpressionValid(expression)).toBe(false)
    })
  })

  describe('addConditionToGroup', () => {
    it('adds a condition to a group', () => {
      const group = createConditionGroup('AND')
      const condition = createCondition('country', 'equals', 'US')
      const updatedGroup = addConditionToGroup(group, condition)
      expect(updatedGroup.conditions.length).toBe(1)
      expect(updatedGroup.conditions[0]).toEqual(condition)
    })
  })

  describe('removeConditionFromGroup', () => {
    it('removes a condition by ID', () => {
      const condition1 = createCondition('country', 'equals', 'US')
      const condition2 = createCondition('browser', 'equals', 'Chrome')
      const group: ConditionGroup = {
        id: 'group1',
        operator: 'AND',
        conditions: [condition1, condition2]
      }
      const updatedGroup = removeConditionFromGroup(group, condition1.id)
      expect(updatedGroup.conditions.length).toBe(1)
      expect((updatedGroup.conditions[0] as FilterCondition).id).toBe(condition2.id)
    })

    it('removes a nested group by ID', () => {
      const nestedGroup = createConditionGroup('OR')
      const topLevelCondition = createCondition('country', 'equals', 'US')
      const group: ConditionGroup = {
        id: 'group1',
        operator: 'AND',
        conditions: [nestedGroup, topLevelCondition]
      }
      const updatedGroup = removeConditionFromGroup(group, nestedGroup.id)
      expect(updatedGroup.conditions.length).toBe(1)
      expect(updatedGroup.conditions[0]).toEqual(topLevelCondition)
    })
  })

  describe('updateConditionInGroup', () => {
    it('updates a condition in a group', () => {
      const condition = createCondition('country', 'equals', 'US')
      const group: ConditionGroup = {
        id: 'group1',
        operator: 'AND',
        conditions: [condition]
      }
      const updatedGroup = updateConditionInGroup(group, condition.id, { value: 'UK' })
      expect((updatedGroup.conditions[0] as FilterCondition).value).toBe('UK')
    })
  })

  describe('updateGroupOperator', () => {
    it('updates the operator of a group', () => {
      const group = createConditionGroup('AND')
      const updatedGroup = updateGroupOperator(group, 'OR')
      expect(updatedGroup.operator).toBe('OR')
    })
  })

  describe('addNestedGroup', () => {
    it('adds a nested group to a group', () => {
      const group = createConditionGroup('AND')
      const nestedGroup = createConditionGroup('OR')
      const updatedGroup = addNestedGroup(group, nestedGroup)
      expect(updatedGroup.conditions.length).toBe(1)
      expect(updatedGroup.conditions[0]).toEqual(nestedGroup)
    })
  })

  describe('fieldRequiresValue', () => {
    it('returns true for operators that need values', () => {
      expect(fieldRequiresValue('equals')).toBe(true)
      expect(fieldRequiresValue('not_equals')).toBe(true)
      expect(fieldRequiresValue('contains')).toBe(true)
      expect(fieldRequiresValue('greater_than')).toBe(true)
      expect(fieldRequiresValue('matches_regex')).toBe(true)
    })

    it('returns false for operators that do not need values', () => {
      expect(fieldRequiresValue('is_set')).toBe(false)
      expect(fieldRequiresValue('is_not_set')).toBe(false)
    })
  })

  describe('AND logic evaluation', () => {
    it('converts AND expression to human-readable string', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'AND',
          conditions: [
            { id: '1', field: 'country', operator: 'equals', value: 'US' },
            { id: '2', field: 'browser', operator: 'equals', value: 'Chrome' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('country is US and browser is Chrome')
    })

    it('handles multiple AND conditions', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'AND',
          conditions: [
            { id: '1', field: 'country', operator: 'equals', value: 'US' },
            { id: '2', field: 'browser', operator: 'equals', value: 'Chrome' },
            { id: '3', field: 'page', operator: 'contains', value: '/docs' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('country is US and browser is Chrome and page contains /docs')
    })
  })

  describe('OR logic evaluation', () => {
    it('converts OR expression to human-readable string', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            { id: '1', field: 'country', operator: 'equals', value: 'US' },
            { id: '2', field: 'country', operator: 'equals', value: 'UK' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('country is US or country is UK')
    })

    it('handles multiple OR conditions', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            { id: '1', field: 'source', operator: 'equals', value: 'google' },
            { id: '2', field: 'source', operator: 'equals', value: 'twitter' },
            { id: '3', field: 'source', operator: 'equals', value: 'facebook' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('source is google or source is twitter or source is facebook')
    })

    it('correctly evaluates different operators in OR group', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            { id: '1', field: 'country', operator: 'equals', value: 'US' },
            { id: '2', field: 'page', operator: 'contains', value: '/pricing' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('country is US or page contains /pricing')
    })

    it('handles not_equals operator in OR group', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            { id: '1', field: 'browser', operator: 'not_equals', value: 'Safari' },
            { id: '2', field: 'device', operator: 'equals', value: 'Desktop' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('browser is not Safari or device is Desktop')
    })

    it('handles is_set and is_not_set operators in OR group', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            { id: '1', field: 'utm_source', operator: 'is_set', value: null },
            { id: '2', field: 'referrer', operator: 'is_not_set', value: null }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('utm_source is set or referrer is not set')
    })
  })

  describe('Nested group evaluation with OR', () => {
    it('handles OR nested within AND', () => {
      const nestedGroup: ConditionGroup = {
        id: 'nested1',
        operator: 'OR',
        conditions: [
          { id: '2', field: 'source', operator: 'equals', value: 'google' },
          { id: '3', field: 'source', operator: 'equals', value: 'twitter' }
        ]
      }
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'AND',
          conditions: [
            { id: '1', field: 'country', operator: 'equals', value: 'US' },
            nestedGroup
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('country is US and (source is google or source is twitter)')
    })

    it('handles AND nested within OR', () => {
      const nestedGroup: ConditionGroup = {
        id: 'nested1',
        operator: 'AND',
        conditions: [
          { id: '1', field: 'country', operator: 'equals', value: 'US' },
          { id: '2', field: 'browser', operator: 'equals', value: 'Chrome' }
        ]
      }
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            nestedGroup,
            { id: '3', field: 'country', operator: 'equals', value: 'UK' }
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('(country is US and browser is Chrome) or country is UK')
    })

    it('handles complex nested OR expressions', () => {
      const nestedGroup1: ConditionGroup = {
        id: 'nested1',
        operator: 'OR',
        conditions: [
          { id: '1', field: 'country', operator: 'equals', value: 'US' },
          { id: '2', field: 'country', operator: 'equals', value: 'CA' }
        ]
      }
      const nestedGroup2: ConditionGroup = {
        id: 'nested2',
        operator: 'OR',
        conditions: [
          { id: '3', field: 'source', operator: 'equals', value: 'google' },
          { id: '4', field: 'source', operator: 'equals', value: 'bing' }
        ]
      }
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root',
          operator: 'OR',
          conditions: [
            nestedGroup1,
            nestedGroup2
          ]
        }
      }

      const result = expressionToHumanString(expression)
      expect(result).toBe('(country is US or country is CA) or (source is google or source is bing)')
    })
  })
})
