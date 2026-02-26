/**
 * Filter Builder Types Tests
 *
 * Tests for FilterExpression types and helper functions
 * in assets/js/dashboard/components/filter-builder/types.ts
 */

import {
  FilterOperator,
  LogicalOperator,
  FilterCondition,
  ConditionGroup,
  FilterExpression,
  FilterBuilderState,
  FilterBuilderError,
  FilterBuilderErrorType,
  FilterField,
  DEFAULT_FILTER_FIELDS,
  OPERATORS_BY_FIELD_TYPE,
  OPERATOR_DISPLAY_NAMES,
  expressionToFilters,
  createEmptyExpression,
  createCondition,
  createConditionGroup,
  generateId
} from './types'

describe('FilterExpression Types', () => {
  describe('FilterOperator type', () => {
    it('should allow valid operators', () => {
      const operators: FilterOperator[] = [
        'equals',
        'not_equals',
        'contains',
        'not_contains',
        'greater_than',
        'less_than',
        'matches_regex',
        'is_set',
        'is_not_set'
      ]
      expect(operators.length).toBe(9)
    })
  })

  describe('LogicalOperator type', () => {
    it('should allow AND and OR operators', () => {
      const operators: LogicalOperator[] = ['AND', 'OR']
      expect(operators).toContain('AND')
      expect(operators).toContain('OR')
    })
  })

  describe('FilterCondition interface', () => {
    it('should create a valid filter condition', () => {
      const condition: FilterCondition = {
        id: 'test-id',
        field: 'country',
        operator: 'equals',
        value: 'US'
      }

      expect(condition.id).toBe('test-id')
      expect(condition.field).toBe('country')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBe('US')
    })

    it('should allow null value for is_set operator', () => {
      const condition: FilterCondition = {
        id: 'test-id',
        field: 'country',
        operator: 'is_set',
        value: null
      }

      expect(condition.value).toBeNull()
    })

    it('should allow different value types', () => {
      const stringCondition: FilterCondition = {
        id: '1',
        field: 'page',
        operator: 'contains',
        value: '/blog'
      }

      const numberCondition: FilterCondition = {
        id: '2',
        field: 'pageviews',
        operator: 'greater_than',
        value: 10
      }

      const booleanCondition: FilterCondition = {
        id: '3',
        field: 'is_bounce',
        operator: 'equals',
        value: false
      }

      expect(typeof stringCondition.value).toBe('string')
      expect(typeof numberCondition.value).toBe('number')
      expect(typeof booleanCondition.value).toBe('boolean')
    })
  })

  describe('ConditionGroup interface', () => {
    it('should create a valid condition group with AND operator', () => {
      const group: ConditionGroup = {
        id: 'group-1',
        operator: 'AND',
        conditions: []
      }

      expect(group.operator).toBe('AND')
      expect(group.conditions).toEqual([])
    })

    it('should contain child conditions', () => {
      const conditions: FilterCondition[] = [
        { id: '1', field: 'country', operator: 'equals', value: 'US' },
        { id: '2', field: 'page', operator: 'contains', value: '/docs' }
      ]

      const group: ConditionGroup = {
        id: 'group-1',
        operator: 'OR',
        conditions
      }

      expect(group.conditions).toHaveLength(2)
      expect((group.conditions as FilterCondition[])[0].field).toBe('country')
    })

    it('should allow nested groups', () => {
      const nestedGroup: ConditionGroup = {
        id: 'nested-1',
        operator: 'AND',
        conditions: []
      }

      const parentGroup: ConditionGroup = {
        id: 'parent-1',
        operator: 'OR',
        conditions: [nestedGroup]
      }

      expect((parentGroup.conditions as ConditionGroup[])[0].id).toBe('nested-1')
    })
  })

  describe('FilterExpression interface', () => {
    it('should create a valid filter expression with version 1', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: []
        }
      }

      expect(expression.version).toBe(1)
      expect(expression.rootGroup.operator).toBe('AND')
    })
  })

  describe('FilterBuilderErrorType type', () => {
    it('should include all error types', () => {
      const errorTypes: FilterBuilderErrorType[] = [
        'field_required',
        'operator_required',
        'value_required',
        'max_depth_exceeded',
        'max_conditions_exceeded',
        'invalid_field'
      ]

      expect(errorTypes).toHaveLength(6)
    })
  })

  describe('DEFAULT_FILTER_FIELDS', () => {
    it('should contain expected filter fields', () => {
      const fieldKeys = DEFAULT_FILTER_FIELDS.map(f => f.key)

      expect(fieldKeys).toContain('country')
      expect(fieldKeys).toContain('page')
      expect(fieldKeys).toContain('source')
      expect(fieldKeys).toContain('browser')
      expect(fieldKeys).toContain('os')
      expect(fieldKeys).toContain('device')
    })

    it('should have correct field types', () => {
      const countryField = DEFAULT_FILTER_FIELDS.find(f => f.key === 'country')
      const pageField = DEFAULT_FILTER_FIELDS.find(f => f.key === 'page')
      const deviceField = DEFAULT_FILTER_FIELDS.find(f => f.key === 'device')

      expect(countryField?.type).toBe('enum')
      expect(pageField?.type).toBe('string')
      expect(deviceField?.type).toBe('enum')
    })
  })

  describe('OPERATORS_BY_FIELD_TYPE', () => {
    it('should have operators for string fields', () => {
      const stringOperators = OPERATORS_BY_FIELD_TYPE.string

      expect(stringOperators).toContain('equals')
      expect(stringOperators).toContain('contains')
      expect(stringOperators).toContain('matches_regex')
      expect(stringOperators).toContain('is_set')
    })

    it('should have operators for number fields', () => {
      const numberOperators = OPERATORS_BY_FIELD_TYPE.number

      expect(numberOperators).toContain('equals')
      expect(numberOperators).toContain('greater_than')
      expect(numberOperators).toContain('less_than')
    })

    it('should have operators for boolean fields', () => {
      const booleanOperators = OPERATORS_BY_FIELD_TYPE.boolean

      expect(booleanOperators).toContain('equals')
      expect(booleanOperators).toContain('is_set')
      expect(booleanOperators).not.toContain('contains')
    })

    it('should have operators for enum fields', () => {
      const enumOperators = OPERATORS_BY_FIELD_TYPE.enum

      expect(enumOperators).toContain('equals')
      expect(enumOperators).toContain('not_equals')
      expect(enumOperators).not.toContain('contains')
    })
  })

  describe('OPERATOR_DISPLAY_NAMES', () => {
    it('should have display names for all operators', () => {
      expect(OPERATOR_DISPLAY_NAMES.equals).toBe('is')
      expect(OPERATOR_DISPLAY_NAMES.not_equals).toBe('is not')
      expect(OPERATOR_DISPLAY_NAMES.contains).toBe('contains')
      expect(OPERATOR_DISPLAY_NAMES.greater_than).toBe('is greater than')
      expect(OPERATOR_DISPLAY_NAMES.less_than).toBe('is less than')
      expect(OPERATOR_DISPLAY_NAMES.matches_regex).toBe('matches regex')
      expect(OPERATOR_DISPLAY_NAMES.is_set).toBe('is set')
      expect(OPERATOR_DISPLAY_NAMES.is_not_set).toBe('is not set')
    })
  })

  describe('generateId', () => {
    it('should generate unique ids', () => {
      const id1 = generateId()
      const id2 = generateId()

      expect(id1).not.toBe(id2)
    })

    it('should generate string ids', () => {
      const id = generateId()

      expect(typeof id).toBe('string')
      expect(id.length).toBeGreaterThan(0)
    })
  })

  describe('createEmptyExpression', () => {
    it('should create expression with version 1', () => {
      const expression = createEmptyExpression()

      expect(expression.version).toBe(1)
    })

    it('should create root group with AND operator', () => {
      const expression = createEmptyExpression()

      expect(expression.rootGroup.operator).toBe('AND')
      expect(expression.rootGroup.conditions).toEqual([])
    })

    it('should generate id for root group', () => {
      const expression = createEmptyExpression()

      expect(expression.rootGroup.id).toBeDefined()
    })
  })

  describe('createCondition', () => {
    it('should create condition with defaults', () => {
      const condition = createCondition()

      expect(condition.id).toBeDefined()
      expect(condition.field).toBe('')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBeNull()
    })

    it('should create condition with provided values', () => {
      const condition = createCondition('country', 'equals', 'US')

      expect(condition.field).toBe('country')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBe('US')
    })

    it('should allow different operator types', () => {
      const condition = createCondition('page', 'contains', '/blog')

      expect(condition.operator).toBe('contains')
    })
  })

  describe('createConditionGroup', () => {
    it('should create group with defaults', () => {
      const group = createConditionGroup()

      expect(group.id).toBeDefined()
      expect(group.operator).toBe('AND')
      expect(group.conditions).toEqual([])
    })

    it('should create group with OR operator', () => {
      const group = createConditionGroup('OR')

      expect(group.operator).toBe('OR')
    })
  })

  describe('expressionToFilters', () => {
    it('should convert simple expression to filters', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'country',
              operator: 'equals',
              value: 'US'
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters).toHaveLength(1)
      expect(filters[0]).toEqual(['is', 'country', ['US']])
    })

    it('should convert multiple conditions', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'country',
              operator: 'equals',
              value: 'US'
            },
            {
              id: 'cond-2',
              field: 'page',
              operator: 'contains',
              value: '/docs'
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters).toHaveLength(2)
      expect(filters[0]).toEqual(['is', 'country', ['US']])
      expect(filters[1]).toEqual(['contains', 'page', ['/docs']])
    })

    it('should handle not_equals operator', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'browser',
              operator: 'not_equals',
              value: 'Chrome'
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters[0]).toEqual(['is_not', 'browser', ['Chrome']])
    })

    it('should handle is_set operator', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'utm_source',
              operator: 'is_set',
              value: null
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters[0]).toEqual(['is_not_null', 'utm_source', ['utm_source']])
    })

    it('should handle is_not_set operator', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'utm_campaign',
              operator: 'is_not_set',
              value: null
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters[0]).toEqual(['is_null', 'utm_campaign', ['utm_campaign']])
    })

    it('should handle matches_regex operator', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'AND',
          conditions: [
            {
              id: 'cond-1',
              field: 'page',
              operator: 'matches_regex',
              value: '^/docs/.*'
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters[0]).toEqual(['matches', 'page', ['^/docs/.*']])
    })

    it('should flatten nested groups', () => {
      const expression: FilterExpression = {
        version: 1,
        rootGroup: {
          id: 'root-1',
          operator: 'OR',
          conditions: [
            {
              id: 'cond-1',
              field: 'country',
              operator: 'equals',
              value: 'US'
            },
            {
              id: 'nested-1',
              operator: 'AND',
              conditions: [
                {
                  id: 'cond-2',
                  field: 'page',
                  operator: 'contains',
                  value: '/docs'
                }
              ]
            }
          ]
        }
      }

      const filters = expressionToFilters(expression)

      expect(filters).toHaveLength(2)
    })
  })
})
