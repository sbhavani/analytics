import React from 'react'
import { renderHook, act } from '@testing-library/react'
import { FilterBuilderProvider, useFilterBuilder } from './FilterBuilderContext'
import { createCondition, createGroup } from './filterTreeUtils'

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <FilterBuilderProvider>{children}</FilterBuilderProvider>
)

describe('FilterBuilderContext', () => {
  describe('initial state', () => {
    it('provides initial empty state', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      expect(result.current.state.filterTree.rootGroup.id).toBe('root')
      expect(result.current.state.filterTree.rootGroup.conditions).toEqual([])
      expect(result.current.state.isDirty).toBe(false)
      expect(result.current.state.isValid).toBe(false)
    })
  })

  describe('addCondition', () => {
    it('adds a condition to the root group', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US'
        })
      })

      expect(result.current.state.filterTree.rootGroup.conditions).toHaveLength(1)
      expect(result.current.state.filterTree.rootGroup.conditions[0].attribute).toBe('country')
    })

    it('marks state as dirty', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id)
      })

      expect(result.current.state.isDirty).toBe(true)
    })
  })

  describe('updateCondition', () => {
    it('updates an existing condition', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US'
        })
      })

      const conditionId = result.current.state.filterTree.rootGroup.conditions[0].id

      act(() => {
        result.current.updateCondition(conditionId, { value: 'DE' })
      })

      expect(result.current.state.filterTree.rootGroup.conditions[0].value).toBe('DE')
    })
  })

  describe('deleteCondition', () => {
    it('removes a condition', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US'
        })
      })

      const conditionId = result.current.state.filterTree.rootGroup.conditions[0].id

      act(() => {
        result.current.deleteCondition(conditionId)
      })

      expect(result.current.state.filterTree.rootGroup.conditions).toHaveLength(0)
    })
  })

  describe('addNestedGroup', () => {
    it('adds a nested group', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addNestedGroup(result.current.state.filterTree.rootGroup.id)
      })

      expect(result.current.state.filterTree.rootGroup.nestedGroups).toHaveLength(1)
    })
  })

  describe('updateConnector', () => {
    it('changes connector from AND to OR', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.updateConnector(result.current.state.filterTree.rootGroup.id, 'OR')
      })

      expect(result.current.state.filterTree.rootGroup.connector).toBe('OR')
    })
  })

  describe('clearAll', () => {
    it('resets the filter tree', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US'
        })
      })

      act(() => {
        result.current.clearAll()
      })

      expect(result.current.state.filterTree.rootGroup.conditions).toHaveLength(0)
      expect(result.current.state.isDirty).toBe(false)
    })
  })

  describe('computed values', () => {
    it('isValid is true when condition is complete', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US',
          operator: 'equals'
        })
      })

      expect(result.current.isValid).toBe(true)
    })

    it('isValid is false when condition is incomplete', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: '',
          value: ''
        })
      })

      expect(result.current.isValid).toBe(false)
    })

    it('generates filter summary', () => {
      const { result } = renderHook(() => useFilterBuilder(), { wrapper })

      act(() => {
        result.current.addCondition(result.current.state.filterTree.rootGroup.id, {
          attribute: 'country',
          value: 'US',
          operator: 'equals'
        })
      })

      expect(result.current.filterSummary).toBe('country = US')
    })
  })

  describe('error handling', () => {
    it('throws error when used outside provider', () => {
      const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {})

      expect(() => {
        renderHook(() => useFilterBuilder())
      }).toThrow('useFilterBuilder must be used within a FilterBuilderProvider')

      consoleError.mockRestore()
    })
  })
})
