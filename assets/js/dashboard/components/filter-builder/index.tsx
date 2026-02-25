import React, { useState, useCallback } from 'react'
import { PlusIcon, TrashIcon, ArrowDownTrayIcon } from '@heroicons/react/20/solid'
import {
  AdvancedFilter,
  FilterItem,
  FilterCondition,
  ConditionGroup,
  createFilterCondition,
  createConditionGroup,
  validateAdvancedFilter,
  MAX_FILTER_DEPTH
} from '../../filtering/segments'
import { ConditionGroupComponent } from './condition-group'
import { useSegmentsContext } from '../../filtering/segments-context'
import { useSiteContext } from '../../site-context'
import { useDashboardStateContext } from '../../dashboard-state-context'

interface FilterBuilderProps {
  onClose?: () => void
}

export function FilterBuilder({ onClose }: FilterBuilderProps) {
  const { segments } = useSegmentsContext()
  const site = useSiteContext()
  const { setFilters, setLabels } = useDashboardStateContext()

  const [filter, setFilter] = useState<AdvancedFilter>({
    items: [createConditionGroup(1)]
  })

  const [segmentName, setSegmentName] = useState('')
  const [showLoadSegment, setShowLoadSegment] = useState(false)
  const [unsavedChanges, setUnsavedChanges] = useState(false)
  const [validationErrors, setValidationErrors] = useState<string[]>([])

  const validation = validateAdvancedFilter(filter)

  const updateFilter = useCallback((newItems: FilterItem[]) => {
    setFilter({ items: newItems })
    setUnsavedChanges(true)
    const errors = validateAdvancedFilter({ items: newItems }).errors
    setValidationErrors(errors)
  }, [])

  const addCondition = useCallback((groupId: string) => {
    const newCondition = createFilterCondition()
    setFilter(prev => {
      const newItems = prev.items.map(item => {
        if ('id' in item && item.id === groupId && 'children' in item) {
          return {
            ...item,
            children: [...item.children, newCondition]
          }
        }
        return item
      })
      return { items: newItems }
    })
    setUnsavedChanges(true)
  }, [])

  const updateCondition = useCallback((groupId: string, conditionId: string, updates: Partial<FilterCondition>) => {
    setFilter(prev => {
      const newItems = prev.items.map(item => {
        if ('id' in item && item.id === groupId && 'children' in item) {
          return {
            ...item,
            children: item.children.map(child => {
              if ('id' in child && child.id === conditionId) {
                return { ...child, ...updates } as FilterCondition
              }
              return child
            })
          }
        }
        return item
      })
      return { items: newItems }
    })
    setUnsavedChanges(true)
  }, [])

  const removeCondition = useCallback((groupId: string, conditionId: string) => {
    setFilter(prev => {
      const newItems = prev.items.map(item => {
        if ('id' in item && item.id === groupId && 'children' in item) {
          return {
            ...item,
            children: item.children.filter(child => !('id' in child) || child.id !== conditionId)
          }
        }
        return item
      }).filter(item => {
        if ('children' in item) {
          return item.children.length > 0
        }
        return true
      })

      // If all items are removed, add a new empty group
      if (newItems.length === 0) {
        return { items: [createConditionGroup(1)] }
      }

      return { items: newItems }
    })
    setUnsavedChanges(true)
  }, [])

  const updateGroupLogic = useCallback((groupId: string, logic: 'AND' | 'OR') => {
    setFilter(prev => {
      const newItems = prev.items.map(item => {
        if ('id' in item && item.id === groupId && 'logic' in item) {
          return { ...item, logic }
        }
        return item
      })
      return { items: newItems }
    })
    setUnsavedChanges(true)
  }, [])

  const addGroup = useCallback(() => {
    // Check if we can add more groups (max depth)
    const currentDepth = filter.items.reduce((max, item) => {
      if ('depth' in item) return Math.max(max, item.depth)
      return max
    }, 1)

    if (currentDepth >= MAX_FILTER_DEPTH) {
      setValidationErrors([`Maximum nesting depth of ${MAX_FILTER_DEPTH} reached`])
      return
    }

    const newGroup = createConditionGroup(currentDepth + 1)
    setFilter(prev => ({
      items: [...prev.items, newGroup]
    }))
    setUnsavedChanges(true)
  }, [filter.items])

  const loadSegment = useCallback((segment: typeof segments[0]) => {
    // TODO: Convert saved segment to advanced filter format
    setShowLoadSegment(false)
    setUnsavedChanges(false)
  }, [])

  const saveSegment = useCallback(async () => {
    if (!segmentName.trim()) {
      setValidationErrors(['Segment name is required'])
      return
    }

    if (!validation.valid) {
      setValidationErrors(validation.errors)
      return
    }

    // TODO: Implement API call to save segment
    console.log('Saving segment:', { name: segmentName, filter })

    setUnsavedChanges(false)
    setSegmentName('')
  }, [segmentName, validation])

  const applyFilter = useCallback(() => {
    if (!validation.valid) {
      setValidationErrors(validation.errors)
      return
    }

    // TODO: Convert to legacy filter format and apply
    // const legacyFilters = advancedFilterToLegacyFilters(filter)
    // setFilters(legacyFilters)

    console.log('Applying filter:', filter)
    onClose?.()
  }, [validation.valid, validation.errors, filter, onClose])

  return (
    <div className="filter-builder">
      <div className="filter-builder__header">
        <h3 className="text-lg font-medium">Filter Builder</h3>
        <button
          onClick={() => setShowLoadSegment(!showLoadSegment)}
          className="text-sm text-gray-500 hover:text-gray-700 flex items-center gap-1"
        >
          <ArrowDownTrayIcon className="w-4 h-4" />
          Load Segment
        </button>
      </div>

      {showLoadSegment && (
        <div className="filter-builder__load-segment mb-4 p-3 bg-gray-50 rounded">
          <h4 className="text-sm font-medium mb-2">Load Saved Segment</h4>
          {segments.length === 0 ? (
            <p className="text-sm text-gray-500">No saved segments</p>
          ) : (
            <ul className="space-y-1">
              {segments.map(segment => (
                <li key={segment.id}>
                  <button
                    onClick={() => loadSegment(segment)}
                    className="text-sm text-blue-600 hover:text-blue-800"
                  >
                    {segment.name}
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      <div className="filter-builder__conditions space-y-3">
        {filter.items.map((item, index) => (
          <React.Fragment key={item.id}>
            {index > 0 && (
              <div className="flex items-center justify-center">
                <span className="text-xs font-medium text-gray-500 uppercase bg-white px-2">
                  AND
                </span>
              </div>
            )}
            {'children' in item && (
              <ConditionGroupComponent
                group={item}
                onAddCondition={() => addCondition(item.id)}
                onUpdateCondition={(conditionId, updates) => updateCondition(item.id, conditionId, updates)}
                onRemoveCondition={(conditionId) => removeCondition(item.id, conditionId)}
                onUpdateLogic={(logic) => updateGroupLogic(item.id, logic)}
              />
            )}
          </React.Fragment>
        ))}
      </div>

      <div className="filter-builder__actions mt-4 flex gap-2">
        <button
          onClick={addGroup}
          className="flex items-center gap-1 px-3 py-2 text-sm text-gray-700 bg-white border border-gray-300 rounded hover:bg-gray-50"
        >
          <PlusIcon className="w-4 h-4" />
          Add Group
        </button>
      </div>

      {validationErrors.length > 0 && (
        <div className="filter-builder__errors mt-4 p-3 bg-red-50 border border-red-200 rounded">
          <ul className="text-sm text-red-600 space-y-1">
            {validationErrors.map((error, i) => (
              <li key={i}>{error}</li>
            ))}
          </ul>
        </div>
      )}

      <div className="filter-builder__save mt-4 pt-4 border-t">
        <input
          type="text"
          value={segmentName}
          onChange={(e) => setSegmentName(e.target.value)}
          placeholder="Segment name"
          className="w-full px-3 py-2 border border-gray-300 rounded mb-2"
        />
        <div className="flex gap-2">
          <button
            onClick={saveSegment}
            disabled={!validation.valid}
            className="flex-1 px-4 py-2 text-sm text-white bg-blue-600 rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Save Segment
          </button>
          <button
            onClick={applyFilter}
            disabled={!validation.valid}
            className="flex-1 px-4 py-2 text-sm text-gray-700 bg-gray-100 border border-gray-300 rounded hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Apply
          </button>
        </div>
      </div>

      {unsavedChanges && (
        <div className="mt-2 text-xs text-amber-600">
          You have unsaved changes
        </div>
      )}
    </div>
  )
}
