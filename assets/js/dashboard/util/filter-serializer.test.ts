import {
  flatToNested,
  nestedToFlat,
  isFilterGroup,
  isFilterCondition,
  getNestingDepth,
  isValidNestingDepth,
  getChildCount,
  isValidChildCount,
  createEmptyFilterGroup,
  createFilterCondition,
  addConditionToGroup,
  removeConditionFromGroup,
  updateConditionInGroup,
  changeGroupFilterType,
  serializeFilter,
  deserializeFilter,
  isValidFilter,
  getAllLeafConditions,
  FilterGroup,
  FilterCondition,
  FilterComposite,
  MAX_NESTING_DEPTH,
  MAX_CHILDREN_PER_GROUP
} from './filter-serializer'

describe('Filter Serializer', () => {
  describe('flatToNested', () => {
    it('converts flat array to nested format', () => {
      const flat = [
        ['is', 'country', ['US']],
        ['is', 'device', ['mobile']]
      ] as any

      const result = flatToNested(flat)

      expect(result).toEqual({
        filter_type: 'and',
        children: flat
      })
    })
  })

  describe('nestedToFlat', () => {
    it('converts nested AND group to flat array', () => {
      const nested: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition,
          ['is', 'device', ['mobile']] as FilterCondition
        ]
      }

      const result = nestedToFlat(nested)

      expect(result).toEqual([
        ['is', 'country', ['US']],
        ['is', 'device', ['mobile']]
      ])
    })

    it('keeps OR groups as nested structure', () => {
      const nested: FilterComposite = {
        filter_type: 'or',
        children: [
          { filter_type: 'and', children: [['is', 'country', ['US']] as FilterCondition] },
          { filter_type: 'and', children: [['is', 'country', ['UK']] as FilterCondition] }
        ]
      } as FilterComposite

      const result = nestedToFlat(nested)

      expect(result).toEqual([nested])
    })
  })

  describe('isFilterGroup', () => {
    it('returns true for filter group', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: []
      }

      expect(isFilterGroup(group)).toBe(true)
    })

    it('returns false for filter condition', () => {
      const condition: FilterCondition = ['is', 'country', ['US']]

      expect(isFilterGroup(condition)).toBe(false)
    })
  })

  describe('isFilterCondition', () => {
    it('returns true for filter condition', () => {
      const condition: FilterCondition = ['is', 'country', ['US']]

      expect(isFilterCondition(condition)).toBe(true)
    })

    it('returns false for filter group', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: []
      }

      expect(isFilterCondition(group)).toBe(false)
    })
  })

  describe('getNestingDepth', () => {
    it('returns 0 for single condition', () => {
      const condition: FilterCondition = ['is', 'country', ['US']]

      expect(getNestingDepth(condition)).toBe(0)
    })

    it('returns 1 for single level group', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition
        ]
      }

      expect(getNestingDepth(group)).toBe(1)
    })

    it('returns 2 for nested group', () => {
      const nested: FilterComposite = {
        filter_type: 'or',
        children: [
          {
            filter_type: 'and',
            children: [['is', 'country', ['US']] as FilterCondition]
          }
        ]
      } as FilterComposite

      expect(getNestingDepth(nested)).toBe(2)
    })
  })

  describe('isValidNestingDepth', () => {
    it('returns true for valid depth', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: []
      }

      expect(isValidNestingDepth(group)).toBe(true)
    })

    it('returns false for exceeded depth', () => {
      const deepNested: FilterComposite = {
        filter_type: 'or',
        children: [
          {
            filter_type: 'and',
            children: [
              {
                filter_type: 'or',
                children: [['is', 'country', ['US']] as FilterCondition]
              }
            ]
          }
        ]
      } as FilterComposite

      expect(isValidNestingDepth(deepNested)).toBe(false)
    })
  })

  describe('getChildCount', () => {
    it('returns 1 for condition', () => {
      const condition: FilterCondition = ['is', 'country', ['US']]

      expect(getChildCount(condition)).toBe(1)
    })

    it('returns children count for group', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition,
          ['is', 'device', ['mobile']] as FilterCondition
        ]
      }

      expect(getChildCount(group)).toBe(2)
    })
  })

  describe('isValidChildCount', () => {
    it('returns true for valid count', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition
        ]
      }

      expect(isValidChildCount(group)).toBe(true)
    })

    it('returns false for exceeded count', () => {
      const children = Array(MAX_CHILDREN_PER_GROUP + 1).fill(['is', 'country', ['US']])
      const group: FilterGroup = {
        filter_type: 'and',
        children: children as FilterCondition[]
      }

      expect(isValidChildCount(group)).toBe(false)
    })
  })

  describe('createEmptyFilterGroup', () => {
    it('creates empty AND group', () => {
      const result = createEmptyFilterGroup()

      expect(result).toEqual({
        filter_type: 'and',
        children: []
      })
    })
  })

  describe('createFilterCondition', () => {
    it('creates condition with defaults', () => {
      const result = createFilterCondition('country')

      expect(result).toEqual(['is', 'country', []])
    })

    it('creates condition with custom values', () => {
      const result = createFilterCondition('country', 'contains_not', ['US', 'UK'])

      expect(result).toEqual(['contains_not', 'country', ['US', 'UK']])
    })
  })

  describe('addConditionToGroup', () => {
    it('adds condition to empty group', () => {
      const group = createEmptyFilterGroup()
      const condition: FilterCondition = ['is', 'country', ['US']]

      const result = addConditionToGroup(group, condition)

      expect(result.children).toHaveLength(1)
      expect(result.children[0]).toEqual(condition)
    })
  })

  describe('removeConditionFromGroup', () => {
    it('removes condition by index', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition,
          ['is', 'device', ['mobile']] as FilterCondition
        ]
      }

      const result = removeConditionFromGroup(group, 0)

      expect(result.children).toHaveLength(1)
      expect(result.children[0]).toEqual(['is', 'device', ['mobile']])
    })
  })

  describe('updateConditionInGroup', () => {
    it('updates condition by index', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: [
          ['is', 'country', ['US']] as FilterCondition
        ]
      }

      const newCondition: FilterCondition = ['is', 'country', ['UK']]
      const result = updateConditionInGroup(group, 0, newCondition)

      expect(result.children[0]).toEqual(newCondition)
    })
  })

  describe('changeGroupFilterType', () => {
    it('changes filter type from AND to OR', () => {
      const group: FilterGroup = {
        filter_type: 'and',
        children: []
      }

      const result = changeGroupFilterType(group, 'or')

      expect(result.filter_type).toBe('or')
    })
  })

  describe('serializeFilter', () => {
    it('serializes filter to JSON string', () => {
      const filter: FilterComposite = {
        filter_type: 'and',
        children: [['is', 'country', ['US']]] as FilterCondition[]
      }

      const result = serializeFilter(filter)

      expect(result).toBe(JSON.stringify(filter))
    })
  })

  describe('deserializeFilter', () => {
    it('deserializes valid JSON', () => {
      const filter: FilterComposite = {
        filter_type: 'and',
        children: [['is', 'country', ['US']]] as FilterCondition[]
      }
      const json = JSON.stringify(filter)

      const result = deserializeFilter(json)

      expect(result).toEqual(filter)
    })

    it('returns null for invalid JSON', () => {
      const result = deserializeFilter('invalid')

      expect(result).toBeNull()
    })
  })

  describe('isValidFilter', () => {
    it('returns true for valid filter group', () => {
      const filter: FilterComposite = {
        filter_type: 'and',
        children: [['is', 'country', ['US']]] as FilterCondition[]
      }

      expect(isValidFilter(filter)).toBe(true)
    })

    it('returns true for valid filter condition', () => {
      const condition: FilterCondition = ['is', 'country', ['US']]

      expect(isValidFilter(condition)).toBe(true)
    })

    it('returns false for invalid filter', () => {
      expect(isValidFilter({ invalid: 'structure' })).toBe(false)
    })
  })

  describe('getAllLeafConditions', () => {
    it('extracts all leaf conditions from nested group', () => {
      const filter: FilterComposite = {
        filter_type: 'or',
        children: [
          {
            filter_type: 'and',
            children: [
              ['is', 'country', ['US']] as FilterCondition,
              ['is', 'device', ['mobile']] as FilterCondition
            ]
          },
          {
            filter_type: 'and',
            children: [
              ['is', 'country', ['UK']] as FilterCondition
            ]
          }
        ]
      } as FilterComposite

      const result = getAllLeafConditions(filter)

      expect(result).toHaveLength(3)
    })
  })
})
