import React, { useState, useCallback } from 'react'
import { XMarkIcon, BookmarkIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
import { FilterBuilderProvider, useFilterBuilder } from './FilterBuilderContext'
import ConditionGroup from './ConditionGroup'
import FilterSummary from './FilterSummary'
import SegmentPreview from './SegmentPreview'
import SaveTemplateModal from './SaveTemplateModal'
import LoadTemplateDropdown from './LoadTemplateDropdown'
import { FilterCondition } from './types'

interface FilterBuilderProps {
  isOpen: boolean
  onClose: () => void
  onApply?: (filters: [string, string, string[]][]) => void
  onSaveSegment?: (name: string, filters: [string, string, string[]][]) => void
}

function FilterBuilderInner({ onClose, onApply, onSaveSegment }: { onClose: () => void; onApply?: (filters: [string, string, string[]][]) => void; onSaveSegment?: (name: string, filters: [string, string, string[]][]) => void }) {
  const [isSaveModalOpen, setIsSaveModalOpen] = useState(false)

  const {
    state,
    addCondition,
    updateCondition,
    deleteCondition,
    addNestedGroup,
    deleteNestedGroup,
    updateConnector,
    clearAll,
    isValid,
    filterSummary,
    legacyFilters
  } = useFilterBuilder()

  const handleAddCondition = useCallback((groupId: string) => {
    addCondition(groupId, {
      attribute: '',
      operator: 'equals',
      value: ''
    })
  }, [addCondition])

  const handleUpdateCondition = useCallback((conditionId: string, updates: Partial<FilterCondition>) => {
    updateCondition(conditionId, updates)
  }, [updateCondition])

  const handleDeleteCondition = useCallback((conditionId: string) => {
    deleteCondition(conditionId)
  }, [deleteCondition])

  const handleAddNestedGroup = useCallback((groupId: string) => {
    addNestedGroup(groupId)
  }, [addNestedGroup])

  const handleConnectorChange = useCallback((groupId: string, connector: 'AND' | 'OR') => {
    updateConnector(groupId, connector)
  }, [updateConnector])

  const handleDeleteNestedGroup = useCallback((groupId: string) => {
    deleteNestedGroup(groupId)
  }, [deleteNestedGroup])

  const handleApply = useCallback(() => {
    if (isValid && onApply) {
      onApply(legacyFilters)
      onClose()
    }
  }, [isValid, onApply, onClose, legacyFilters])

  const handleClearAll = useCallback(() => {
    clearAll()
  }, [clearAll])

  const handleOpenSaveModal = useCallback(() => {
    setIsSaveModalOpen(true)
  }, [])

  const handleCloseSaveModal = useCallback(() => {
    setIsSaveModalOpen(false)
  }, [])

  const handleSaveSegment = useCallback((name: string) => {
    if (onSaveSegment) {
      onSaveSegment(name, legacyFilters)
    }
  }, [onSaveSegment, legacyFilters])

  // Get all conditions for analytics
  const totalConditions = state.filterTree.rootGroup.conditions.length +
    state.filterTree.rootGroup.nestedGroups.reduce((acc, g) => acc + g.conditions.length, 0)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
        <h2 className="text-lg font-semibold text-gray-900">
          Advanced Filter Builder
        </h2>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={handleClearAll}
            className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
            aria-label="Clear all filters"
          >
            <ArrowPathIcon className="h-4 w-4 mr-1" />
            Clear
          </button>
          <div className="w-48">
            <LoadTemplateDropdown />
          </div>
          <button
            type="button"
            onClick={handleOpenSaveModal}
            className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-indigo-700 bg-indigo-50 rounded-md hover:bg-indigo-100"
            aria-label="Save filter as segment"
          >
            <BookmarkIcon className="h-4 w-4 mr-1" />
            Save
          </button>
        </div>
      </div>

      {/* Body */}
      <div className="flex-1 overflow-y-auto p-6">
        {/* Filter preview */}
        <div className="mb-4">
          <SegmentPreview />
        </div>

        {/* Filter conditions */}
        <div className="space-y-4">
          <ConditionGroup
            group={state.filterTree.rootGroup}
            groupId={state.filterTree.rootGroup.id}
            level={0}
            onUpdateCondition={handleUpdateCondition}
            onDeleteCondition={handleDeleteCondition}
            onAddCondition={handleAddCondition}
            onUpdateConnector={(connector) => handleConnectorChange(state.filterTree.rootGroup.id, connector)}
            onAddNestedGroup={handleAddNestedGroup}
            onDeleteNestedGroup={handleDeleteNestedGroup}
          />
        </div>

        {/* Filter summary */}
        {filterSummary && (
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <h3 className="text-sm font-medium text-gray-700 mb-2">Filter Summary</h3>
            <FilterSummary summary={filterSummary} />
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200 bg-gray-50">
        <div className="text-sm text-gray-500">
          {totalConditions === 0
            ? 'No conditions added'
            : `${totalConditions} condition${totalConditions !== 1 ? 's' : ''}`
          }
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleApply}
            disabled={!isValid}
            className={`
              px-4 py-2 text-sm font-medium rounded-md
              ${isValid
                ? 'text-white bg-indigo-600 hover:bg-indigo-700'
                : 'text-gray-400 bg-gray-300 cursor-not-allowed'
              }
            `}
            aria-disabled={!isValid}
          >
            Apply Filter
          </button>
        </div>
      </div>

      {/* Save Template Modal */}
      <SaveTemplateModal
        isOpen={isSaveModalOpen}
        onClose={handleCloseSaveModal}
        onSave={handleSaveSegment}
        filterSummary={filterSummary}
      />
    </div>
  )
}

export function FilterBuilder({ isOpen, onClose, onApply, onSaveSegment }: FilterBuilderProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div
          className="relative w-full max-w-3xl bg-white rounded-lg shadow-xl"
          role="dialog"
          aria-modal="true"
          aria-labelledby="filter-builder-title"
        >
          <FilterBuilderProvider>
            <FilterBuilderInner onClose={onClose} onApply={onApply} onSaveSegment={onSaveSegment} />
          </FilterBuilderProvider>
        </div>
      </div>
    </div>
  )
}

export default FilterBuilder
