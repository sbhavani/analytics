import React, { useState, useEffect, useCallback } from 'react'
import type { FilterData, FilterLogic, Segment, FilterCondition, FilterGroup as FilterGroupType } from '../../../types/filter-builder'
import { useFilterBuilder } from '../../hooks/useFilterBuilder'
import { FilterGroup } from './FilterGroup'
import { VisitorCountDisplay } from './VisitorCountDisplay'
import { SegmentList } from './SegmentList'
import { SaveSegmentModal } from './SaveSegmentModal'
import { DeleteSegmentConfirm } from './DeleteSegmentConfirm'

interface FilterBuilderProps {
  siteId: string | number
  initialFilterData?: FilterData
  period?: string
  date?: string
  onFilterChange?: (filterData: FilterData) => void
}

export function FilterBuilder({
  siteId,
  initialFilterData,
  period = '30d',
  date,
  onFilterChange
}: FilterBuilderProps) {
  const [showSaveModal, setShowSaveModal] = useState(false)
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [segmentToDelete, setSegmentToDelete] = useState<number | null>(null)

  const {
    filterData,
    savedSegments,
    selectedSegmentId,
    isLoading,
    isSaving,
    error,
    visitorCount,
    visitorCountLoading,
    visitorCountError,
    validationErrors,
    addCondition,
    updateCondition,
    removeCondition,
    addNestedGroup,
    removeNestedGroup,
    setLogic,
    clearFilters,
    loadSegments,
    saveSegment,
    updateCurrentSegment,
    deleteCurrentSegment,
    selectSegment,
    loadSegmentToBuilder
  } = useFilterBuilder({
    siteId,
    initialFilterData,
    period,
    date
  })

  // Load segments on mount
  useEffect(() => {
    loadSegments()
  }, [loadSegments])

  // Notify parent of filter changes
  useEffect(() => {
    onFilterChange?.(filterData)
  }, [filterData, onFilterChange])

  // Find and update condition in any group
  const handleUpdateCondition = useCallback(
    (conditionId: string, updates: Partial<FilterCondition>) => {
      // Find the group containing this condition
      for (const group of filterData.filters) {
        const found = findConditionInGroup(group, conditionId)
        if (found) {
          updateCondition(found.groupId, conditionId, updates)
          return
        }
      }
    },
    [filterData, updateCondition]
  )

  // Find and remove condition from any group
  const handleRemoveCondition = useCallback(
    (conditionId: string) => {
      for (const group of filterData.filters) {
        const found = findConditionInGroup(group, conditionId)
        if (found) {
          removeCondition(found.groupId, conditionId)
          return
        }
      }
    },
    [filterData, removeCondition]
  )

  const findConditionInGroup = (
    group: FilterGroupType,
    conditionId: string,
    parentGroupId?: string
  ): { groupId: string } | null => {
    for (const item of group.conditions) {
      if (typeof item === 'object' && item !== null && 'id' in item && item.id === conditionId) {
        return { groupId: parentGroupId || group.id }
      }
      if (typeof item === 'object' && item !== null && 'logic' in item) {
        const found = findConditionInGroup(item as FilterGroupType, conditionId, group.id)
        if (found) return found
      }
    }
    return null
  }

  const handleSelectSegment = (segmentId: number) => {
    const segment = savedSegments.find(s => s.id === segmentId)
    if (segment) {
      loadSegmentToBuilder(segment)
      selectSegment(segmentId)
    }
  }

  const handleDeleteSegment = (segmentId: number) => {
    setSegmentToDelete(segmentId)
    setShowDeleteConfirm(true)
  }

  const handleConfirmDelete = async () => {
    if (segmentToDelete === null) return

    if (segmentToDelete === selectedSegmentId) {
      await deleteCurrentSegment()
    } else {
      // Delete from list directly
      const { deleteSegment } = await import('../../api/segments')
      await deleteSegment(siteId, segmentToDelete)
      await loadSegments()
    }
    setShowDeleteConfirm(false)
    setSegmentToDelete(null)
  }

  const selectedSegment = savedSegments.find(s => s.id === selectedSegmentId)
  const segmentToDeleteName = segmentToDelete
    ? savedSegments.find(s => s.id === segmentToDelete)?.name || ''
    : ''

  return (
    <div className="filter-builder p-4 bg-white rounded-lg shadow">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-900">
          Filter Builder
        </h2>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={clearFilters}
            className="px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900"
          >
            Clear All
          </button>
          <button
            type="button"
            onClick={() => setShowSaveModal(true)}
            disabled={validationErrors.length > 0}
            className="px-4 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Save Segment
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
          <ul className="list-disc list-inside text-sm text-yellow-700">
            {validationErrors.map((err, idx) => (
              <li key={idx}>{err}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Filter Groups */}
      <div className="space-y-4 mb-4">
        {filterData.filters.map((group: FilterGroupType) => (
          <FilterGroup
            key={group.id}
            group={group}
            onUpdateCondition={handleUpdateCondition}
            onRemoveCondition={handleRemoveCondition}
            onAddCondition={() => addCondition(group.id)}
            onToggleLogic={() => {}}
            onSetLogic={(logic: FilterLogic) => setLogic(group.id, logic)}
            onAddNestedGroup={() => addNestedGroup(group.id)}
            onRemoveNestedGroup={
              filterData.filters.length > 1
                ? (nestedGroupId: string) => {
                    // Remove the nested group
                    removeCondition(group.id, nestedGroupId)
                  }
                : undefined
            }
            disabled={isSaving}
          />
        ))}
      </div>

      {/* Keyboard Shortcuts Hint */}
      <div className="mb-4 text-xs text-gray-500 flex flex-wrap gap-3">
        <span className="flex items-center gap-1">
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-gray-600 font-mono">Tab</kbd>
          <span>Navigate</span>
        </span>
        <span className="flex items-center gap-1">
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-gray-600 font-mono">Enter</kbd>
          <span>Add condition</span>
        </span>
        <span className="flex items-center gap-1">
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-gray-600 font-mono">Alt</kbd>
          +
          <kbd className="px-1.5 py-0.5 bg-gray-100 border border-gray-300 rounded text-gray-600 font-mono">Del</kbd>
          <span>Remove</span>
        </span>
      </div>

      {/* Visitor Count */}
      <div className="flex items-center justify-between py-3 border-t border-gray-200">
        <VisitorCountDisplay
          count={visitorCount}
          loading={visitorCountLoading}
          error={visitorCountError}
        />

        {selectedSegment && (
          <div className="text-sm text-gray-500">
            Editing: <span className="font-medium">{selectedSegment.name}</span>
            <button
              type="button"
              onClick={() => setShowSaveModal(true)}
              className="ml-2 text-blue-600 hover:underline"
            >
              Update
            </button>
          </div>
        )}
      </div>

      {/* Saved Segments */}
      <div className="mt-6 pt-4 border-t border-gray-200">
        <h3 className="text-sm font-medium text-gray-700 mb-2">
          Saved Segments
        </h3>
        <SegmentList
          segments={savedSegments}
          selectedSegmentId={selectedSegmentId}
          onSelect={handleSelectSegment}
          onDelete={handleDeleteSegment}
          isLoading={isLoading}
        />
      </div>

      {/* Save Modal */}
      <SaveSegmentModal
        isOpen={showSaveModal}
        onClose={() => setShowSaveModal(false)}
        onSave={selectedSegmentId ? updateCurrentSegment : saveSegment}
        isSaving={isSaving}
        existingName={selectedSegment?.name}
        visitorCount={visitorCount}
      />

      {/* Delete Confirmation */}
      <DeleteSegmentConfirm
        isOpen={showDeleteConfirm}
        segmentName={segmentToDeleteName}
        onClose={() => {
          setShowDeleteConfirm(false)
          setSegmentToDelete(null)
        }}
        onConfirm={handleConfirmDelete}
        isDeleting={isSaving}
      />
    </div>
  )
}
