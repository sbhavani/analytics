import { useFilterBuilder } from '../../dashboard/hooks/useFilterBuilder'
import {
  createEmptyFilterTree,
  createEmptyCondition,
  createEmptyGroup,
  FilterTree,
  FilterCondition,
  ConditionGroup
} from '../../dashboard/lib/filter-parser'
import { renderHook, act } from '@testing-library/react'

describe('useFilterBuilder', () => {
  describe('initialization', () => {
    it('creates empty filter tree by default', () => {
      const { result } = renderHook(() => useFilterBuilder())

      // Just verify structure - IDs are random so can't compare equality
      expect(result.current.filterTree.rootGroup.conditions).toEqual([])
      expect(result.current.filterTree.rootGroup.children).toEqual([])
      expect(result.current.filterTree.rootGroup.connector).toBe('and')
      expect(result.current.filterTree.rootGroup.isRoot).toBe(true)
      expect(result.current.filterTree.labels).toEqual({})
      expect(result.current.isValid).toBe(true)
      expect(result.current.validationErrors).toEqual([])
      expect(result.current.isDirty).toBe(false)
    })

    it('uses provided initial tree', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.conditions[0].dimension).toBe('visit:country')
    })

    it('respects maxConditions option', () => {
      const { result } = renderHook(() => useFilterBuilder({ maxConditions: 2 }))

      // Add first condition
      act(() => {
        result.current.addCondition()
      })
      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)

      // Add second condition
      act(() => {
        result.current.addCondition()
      })
      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(2)

      // Try to add third - should be blocked
      act(() => {
        result.current.addCondition()
      })
      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(2)
    })

    it('respects maxDepth option for groups', () => {
      const { result } = renderHook(() => useFilterBuilder({ maxDepth: 2 }))

      // Add first group
      act(() => {
        result.current.addGroup()
      })
      expect(result.current.filterTree.rootGroup.children).toHaveLength(1)

      // Try to add nested group within the first group - should be blocked
      act(() => {
        result.current.addGroup(result.current.filterTree.rootGroup.children[0].id)
      })
      expect(result.current.filterTree.rootGroup.children[0].children).toHaveLength(0)
    })
  })

  describe('addCondition', () => {
    it('adds a new empty condition to root group', () => {
      const { result } = renderHook(() => useFilterBuilder())

      act(() => {
        result.current.addCondition()
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.conditions[0]).toEqual(
        expect.objectContaining({
          dimension: '',
          operator: 'is',
          value: []
        })
      )
    })

    it('adds condition to specific group', () => {
      const { result } = renderHook(() => useFilterBuilder())

      // Add a group first
      act(() => {
        result.current.addGroup()
      })

      const groupId = result.current.filterTree.rootGroup.children[0].id

      act(() => {
        result.current.addCondition(groupId)
      })

      expect(result.current.filterTree.rootGroup.children[0].conditions).toHaveLength(1)
    })

    it('triggers onChange callback', () => {
      const onChange = jest.fn()
      const { result } = renderHook(() => useFilterBuilder({ onChange }))

      act(() => {
        result.current.addCondition()
      })

      expect(onChange).toHaveBeenCalled()
    })

    it('sets isDirty to true after adding condition', () => {
      const { result } = renderHook(() => useFilterBuilder())

      expect(result.current.isDirty).toBe(false)

      act(() => {
        result.current.addCondition()
      })

      expect(result.current.isDirty).toBe(true)
    })
  })

  describe('removeCondition', () => {
    it('removes condition from root group', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] },
            { id: 'cond-2', dimension: 'visit:device', operator: 'is', value: ['Desktop'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.removeCondition('cond-1')
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.conditions[0].id).toBe('cond-2')
    })

    it('adds empty condition when last condition is removed', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.removeCondition('cond-1')
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.conditions[0].dimension).toBe('')
    })

    it('removes condition from nested group and group is removed when empty', () => {
      // Test removing a condition from a nested group at depth 1 - should remove the empty group
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-root', dimension: 'visit:country', operator: 'is', value: ['US'] }
          ],
          children: [
            {
              id: 'group-1',
              connector: 'and',
              conditions: [
                { id: 'cond-nested', dimension: 'visit:device', operator: 'is', value: ['Mobile'] }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.removeCondition('cond-nested', 'group-1')
      })

      // When removing last condition and no children, the group gets removed
      expect(result.current.filterTree.rootGroup.children).toHaveLength(0)
      // Root conditions remain intact
      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
    })

    it('removes nested group when last condition is removed and no children', () => {
      const groupId = 'nested-group'
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: groupId,
              connector: 'and',
              conditions: [
                { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.removeCondition('cond-1', groupId)
      })

      // When group has no children, it gets removed entirely
      expect(result.current.filterTree.rootGroup.children).toHaveLength(0)
    })
  })

  describe('updateCondition', () => {
    it('updates condition in root group', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: '', operator: 'is', value: [] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.updateCondition('cond-1', {
          dimension: 'visit:country',
          operator: 'is_not',
          value: ['US']
        })
      })

      expect(result.current.filterTree.rootGroup.conditions[0]).toEqual(
        expect.objectContaining({
          id: 'cond-1',
          dimension: 'visit:country',
          operator: 'is_not',
          value: ['US']
        })
      )
    })

    it('updates condition in nested group', () => {
      const groupId = 'nested-group'
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: groupId,
              connector: 'and',
              conditions: [
                { id: 'cond-1', dimension: '', operator: 'is', value: [] }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.updateCondition('cond-1', {
          dimension: 'visit:device',
          operator: 'is',
          value: ['Mobile']
        }, groupId)
      })

      expect(result.current.filterTree.rootGroup.children[0].conditions[0]).toEqual(
        expect.objectContaining({
          dimension: 'visit:device',
          operator: 'is',
          value: ['Mobile']
        })
      )
    })
  })

  describe('addGroup', () => {
    it('adds a new group to root', () => {
      const { result } = renderHook(() => useFilterBuilder())

      act(() => {
        result.current.addGroup()
      })

      expect(result.current.filterTree.rootGroup.children).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.children[0].connector).toBe('and')
    })

    it('adds nested group within another group', () => {
      const { result } = renderHook(() => useFilterBuilder({ maxDepth: 3 }))

      // Add first group
      act(() => {
        result.current.addGroup()
      })

      const groupId = result.current.filterTree.rootGroup.children[0].id

      // Add nested group
      act(() => {
        result.current.addGroup(groupId)
      })

      expect(result.current.filterTree.rootGroup.children[0].children).toHaveLength(1)
    })

    it('does not exceed max depth', () => {
      const { result } = renderHook(() => useFilterBuilder({ maxDepth: 2 }))

      // Add first group
      act(() => {
        result.current.addGroup()
      })

      const groupId = result.current.filterTree.rootGroup.children[0].id

      // Try to add nested group - should be blocked
      act(() => {
        result.current.addGroup(groupId)
      })

      expect(result.current.filterTree.rootGroup.children[0].children).toHaveLength(0)
    })
  })

  describe('removeGroup', () => {
    it('removes nested group', () => {
      const groupId = 'nested-group'
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: groupId,
              connector: 'and',
              conditions: [
                { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.removeGroup(groupId)
      })

      expect(result.current.filterTree.rootGroup.children).toHaveLength(0)
    })

    it('cannot remove root group', () => {
      const { result } = renderHook(() => useFilterBuilder())

      const rootId = result.current.filterTree.rootGroup.id
      const originalId = rootId

      act(() => {
        result.current.removeGroup(rootId)
      })

      // Root group should remain unchanged
      expect(result.current.filterTree.rootGroup.id).toBe(originalId)
      expect(result.current.filterTree.rootGroup.isRoot).toBe(true)
    })
  })

  describe('toggleConnector', () => {
    it('toggles root group connector', () => {
      const { result } = renderHook(() => useFilterBuilder())

      expect(result.current.filterTree.rootGroup.connector).toBe('and')

      // Get the actual root group ID
      const rootId = result.current.filterTree.rootGroup.id

      act(() => {
        result.current.toggleConnector(rootId)
      })

      expect(result.current.filterTree.rootGroup.connector).toBe('or')

      act(() => {
        result.current.toggleConnector(rootId)
      })

      expect(result.current.filterTree.rootGroup.connector).toBe('and')
    })

    it('toggles nested group connector', () => {
      const groupId = 'nested-group'
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: groupId,
              connector: 'and',
              conditions: [],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.toggleConnector(groupId)
      })

      expect(result.current.filterTree.rootGroup.children[0].connector).toBe('or')
    })
  })

  describe('groupConditions', () => {
    it('groups multiple conditions into a nested group', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] },
            { id: 'cond-2', dimension: 'visit:device', operator: 'is', value: ['Desktop'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.groupConditions(['cond-1', 'cond-2'])
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(0)
      expect(result.current.filterTree.rootGroup.children).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.children[0].conditions).toHaveLength(2)
    })

    it('does not group less than 2 conditions', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.groupConditions(['cond-1'])
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.filterTree.rootGroup.children).toHaveLength(0)
    })
  })

  describe('ungroupGroup', () => {
    it('moves conditions from nested group to parent', () => {
      const groupId = 'nested-group'
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [
            {
              id: groupId,
              connector: 'and',
              conditions: [
                { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] },
                { id: 'cond-2', dimension: 'visit:device', operator: 'is', value: ['Desktop'] }
              ],
              children: [],
              isRoot: false
            }
          ],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      act(() => {
        result.current.ungroupGroup(groupId)
      })

      expect(result.current.filterTree.rootGroup.children).toHaveLength(0)
      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(2)
    })

    it('cannot ungroup root', () => {
      const { result } = renderHook(() => useFilterBuilder())

      act(() => {
        result.current.ungroupGroup('root')
      })

      expect(result.current.filterTree.rootGroup.isRoot).toBe(true)
    })
  })

  describe('reset', () => {
    it('resets to initial tree', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      // Add more conditions
      act(() => {
        result.current.addCondition()
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(2)

      // Reset
      act(() => {
        result.current.reset()
      })

      expect(result.current.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.isDirty).toBe(false)
    })
  })

  describe('setFilterTree', () => {
    it('directly sets the filter tree', () => {
      const { result } = renderHook(() => useFilterBuilder())

      const newTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'or',
          conditions: [
            { id: 'cond-1', dimension: 'visit:browser', operator: 'is', value: ['Chrome'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      act(() => {
        result.current.setFilterTree(newTree)
      })

      expect(result.current.filterTree.rootGroup.connector).toBe('or')
      expect(result.current.filterTree.rootGroup.conditions[0].dimension).toBe('visit:browser')
    })
  })

  describe('validation', () => {
    it('validates missing dimension', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: '', operator: 'is', value: ['US'] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.isValid).toBe(false)
      expect(result.current.validationErrors).toContain('Condition missing dimension')
    })

    it('validates missing value', () => {
      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [
            { id: 'cond-1', dimension: 'visit:country', operator: 'is', value: [] }
          ],
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.isValid).toBe(false)
      expect(result.current.validationErrors).toContain('Condition missing value')
    })

    it('validates max conditions (20)', () => {
      const conditions = Array.from({ length: 20 }, (_, i) => ({
        id: `cond-${i}`,
        dimension: 'visit:country',
        operator: 'is' as const,
        value: ['US'] as (string | number)[]
      }))

      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions,
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.isValid).toBe(true)
      expect(result.current.validationErrors).toHaveLength(0)
    })

    it('reports error when exceeding 20 conditions', () => {
      const conditions = Array.from({ length: 21 }, (_, i) => ({
        id: `cond-${i}`,
        dimension: 'visit:country',
        operator: 'is' as const,
        value: ['US'] as (string | number)[]
      }))

      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions,
          children: [],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.isValid).toBe(false)
      expect(result.current.validationErrors).toContain('Maximum 20 conditions allowed')
    })

    it('validates max nesting depth (3)', () => {
      // Build a 4-level deep tree
      const level4: ConditionGroup = {
        id: 'level-4',
        connector: 'and',
        conditions: [{ id: 'cond-1', dimension: 'visit:country', operator: 'is', value: ['US'] }],
        children: [],
        isRoot: false
      }
      const level3: ConditionGroup = {
        id: 'level-3',
        connector: 'and',
        conditions: [],
        children: [level4],
        isRoot: false
      }
      const level2: ConditionGroup = {
        id: 'level-2',
        connector: 'and',
        conditions: [],
        children: [level3],
        isRoot: false
      }

      const initialTree: FilterTree = {
        rootGroup: {
          id: 'root',
          connector: 'and',
          conditions: [],
          children: [level2],
          isRoot: true
        },
        labels: {}
      }

      const { result } = renderHook(() => useFilterBuilder({ initialTree }))

      expect(result.current.isValid).toBe(false)
      expect(result.current.validationErrors).toContain('Maximum 3 levels of nesting allowed')
    })
  })
})
