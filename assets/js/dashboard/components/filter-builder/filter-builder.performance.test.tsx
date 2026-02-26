/**
 * Filter Builder Performance Tests
 *
 * Tests to verify UI operations respond within 100ms as per performance requirements.
 * See: https://plausible.io/docs/segments#performance-goals
 *
 * These tests focus on the utility functions that power the filter builder.
 * The component rendering tests require the FilterBuilder component to be functional.
 */

import {
  FilterExpression,
  FilterCondition,
  ConditionGroup,
  createEmptyExpression,
  createCondition,
  createConditionGroup,
  FilterExpressionNode
} from './types'
import { validateExpression, countConditions, getNestingDepth, addConditionToGroup, updateConditionInGroup, removeConditionFromGroup, addNestedGroup } from './utils'

// Performance threshold in milliseconds
const PERFORMANCE_THRESHOLD_MS = 100

describe('Filter Builder Performance Tests', () => {
  describe('Utility Functions Performance', () => {
    /**
     * Test that expression validation completes within 100ms
     * This is critical for real-time feedback as users build filters
     */
    it('validateExpression should complete within 100ms for simple expression', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'test-group-1',
          operator: 'AND',
          conditions: [
            createCondition('country', 'equals', 'US'),
            createCondition('browser', 'equals', 'Chrome')
          ]
        }
      }

      const startTime = performance.now()
      for (let i = 0; i < 100; i++) {
        validateExpression(expression)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 100
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('validateExpression should complete within 100ms for complex nested expression', () => {
      // Create a deeply nested expression with multiple conditions
      const complexExpression: FilterExpression = {
        version: 1,
        rootGroup: createComplexGroup(3, 3) // 3 levels, 3 conditions each
      }

      const startTime = performance.now()
      for (let i = 0; i < 100; i++) {
        validateExpression(complexExpression)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 100
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    /**
     * Test that condition count operations complete within 100ms
     */
    it('countConditions should complete within 100ms', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: createComplexGroup(5, 5)
      }

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        countConditions(expression.rootGroup)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    /**
     * Test that nesting depth calculation completes within 100ms
     */
    it('getNestingDepth should complete within 100ms', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: createComplexGroup(5, 3)
      }

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        getNestingDepth(expression.rootGroup)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    /**
     * Test that condition manipulation operations complete within 100ms
     */
    it('addConditionToGroup should complete within 100ms', () => {
      const group: ConditionGroup = {
        id: 'test-group',
        operator: 'AND',
        conditions: []
      }
      const newCondition = createCondition('country', 'equals', 'US')

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        addConditionToGroup(group, newCondition)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('updateConditionInGroup should complete within 100ms', () => {
      const existingCondition = createCondition('country', 'equals', 'US')
      const group: ConditionGroup = {
        id: 'test-group',
        operator: 'AND',
        conditions: [existingCondition]
      }

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        updateConditionInGroup(group, existingCondition.id, { value: 'UK' })
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('removeConditionFromGroup should complete within 100ms', () => {
      const existingCondition = createCondition('country', 'equals', 'US')
      const group: ConditionGroup = {
        id: 'test-group',
        operator: 'AND',
        conditions: [existingCondition]
      }

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        removeConditionFromGroup(group, existingCondition.id)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('addNestedGroup should complete within 100ms', () => {
      const existingCondition = createCondition('country', 'equals', 'US')
      const group: ConditionGroup = {
        id: 'test-group',
        operator: 'AND',
        conditions: [existingCondition]
      }
      const nestedGroup = createConditionGroup('OR')

      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        addNestedGroup(group, nestedGroup)
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })
  })

  describe('Expression Creation Performance', () => {
    /**
     * Test that creating filter expressions completes within 100ms
     */
    it('createEmptyExpression should complete within 100ms', () => {
      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        createEmptyExpression()
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('createCondition should complete within 100ms', () => {
      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        createCondition('country', 'equals', 'US')
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('createConditionGroup should complete within 100ms', () => {
      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        createConditionGroup('AND')
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    it('generateId should complete within 100ms', () => {
      const startTime = performance.now()
      for (let i = 0; i < 1000; i++) {
        // We can't directly test generateId as it's not exported,
        // but we can test createCondition which uses it
        createCondition('field', 'equals', 'value')
      }
      const endTime = performance.now()

      const avgTime = (endTime - startTime) / 1000
      expect(avgTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })
  })

  describe('Stress Tests', () => {
    /**
     * Test validation performance under load with maximum conditions
     */
    it('Validation should remain fast with maximum conditions', () => {
      // Create expression exceeding max allowed conditions (50) - use 51 to trigger error
      const maxConditions: FilterCondition[] = Array.from({ length: 51 }, (_, i) =>
        createCondition(`field${i}`, 'equals', `value${i}`)
      )

      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'test-group',
          operator: 'AND',
          conditions: maxConditions
        }
      }

      const startTime = performance.now()
      const result = validateExpression(expression)
      const endTime = performance.now()

      const validationTime = endTime - startTime
      expect(validationTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
      // Should also return max_conditions_exceeded error
      expect(result.some(e => e.type === 'max_conditions_exceeded')).toBe(true)
    })

    /**
     * Test that deep nesting validation completes within 100ms
     */
    it('Deep nesting validation should complete within 100ms', () => {
      // Create expression with max allowed nesting (5 levels)
      const deepExpression: FilterExpression = {
        version: 1,
        rootGroup: createComplexGroup(5, 2)
      }

      const startTime = performance.now()
      const result = validateExpression(deepExpression)
      const endTime = performance.now()

      const validationTime = endTime - startTime
      expect(validationTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })

    /**
     * Test rapid creation and manipulation of expressions
     */
    it('Rapid expression manipulation should each complete within 100ms', () => {
      let group = createConditionGroup('AND')

      // Add 10 conditions
      const startAdd = performance.now()
      for (let i = 0; i < 10; i++) {
        group = addConditionToGroup(group, createCondition(`field${i}`, 'equals', `value${i}`))
      }
      const addTime = performance.now() - startAdd
      expect(addTime / 10).toBeLessThan(PERFORMANCE_THRESHOLD_MS)

      // Get all condition IDs
      const conditionIds = group.conditions.map(c => (c as FilterCondition).id)

      // Update all conditions
      const startUpdate = performance.now()
      for (const id of conditionIds) {
        group = updateConditionInGroup(group, id, { value: 'updated' })
      }
      const updateTime = performance.now() - startUpdate
      expect(updateTime / conditionIds.length).toBeLessThan(PERFORMANCE_THRESHOLD_MS)

      // Remove all conditions
      const startRemove = performance.now()
      for (const id of conditionIds) {
        group = removeConditionFromGroup(group, id)
      }
      const removeTime = performance.now() - startRemove
      expect(removeTime / conditionIds.length).toBeLessThan(PERFORMANCE_THRESHOLD_MS)
    })
  })

  describe('Performance Regression Tests', () => {
    /**
     * These tests ensure that performance doesn't degrade over time
     * by running operations multiple times and checking consistency
     */
    it('Performance should remain consistent across multiple runs', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'test-group',
          operator: 'AND',
          conditions: Array.from({ length: 10 }, (_, i) =>
            createCondition(`field${i}`, 'equals', `value${i}`)
          )
        }
      }

      const times: number[] = []

      // Run validation 10 times and collect times
      for (let run = 0; run < 10; run++) {
        const startTime = performance.now()
        validateExpression(expression)
        const endTime = performance.now()
        times.push(endTime - startTime)
      }

      // All times should be under threshold
      const maxTime = Math.max(...times)
      expect(maxTime).toBeLessThan(PERFORMANCE_THRESHOLD_MS)

      // Check for regression: latest run shouldn't be significantly slower
      const avgTime = times.reduce((a, b) => a + b, 0) / times.length
      const latestTime = times[times.length - 1]
      expect(latestTime).toBeLessThan(avgTime * 2) // Allow 2x variance
    })
  })
})

/**
 * Helper function to create a complex nested group structure for testing
 */
function createComplexGroup(depth: number, conditionsPerLevel: number): ConditionGroup {
  if (depth === 0) {
    return {
      id: `group-${depth}`,
      operator: 'AND',
      conditions: Array.from({ length: conditionsPerLevel }, (_, i) =>
        createCondition(`field${i}`, 'equals', `value${i}`)
      )
    }
  }

  const nestedGroup = createComplexGroup(depth - 1, conditionsPerLevel)
  const conditions: FilterExpressionNode[] = Array.from(
    { length: conditionsPerLevel },
    (_, i) => createCondition(`field${depth}-${i}`, 'equals', `value${depth}-${i}`)
  )
  conditions.push(nestedGroup)

  return {
    id: `group-${depth}`,
    operator: 'AND',
    conditions
  }
}
