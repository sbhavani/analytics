import {
  evaluateCondition,
  evaluateFilterGroup,
  evaluateFilter,
  filterVisitors,
  VisitorData
} from './filter-evaluation'
import { FilterGroup, FilterCondition } from '../components/filter-builder/types'

describe('evaluateCondition', () => {
  describe('AND logic - single conditions', () => {
    it('should return true when "is" operator matches', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'country',
        operator: 'is',
        value: 'US'
      }
      const visitor: VisitorData = { country: 'US' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false when "is" operator does not match', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'country',
        operator: 'is',
        value: 'US'
      }
      const visitor: VisitorData = { country: 'CA' }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true when "is_not" operator does not match', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'country',
        operator: 'is_not',
        value: 'US'
      }
      const visitor: VisitorData = { country: 'CA' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false when "is_not" operator matches', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'country',
        operator: 'is_not',
        value: 'US'
      }
      const visitor: VisitorData = { country: 'US' }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true when "contains" operator matches', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'page',
        operator: 'contains',
        value: '/blog'
      }
      const visitor: VisitorData = { page: '/blog/post-1' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should be case insensitive for contains', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'page',
        operator: 'contains',
        value: 'BLOG'
      }
      const visitor: VisitorData = { page: '/Blog/post-1' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false when "contains" operator does not match', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'page',
        operator: 'contains',
        value: '/docs'
      }
      const visitor: VisitorData = { page: '/blog/post-1' }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true when "contains_not" operator does not find value', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'page',
        operator: 'contains_not',
        value: '/admin'
      }
      const visitor: VisitorData = { page: '/blog/post-1' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false when "contains_not" operator finds value', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'page',
        operator: 'contains_not',
        value: '/blog'
      }
      const visitor: VisitorData = { page: '/blog/post-1' }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true for "greater_than" when value is greater', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'visit_duration',
        operator: 'greater_than',
        value: 60
      }
      const visitor: VisitorData = { visit_duration: 120 }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false for "greater_than" when value is not greater', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'visit_duration',
        operator: 'greater_than',
        value: 60
      }
      const visitor: VisitorData = { visit_duration: 30 }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true for "less_than" when value is less', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'visit_duration',
        operator: 'less_than',
        value: 60
      }
      const visitor: VisitorData = { visit_duration: 30 }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false for "less_than" when value is not less', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'visit_duration',
        operator: 'less_than',
        value: 60
      }
      const visitor: VisitorData = { visit_duration: 120 }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true for "is_set" when field has value', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'email',
        operator: 'is_set',
        value: ''
      }
      const visitor: VisitorData = { email: 'test@example.com' }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false for "is_set" when field is null', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'email',
        operator: 'is_set',
        value: ''
      }
      const visitor: VisitorData = { email: null }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })

    it('should return true for "is_not_set" when field is null', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'email',
        operator: 'is_not_set',
        value: ''
      }
      const visitor: VisitorData = { email: null }
      expect(evaluateCondition(condition, visitor)).toBe(true)
    })

    it('should return false for "is_not_set" when field has value', () => {
      const condition: FilterCondition = {
        id: 'cond-1',
        field: 'email',
        operator: 'is_not_set',
        value: ''
      }
      const visitor: VisitorData = { email: 'test@example.com' }
      expect(evaluateCondition(condition, visitor)).toBe(false)
    })
  })
})

describe('evaluateFilterGroup', () => {
  describe('AND logic', () => {
    it('should return true when all conditions match with AND operator', () => {
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
            operator: 'is',
            value: 'Chrome'
          }
        ]
      }
      const visitor: VisitorData = { country: 'US', browser: 'Chrome' }
      expect(evaluateFilterGroup(group, visitor)).toBe(true)
    })

    it('should return false when one condition fails with AND operator', () => {
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
            operator: 'is',
            value: 'Chrome'
          }
        ]
      }
      const visitor: VisitorData = { country: 'US', browser: 'Firefox' }
      expect(evaluateFilterGroup(group, visitor)).toBe(false)
    })

    it('should return false when multiple conditions fail with AND operator', () => {
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
            operator: 'is',
            value: 'Chrome'
          },
          {
            id: 'cond-3',
            field: 'os',
            operator: 'is',
            value: 'Windows'
          }
        ]
      }
      const visitor: VisitorData = { country: 'CA', browser: 'Firefox', os: 'Mac' }
      expect(evaluateFilterGroup(group, visitor)).toBe(false)
    })

    it('should return true when single condition matches with AND operator', () => {
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
      const visitor: VisitorData = { country: 'US' }
      expect(evaluateFilterGroup(group, visitor)).toBe(true)
    })

    it('should return true for empty group with AND operator', () => {
      const group: FilterGroup = {
        id: 'group-1',
        type: 'group',
        operator: 'AND',
        children: []
      }
      const visitor: VisitorData = { country: 'US' }
      expect(evaluateFilterGroup(group, visitor)).toBe(true)
    })

    it('should handle mixed operators in nested groups with AND at top level', () => {
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
      // Should match: country is US AND (browser is Chrome OR browser is Firefox)
      const visitor1: VisitorData = { country: 'US', browser: 'Chrome' }
      expect(evaluateFilterGroup(group, visitor1)).toBe(true)

      const visitor2: VisitorData = { country: 'US', browser: 'Firefox' }
      expect(evaluateFilterGroup(group, visitor2)).toBe(true)

      const visitor3: VisitorData = { country: 'US', browser: 'Safari' }
      expect(evaluateFilterGroup(group, visitor3)).toBe(false)

      const visitor4: VisitorData = { country: 'CA', browser: 'Chrome' }
      expect(evaluateFilterGroup(group, visitor4)).toBe(false)
    })

    it('should handle multiple levels of nested groups with AND logic', () => {
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
            operator: 'AND',
            children: [
              {
                id: 'cond-2',
                field: 'browser',
                operator: 'is',
                value: 'Chrome'
              },
              {
                id: 'cond-3',
                field: 'os',
                operator: 'is',
                value: 'Windows'
              }
            ]
          }
        ]
      }
      // Should match: country is US AND (browser is Chrome AND os is Windows)
      const visitor1: VisitorData = { country: 'US', browser: 'Chrome', os: 'Windows' }
      expect(evaluateFilterGroup(group, visitor1)).toBe(true)

      const visitor2: VisitorData = { country: 'US', browser: 'Chrome', os: 'Mac' }
      expect(evaluateFilterGroup(group, visitor2)).toBe(false)

      const visitor3: VisitorData = { country: 'CA', browser: 'Chrome', os: 'Windows' }
      expect(evaluateFilterGroup(group, visitor3)).toBe(false)
    })

    it('should handle contains operator in AND logic', () => {
      const group: FilterGroup = {
        id: 'group-1',
        type: 'group',
        operator: 'AND',
        children: [
          {
            id: 'cond-1',
            field: 'page',
            operator: 'contains',
            value: '/blog'
          },
          {
            id: 'cond-2',
            field: 'source',
            operator: 'is',
            value: 'google'
          }
        ]
      }
      const visitor1: VisitorData = { page: '/blog/post-1', source: 'google' }
      expect(evaluateFilterGroup(group, visitor1)).toBe(true)

      const visitor2: VisitorData = { page: '/blog/post-1', source: 'twitter' }
      expect(evaluateFilterGroup(group, visitor2)).toBe(false)
    })

    it('should handle numeric comparisons in AND logic', () => {
      const group: FilterGroup = {
        id: 'group-1',
        type: 'group',
        operator: 'AND',
        children: [
          {
            id: 'cond-1',
            field: 'visit_duration',
            operator: 'greater_than',
            value: 60
          },
          {
            id: 'cond-2',
            field: 'pageviews',
            operator: 'greater_than',
            value: 5
          }
        ]
      }
      const visitor1: VisitorData = { visit_duration: 120, pageviews: 10 }
      expect(evaluateFilterGroup(group, visitor1)).toBe(true)

      const visitor2: VisitorData = { visit_duration: 30, pageviews: 10 }
      expect(evaluateFilterGroup(group, visitor2)).toBe(false)

      const visitor3: VisitorData = { visit_duration: 120, pageviews: 3 }
      expect(evaluateFilterGroup(group, visitor3)).toBe(false)
    })

    it('should handle is_set and is_not_set in AND logic', () => {
      const group: FilterGroup = {
        id: 'group-1',
        type: 'group',
        operator: 'AND',
        children: [
          {
            id: 'cond-1',
            field: 'email',
            operator: 'is_set',
            value: ''
          },
          {
            id: 'cond-2',
            field: 'phone',
            operator: 'is_not_set',
            value: ''
          }
        ]
      }
      const visitor1: VisitorData = { email: 'test@example.com', phone: null }
      expect(evaluateFilterGroup(group, visitor1)).toBe(true)

      const visitor2: VisitorData = { email: null, phone: null }
      expect(evaluateFilterGroup(group, visitor2)).toBe(false)

      const visitor3: VisitorData = { email: 'test@example.com', phone: '123-456' }
      expect(evaluateFilterGroup(group, visitor3)).toBe(false)
    })
  })
})

describe('evaluateFilter', () => {
  describe('AND logic integration', () => {
    it('should evaluate complete filter with AND operator', () => {
      const rootGroup: FilterGroup = {
        id: 'root',
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
      const visitor: VisitorData = { country: 'US', browser: 'Chrome/120' }
      expect(evaluateFilter(rootGroup, visitor)).toBe(true)
    })
  })
})

describe('filterVisitors', () => {
  describe('AND logic', () => {
    it('should filter visitors based on AND conditions', () => {
      const rootGroup: FilterGroup = {
        id: 'root',
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
            operator: 'is',
            value: 'Chrome'
          }
        ]
      }

      const visitors: VisitorData[] = [
        { country: 'US', browser: 'Chrome' },
        { country: 'US', browser: 'Firefox' },
        { country: 'CA', browser: 'Chrome' },
        { country: 'CA', browser: 'Firefox' }
      ]

      const filtered = filterVisitors(visitors, rootGroup)
      expect(filtered).toHaveLength(1)
      expect(filtered[0]).toEqual({ country: 'US', browser: 'Chrome' })
    })

    it('should return empty array when no visitors match AND conditions', () => {
      const rootGroup: FilterGroup = {
        id: 'root',
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
            operator: 'is',
            value: 'Chrome'
          }
        ]
      }

      const visitors: VisitorData[] = [
        { country: 'US', browser: 'Firefox' },
        { country: 'CA', browser: 'Chrome' }
      ]

      const filtered = filterVisitors(visitors, rootGroup)
      expect(filtered).toHaveLength(0)
    })

    it('should return all visitors when filter has no conditions', () => {
      const rootGroup: FilterGroup = {
        id: 'root',
        type: 'group',
        operator: 'AND',
        children: []
      }

      const visitors: VisitorData[] = [
        { country: 'US', browser: 'Chrome' },
        { country: 'CA', browser: 'Firefox' }
      ]

      const filtered = filterVisitors(visitors, rootGroup)
      expect(filtered).toHaveLength(2)
    })
  })
})
