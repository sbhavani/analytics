import React, { useState, useEffect, useCallback } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  FilterExpression,
  FilterGroup,
  FilterCondition,
  createEmptyFilterExpression,
  createFilterCondition,
  createFilterGroup,
  filterExpressionToLegacyFilters,
  legacyFiltersToFilterExpression
} from '../../types/filter-expression'
import { validateFilterExpression, serializeFilterExpression } from '../../util/filter-expression'
import ConditionRow from './condition-row'
import FilterGroupComponent from './filter-group'
import SegmentList from './segment-list'
import SaveSegmentDialog from './save-segment-dialog'
import PreviewCount from './preview-count'
import { SavedSegment, SegmentData } from '../../filtering/segments'

interface FilterBuilderProps {
  siteId: number
  initialExpression?: FilterExpression
  onApply?: (expression: FilterExpression, legacyFilters: any[]) => void
  onSaveSegment?: (name: string, type: 'personal' | 'site', expression: FilterExpression) => Promise<void>
  savedSegments?: SavedSegment[]
  isLoadingSegments?: boolean
}

export function FilterBuilder({
  siteId,
  initialExpression,
  onApply,
  onSaveSegment,
  savedSegments = [],
  isLoadingSegments = false
}: FilterBuilderProps) {
  const [expression, setExpression] = useState<FilterExpression>(
    initialExpression || createEmptyFilterExpression()
  )
  const [isSaveDialogOpen, setIsSaveDialogOpen] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [selectedSegmentId, setSelectedSegmentId] = useState<number | undefined>()

  const validation = validateFilterExpression(expression)

  // Handle adding a new condition
  const handleAddCondition = useCallback(() => {
    const newCondition = createFilterCondition()
    setExpression(prev => ({
      ...prev,
      root: {
        ...prev.root,
        children: [...prev.root.children, newCondition]
      }
    }))
  }, [])

  // Handle updating a condition
  const handleUpdateCondition = useCallback((conditionId: string, updates: Partial<FilterCondition>) => {
    setExpression(prev => {
      const updateInGroup = (group: FilterGroup): FilterGroup => ({
        ...group,
        children: group.children.map(child => {
          if ('dimension' in child && child.id === conditionId) {
            return { ...child, ...updates }
          }
          return child
        })
      })
      return { ...prev, root: updateInGroup(prev.root) }
    })
  }, [])

  // Handle deleting a condition
  const handleDeleteCondition = useCallback((conditionId: string) => {
    setExpression(prev => {
      const deleteFromGroup = (group: FilterGroup): FilterGroup => ({
        ...group,
        children: group.children.filter(child => {
          if ('dimension' in child) {
            return child.id !== conditionId
          }
          return child.id !== conditionId
        })
      })
      return { ...prev, root: deleteFromGroup(prev.root) }
    })
  }, [])

  // Handle adding a new group
  const handleAddGroup = useCallback(() => {
    const newGroup = createFilterGroup('AND')
    newGroup.children.push(createFilterCondition())
    setExpression(prev => ({
      ...prev,
      root: {
        ...prev.root,
        children: [...prev.root.children, newGroup]
      }
    }))
  }, [])

  // Handle apply
  const handleApply = useCallback(() => {
    if (validation.valid && onApply) {
      const legacyFilters = filterExpressionToLegacyFilters(expression)
      onApply(expression, legacyFilters)
    }
  }, [expression, validation.valid, onApply])

  // Handle save segment
  const handleSaveSegment = useCallback(async (name: string, type: 'personal' | 'site') => {
    if (onSaveSegment && validation.valid) {
      setIsSaving(true)
      try {
        await onSaveSegment(name, type, expression)
        setIsSaveDialogOpen(false)
      } finally {
        setIsSaving(false)
      }
    }
  }, [expression, onSaveSegment, validation.valid])

  // Handle load segment
  const handleLoadSegment = useCallback((segment: SavedSegment) => {
    const segmentData = segment as any
    if (segmentData.segment_data?.filters) {
      const loadedExpression = legacyFiltersToFilterExpression(
        segmentData.segment_data.filters,
        segmentData.segment_data.labels
      )
      setExpression(loadedExpression)
      setSelectedSegmentId(segment.id)
    }
  }, [])

  // Get legacy filters for preview
  const legacyFilters = React.useMemo(() => {
    return filterExpressionToLegacyFilters(expression)
  }, [expression])

  const conditionCount = expression.root.children.filter(c => 'dimension' in c).length
  const groupCount = expression.root.children.filter(c => !('dimension' in c)).length

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-medium text-gray-900">Filter Builder</h3>
        <div className="flex items-center space-x-2">
          {/* Load segment dropdown */}
          {savedSegments.length > 0 && (
            <div className="w-48">
              <SegmentList
                segments={savedSegments}
                selectedSegmentId={selectedSegmentId}
                onSelect={handleLoadSegment}
                onCreateNew={() => setIsSaveDialogOpen(true)}
              />
            </div>
          )}
        </div>
      </div>

      {/* Filter groups and conditions */}
      <div className="space-y-2">
        {expression.root.children.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            No conditions yet. Add a condition to get started.
          </div>
        ) : (
          <FilterGroupComponent
            group={expression.root}
            onChange={(group) => setExpression(prev => ({ ...prev, root: group }))}
            onAddCondition={handleAddCondition}
            onUpdateCondition={handleUpdateCondition}
            onDeleteCondition={handleDeleteCondition}
            depth={0}
          />
        )}
      </div>

      {/* Add buttons */}
      <div className="flex items-center space-x-2 pt-2">
        <button
          type="button"
          onClick={handleAddCondition}
          className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-700 bg-indigo-50 border border-indigo-200 rounded-md hover:bg-indigo-100"
        >
          <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Add condition
        </button>

        <button
          type="button"
          onClick={handleAddGroup}
          className="inline-flex items-center px-3 py-2 text-sm font-medium text-indigo-700 bg-indigo-50 border border-indigo-200 rounded-md hover:bg-indigo-100"
        >
          <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 14v6m-3-3h6M6 10h2a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2zm10 0h2a2 2 0 002-2V6a2 2 0 00-2-2h-2a2 2 0 00-2 2v2a2 2 0 002 2zM6 20h2a2 2 0 002-2v-2a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2z" />
          </svg>
          Add group
        </button>
      </div>

      {/* Validation errors */}
      {!validation.valid && (
        <div className="bg-red-50 border border-red-200 rounded-md p-3">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">
                Invalid filter
              </h3>
              <div className="mt-2 text-sm text-red-700">
                <ul className="list-disc pl-5 space-y-1">
                  {validation.errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Zero results warning */}
      {validation.valid && conditionCount === 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-md p-3">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <p className="text-sm text-yellow-700">
                Add at least one condition to create a filter.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex items-center justify-between pt-4 border-t border-gray-200">
        <div>
          <PreviewCount
            count={validation.valid && conditionCount > 0 ? undefined : null}
            isLoading={false}
          />
        </div>

        <div className="flex items-center space-x-2">
          <button
            type="button"
            onClick={() => setIsSaveDialogOpen(true)}
            disabled={!validation.valid || conditionCount === 0}
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Save as Segment
          </button>

          <button
            type="button"
            onClick={handleApply}
            disabled={!validation.valid || conditionCount === 0}
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Apply Filter
          </button>
        </div>
      </div>

      {/* Save segment dialog */}
      <SaveSegmentDialog
        isOpen={isSaveDialogOpen}
        onClose={() => setIsSaveDialogOpen(false)}
        onSave={handleSaveSegment}
        isSaving={isSaving}
      />
    </div>
  )
}

export default FilterBuilder
