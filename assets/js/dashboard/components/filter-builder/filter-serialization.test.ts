import {
  conditionToLegacyFilter,
  filterGroupToLegacyFilters,
  legacyFilterToCondition,
  legacyFiltersToFilterGroup,
  serializeFilterGroup,
  deserializeFilterGroup,
  buildQueryFromFilterGroup
} from './filter-serialization'
import { FilterCondition, FilterGroup } from './types'

describe('conditionToLegacyFilter', () => {
  it('converts basic "is" operator', () => {
    const condition: FilterCondition = {
      id: 'test-1',
      field: 'country',
      operator: 'is',
      value: 'US'
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is', 'country', ['US']])
  })

  it('converts "is_not" operator', () => {
    const condition: FilterCondition = {
      id: 'test-2',
      field: 'browser',
      operator: 'is_not',
      value: 'Chrome'
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is_not', 'browser', ['Chrome']])
  })

  it('converts "contains" operator', () => {
    const condition: FilterCondition = {
      id: 'test-3',
      field: 'page',
      operator: 'contains',
      value: '/blog'
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['contains', 'page', ['/blog']])
  })

  it('converts "contains_not" operator', () => {
    const condition: FilterCondition = {
      id: 'test-4',
      field: 'referrer',
      operator: 'contains_not',
      value: 'google'
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['contains_not', 'referrer', ['google']])
  })

  it('handles "is_set" operator', () => {
    const condition: FilterCondition = {
      id: 'test-5',
      field: 'props',
      operator: 'is_set',
      value: ''
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is_not', 'props', ['']])
  })

  it('handles "is_not_set" operator', () => {
    const condition: FilterCondition = {
      id: 'test-6',
      field: 'props',
      operator: 'is_not_set',
      value: ''
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is', 'props', ['']])
  })

  it('handles numeric value', () => {
    const condition: FilterCondition = {
      id: 'test-7',
      field: 'visit_duration',
      operator: 'is',
      value: 120
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is', 'visit_duration', [120]])
  })

  it('handles boolean value', () => {
    const condition: FilterCondition = {
      id: 'test-8',
      field: 'is_bounce',
      operator: 'is',
      value: true
    }
    const result = conditionToLegacyFilter(condition)
    expect(result).toEqual(['is', 'is_bounce', [true]])
  })
})

describe('filterGroupToLegacyFilters', () => {
  it('converts a group with single condition', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        }
      ]
    }
    const result = filterGroupToLegacyFilters(group)
    expect(result).toEqual([['is', 'country', ['US']]])
  })

  it('converts a group with multiple conditions', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        },
        {
          id: 'cond-2',
          field: 'browser',
          operator: 'contains',
          value: 'Chrome'
        }
      ]
    }
    const result = filterGroupToLegacyFilters(group)
    expect(result).toEqual([
      ['is', 'country', ['US']],
      ['contains', 'browser', ['Chrome']]
    ])
  })

  it('converts nested groups', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        },
        {
          id: 'nested-group-1',
          type: 'group',
          operator: 'OR',
          children: [
            {
              id: 'cond-2',
              field: 'browser',
              operator: 'is',
              value: 'Chrome'
            },
            {
              id: 'cond-3',
              field: 'browser',
              operator: 'is',
              value: 'Firefox'
            }
          ]
        }
      ]
    }
    const result = filterGroupToLegacyFilters(group)
    expect(result).toEqual([
      ['is', 'country', ['US']],
      ['is', 'browser', ['Chrome']],
      ['is', 'browser', ['Firefox']]
    ])
  })

  it('handles empty group', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: []
    }
    const result = filterGroupToLegacyFilters(group)
    expect(result).toEqual([])
  })
})

describe('legacyFilterToCondition', () => {
  it('converts "is" operation', () => {
    const filter: [string, string, string[]] = ['is', 'country', ['US']]
    const result = legacyFilterToCondition(filter)
    expect(result.field).toBe('country')
    expect(result.operator).toBe('is')
    expect(result.value).toBe('US')
    expect(result.id).toMatch(/^legacy-/)
  })

  it('converts "is_not" operation', () => {
    const filter: [string, string, string[]] = ['is_not', 'browser', ['Chrome']]
    const result = legacyFilterToCondition(filter)
    expect(result.field).toBe('browser')
    expect(result.operator).toBe('is_not')
    expect(result.value).toBe('Chrome')
  })

  it('converts "contains" operation', () => {
    const filter: [string, string, string[]] = ['contains', 'page', ['/blog']]
    const result = legacyFilterToCondition(filter)
    expect(result.field).toBe('page')
    expect(result.operator).toBe('contains')
    expect(result.value).toBe('/blog')
  })

  it('converts "contains_not" operation', () => {
    const filter: [string, string, string[]] = ['contains_not', 'referrer', ['google']]
    const result = legacyFilterToCondition(filter)
    expect(result.field).toBe('referrer')
    expect(result.operator).toBe('contains_not')
    expect(result.value).toBe('google')
  })

  it('handles empty clause for "is" as "is_set"', () => {
    const filter: [string, string, string[]] = ['is', 'props', ['']]
    const result = legacyFilterToCondition(filter)
    expect(result.operator).toBe('is_set')
    expect(result.value).toBe('')
  })

  it('handles empty clause for "is_not" as "is_not_set"', () => {
    const filter: [string, string, string[]] = ['is_not', 'props', ['']]
    const result = legacyFilterToCondition(filter)
    expect(result.operator).toBe('is_not_set')
    expect(result.value).toBe('')
  })

  it('handles unknown operation defaulting to "is"', () => {
    const filter: [string, string, string[]] = ['unknown_op', 'field', ['value']]
    const result = legacyFilterToCondition(filter)
    expect(result.operator).toBe('is')
  })

  it('handles filter with no clauses', () => {
    const filter: [string, string, string[]] = ['is', 'field', []]
    const result = legacyFilterToCondition(filter)
    expect(result.value).toBe('')
  })

  it('handles filter with numeric clause', () => {
    const filter: [string, string, (string | number)[]] = ['is', 'visit_duration', [120]]
    const result = legacyFilterToCondition(filter)
    expect(result.value).toBe(120)
  })
})

describe('legacyFiltersToFilterGroup', () => {
  it('converts single filter to group', () => {
    const filters: [string, string, string[]][] = [
      ['is', 'country', ['US']]
    ]
    const result = legacyFiltersToFilterGroup(filters)
    expect(result.type).toBe('group')
    expect(result.operator).toBe('AND')
    expect(result.children).toHaveLength(1)
    expect((result.children[0] as FilterCondition).field).toBe('country')
  })

  it('converts multiple filters to group', () => {
    const filters: [string, string, string[]][] = [
      ['is', 'country', ['US']],
      ['is_not', 'browser', ['Chrome']]
    ]
    const result = legacyFiltersToFilterGroup(filters)
    expect(result.children).toHaveLength(2)
    expect((result.children[0] as FilterCondition).field).toBe('country')
    expect((result.children[1] as FilterCondition).field).toBe('browser')
  })

  it('handles empty filters array', () => {
    const filters: [string, string, string[]][] = []
    const result = legacyFiltersToFilterGroup(filters)
    expect(result.children).toHaveLength(0)
  })

  it('generates unique IDs', () => {
    const filters: [string, string, string[]][] = [
      ['is', 'country', ['US']],
      ['is', 'browser', ['Chrome']]
    ]
    const result = legacyFiltersToFilterGroup(filters)
    expect(result.id).toMatch(/^root-/)
    expect(result.children[0].id).toMatch(/^legacy-/)
    expect(result.children[1].id).toMatch(/^legacy-/)
  })
})

describe('serializeFilterGroup', () => {
  it('serializes a simple group', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        }
      ]
    }
    const result = serializeFilterGroup(group)
    expect(result).toBe('[["is","country",["US"]]]')
  })

  it('serializes a group with multiple conditions', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        },
        {
          id: 'cond-2',
          field: 'browser',
          operator: 'contains',
          value: 'Chrome'
        }
      ]
    }
    const result = serializeFilterGroup(group)
    expect(result).toBe('[["is","country",["US"]],["contains","browser",["Chrome"]]]')
  })

  it('serializes empty group', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: []
    }
    const result = serializeFilterGroup(group)
    expect(result).toBe('[]')
  })
})

describe('deserializeFilterGroup', () => {
  it('deserializes a valid JSON string', () => {
    const serialized = '[["is","country",["US"]]]'
    const result = deserializeFilterGroup(serialized)
    expect(result).not.toBeNull()
    expect(result?.type).toBe('group')
    expect(result?.children).toHaveLength(1)
    const child = result?.children[0] as FilterCondition
    expect(child.field).toBe('country')
  })

  it('deserializes multiple filters', () => {
    const serialized = '[["is","country",["US"]],["is_not","browser",["Chrome"]]]'
    const result = deserializeFilterGroup(serialized)
    expect(result?.children).toHaveLength(2)
  })

  it('returns null for invalid JSON', () => {
    const serialized = 'invalid json'
    const result = deserializeFilterGroup(serialized)
    expect(result).toBeNull()
  })

  it('returns null for empty string', () => {
    const serialized = ''
    const result = deserializeFilterGroup(serialized)
    expect(result).toBeNull()
  })

  it('round-trips correctly', () => {
    const original: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        }
      ]
    }
    const serialized = serializeFilterGroup(original)
    const deserialized = deserializeFilterGroup(serialized)
    const child = deserialized?.children[0] as FilterCondition
    expect(child.field).toBe('country')
    expect(child.operator).toBe('is')
    expect(child.value).toBe('US')
  })
})

describe('buildQueryFromFilterGroup', () => {
  it('builds query with filters parameter', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        }
      ]
    }
    const result = buildQueryFromFilterGroup(group)
    expect(result.filters).toBe('[["is","country",["US"]]]')
  })

  it('builds query with multiple filters', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        },
        {
          id: 'cond-2',
          field: 'browser',
          operator: 'contains',
          value: 'Chrome'
        }
      ]
    }
    const result = buildQueryFromFilterGroup(group)
    expect(result.filters).toBe('[["is","country",["US"]],["contains","browser",["Chrome"]]]')
  })

  it('returns object with filters key only', () => {
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: []
    }
    const result = buildQueryFromFilterGroup(group)
    expect(Object.keys(result)).toEqual(['filters'])
  })
})

describe('full round-trip', () => {
  it('converts FilterCondition to legacy and back', () => {
    const original: FilterCondition = {
      id: 'cond-1',
      field: 'country',
      operator: 'is',
      value: 'US'
    }
    const group: FilterGroup = {
      id: 'group-1',
      type: 'group',
      operator: 'AND',
      children: [original]
    }

    const legacy = filterGroupToLegacyFilters(group)
    const restored = legacyFiltersToFilterGroup(legacy)

    const restoredChild = restored.children[0] as FilterCondition
    expect(restoredChild.field).toBe(original.field)
    expect(restoredChild.operator).toBe(original.operator)
    expect(restoredChild.value).toBe(original.value)
  })

  it('handles complex nested groups', () => {
    const group: FilterGroup = {
      id: 'root',
      type: 'group',
      operator: 'OR',
      children: [
        {
          id: 'cond-1',
          field: 'country',
          operator: 'is',
          value: 'US'
        },
        {
          id: 'nested-1',
          type: 'group',
          operator: 'AND',
          children: [
            {
              id: 'cond-2',
              field: 'browser',
              operator: 'contains',
              value: 'Chrome'
            },
            {
              id: 'cond-3',
              field: 'page',
              operator: 'is',
              value: '/docs'
            }
          ]
        }
      ]
    }

    const serialized = serializeFilterGroup(group)
    const deserialized = deserializeFilterGroup(serialized)

    // Serialization flattens nested groups, so all conditions end up at the top level
    expect(deserialized?.children).toHaveLength(3)
    expect((deserialized?.children[0] as FilterCondition).field).toBe('country')
  })
})
