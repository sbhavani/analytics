import React, { useCallback, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { XMarkIcon, ArrowPathIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { FilterBuilderProvider, useFilterBuilderContext } from './filter-builder-context'
import { filterGroupToLegacyFilters } from './filter-serialization'
import FilterGroup from './FilterGroup'
import FilterPreview from './FilterPreview'
import SaveSegmentModal from './SaveSegmentModal'
import LoadSegmentDropdown from './LoadSegmentDropdown'
import { FilterGroup as FilterGroupType, validateFilterStructure } from './types'

interface FilterBuilderContainerProps {
  isOpen: boolean
  onClose: () => void
  initialFilterGroup?: FilterGroupType
}

function FilterBuilderInner({ onClose }: { onClose: () => void }) {
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const { state, clearAll, applyFilter, isLoading, error } = useFilterBuilderContext()
  const [showSaveModal, setShowSaveModal] = useState(false)

  const handleApplyFilter = useCallback(() => {
    // Convert filter group to legacy format
    const filters = filterGroupToLegacyFilters(state.rootGroup)

    // Update URL with new filters
    const newSearchParams = new URLSearchParams(searchParams)
    newSearchParams.set('filters', JSON.stringify(filters))

    setSearchParams(newSearchParams)
    applyFilter()
  }, [state.rootGroup, searchParams, setSearchParams, applyFilter])

  const handleClearAll = useCallback(() => {
    clearAll()
  }, [clearAll])

  const handleClose = useCallback(() => {
    onClose()
  }, [onClose])

  const validation = validateFilterStructure(state.rootGroup)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 bg-white">
        <div className="flex items-center gap-4">
          <h3 className="text-lg font-medium text-gray-900">Advanced Filter Builder</h3>
          <LoadSegmentDropdown />
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowSaveModal(true)}
            disabled={!validation.isValid}
            className={classNames(
              'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
              {
                'bg-gray-100 text-gray-400 cursor-not-allowed': !validation.isValid,
                'bg-indigo-100 text-indigo-700 hover:bg-indigo-200': validation.isValid
              }
            )}
          >
            Save as Segment
          </button>
          <button
            onClick={handleClearAll}
            className="px-3 py-1.5 text-sm font-medium text-gray-600 hover:text-gray-700 hover:bg-gray-100 rounded-md transition-colors"
          >
            Clear All
          </button>
          <button
            onClick={handleClose}
            className="p-1 text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="mx-4 mt-3 px-3 py-2 bg-red-50 border border-red-200 rounded-md">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Filter builder content */}
      <div className="flex-1 overflow-y-auto p-4">
        <FilterGroup group={state.rootGroup} depth={0} />
      </div>

      {/* Footer with actions */}
      <div className="px-4 py-3 border-t border-gray-200 bg-gray-50">
        <div className="flex items-center justify-between">
          <FilterPreview />

          <div className="flex items-center gap-3">
            <button
              onClick={handleClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleApplyFilter}
              disabled={!validation.isValid || isLoading}
              className={classNames(
                'px-4 py-2 text-sm font-medium text-white rounded-md transition-colors flex items-center gap-2',
                {
                  'bg-gray-400 cursor-not-allowed': !validation.isValid || isLoading,
                  'bg-indigo-600 hover:bg-indigo-700': validation.isValid && !isLoading
                }
              )}
            >
              {isLoading && <ArrowPathIcon className="w-4 h-4 animate-spin" />}
              Apply Filter
            </button>
          </div>
        </div>

        {/* Validation errors */}
        {!validation.isValid && validation.errors.length > 0 && (
          <div className="mt-3">
            {validation.errors.map((err, idx) => (
              <p key={idx} className="text-xs text-red-600">• {err}</p>
            ))}
          </div>
        )}
      </div>

      {/* Save segment modal */}
      {showSaveModal && (
        <SaveSegmentModal
          filterGroup={state.rootGroup}
          onClose={() => setShowSaveModal(false)}
        />
      )}
    </div>
  )
}

export default function FilterBuilderContainer({ isOpen, onClose, initialFilterGroup }: FilterBuilderContainerProps) {
  if (!isOpen) return null

  const handleApplyFilter = (filterGroup: FilterGroupType) => {
    const filters = filterGroupToLegacyFilters(filterGroup)
    console.log('Applying filter:', filters)
    // The actual navigation happens in the inner component
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          onClick={onClose}
        />

        {/* Modal */}
        <div className="relative w-full max-w-3xl bg-white rounded-lg shadow-xl">
          <FilterBuilderProvider
            onApplyFilter={handleApplyFilter}
            initialGroup={initialFilterGroup}
          >
            <FilterBuilderInner onClose={onClose} />
          </FilterBuilderProvider>
        </div>
      </div>
    </div>
  )
}
