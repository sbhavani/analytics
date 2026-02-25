import React, { useState, useCallback, useRef, useEffect } from 'react'
import {
  FilterRoot,
  FilterPreview,
  SavedSegmentInfo,
  HistoryEntry
} from './types'
import { FilterGroup } from './FilterGroup'
import {
  createEmptyFilterRoot,
  createFilterCondition,
  createFilterGroup,
  validateFilter,
  countConditions,
  hasMaxConditions,
  sanitizeSegmentName,
  validateSegmentName,
  convertToFlatFilters,
  getNestingDepth
} from './filter-utils'

interface FilterBuilderProps {
  siteId: number
  initialFilters?: FilterRoot
  onApply?: (filters: FilterRoot) => void
  onClose?: () => void
  savedSegments?: SavedSegmentInfo[]
  onLoadSegment?: (segmentId: number) => void
}

export function FilterBuilder({
  siteId: _siteId,
  initialFilters,
  onApply,
  onClose,
  savedSegments = [],
  onLoadSegment
}: FilterBuilderProps) {
  const [rootGroup, setRootGroup] = useState<FilterRoot>(initialFilters || createEmptyFilterRoot())
  const [errors, setErrors] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [preview, setPreview] = useState<FilterPreview | null>(null)
  const [showSegmentList, setShowSegmentList] = useState(false)
  const [showSaveModal, setShowSaveModal] = useState(false)
  const [segmentName, setSegmentName] = useState('')
  const [saveError, setSaveError] = useState<string | null>(null)
  const [history, setHistory] = useState<HistoryEntry[]>([])
  const debounceRef = useRef<NodeJS.Timeout | null>(null)

  // Update root group and save to history
  const handleRootChange = useCallback((newRoot: FilterRoot) => {
    // Save current state to history for undo
    setHistory(prev => [...prev.slice(-19), { rootGroup, timestamp: Date.now() }])
    setRootGroup(newRoot)
  }, [rootGroup])

  // Undo functionality
  const handleUndo = useCallback(() => {
    if (history.length > 0) {
      const previousState = history[history.length - 1]
      setRootGroup(previousState.rootGroup)
      setHistory(prev => prev.slice(0, -1))
    }
  }, [history])

  // Add new condition to root
  const handleAddCondition = useCallback(() => {
    if (hasMaxConditions(rootGroup)) {
      setErrors(['Maximum of 20 conditions allowed'])
      return
    }
    const newConditions = [...rootGroup.conditions, createFilterCondition()]
    handleRootChange({ ...rootGroup, conditions: newConditions })
  }, [rootGroup, handleRootChange])

  // Add new group to root
  const handleAddGroup = useCallback(() => {
    if (getNestingDepth(rootGroup) >= 4) {
      setErrors(['Maximum nesting depth of 5 levels reached'])
      return
    }
    const newGroups = [...rootGroup.groups, createFilterGroup('AND')]
    handleRootChange({ ...rootGroup, groups: newGroups })
  }, [rootGroup, handleRootChange])

  // Clear all conditions
  const handleClearAll = useCallback(() => {
    handleRootChange(createEmptyFilterRoot())
    setHistory([])
    setErrors([])
    setPreview(null)
  }, [handleRootChange])

  // Handle apply
  const handleApply = useCallback(() => {
    const validation = validateFilter(rootGroup)
    if (!validation.isValid) {
      setErrors(validation.errors)
      return
    }
    setErrors([])
    onApply?.(rootGroup)
  }, [rootGroup, onApply])

  // Fetch preview (debounced)
  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current)
    }

    const validation = validateFilter(rootGroup)
    if (!validation.isValid) {
      setPreview(null)
      return
    }

    debounceRef.current = setTimeout(async () => {
      setIsLoading(true)
      try {
        const flatFilters = convertToFlatFilters(rootGroup)
        // In a real implementation, this would call the API
        // For now, we'll simulate a preview response
        console.log('Fetching preview for filters:', flatFilters)
        // Simulated preview - in production this would be an API call
        setPreview({ visitors: Math.floor(Math.random() * 10000), sample_percent: null })
      } catch (err) {
        console.error('Failed to fetch preview:', err)
      } finally {
        setIsLoading(false)
      }
    }, 400) // 400ms debounce

    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current)
      }
    }
  }, [rootGroup])

  // Save segment
  const handleSaveSegment = useCallback(async () => {
    const validation = validateSegmentName(segmentName)
    if (!validation.isValid) {
      setSaveError(validation.error || 'Invalid segment name')
      return
    }

    const filterValidation = validateFilter(rootGroup)
    if (!filterValidation.isValid) {
      setSaveError(filterValidation.errors[0] || 'Invalid filter')
      return
    }

    setIsLoading(true)
    setSaveError(null)

    try {
      const flatFilters = convertToFlatFilters(rootGroup)
      // In a real implementation, this would call the API
      console.log('Saving segment:', { name: sanitizeSegmentName(segmentName), filters: flatFilters })
      // Simulated save
      setShowSaveModal(false)
      setSegmentName('')
    } catch (_err) {
      setSaveError('Failed to save segment')
    } finally {
      setIsLoading(false)
    }
  }, [segmentName, rootGroup])

  // Load segment
  const handleLoadSegment = useCallback((segmentId: number) => {
    const segment = savedSegments.find(s => s.id === segmentId)
    if (segment && onLoadSegment) {
      // Parse the segment data back to FilterRoot
      // This is simplified - in production you'd have proper parsing
      setRootGroup(createEmptyFilterRoot())
      setShowSegmentList(false)
      onLoadSegment(segmentId)
    }
  }, [savedSegments, onLoadSegment])

  const conditionCount = countConditions(rootGroup)
  const isEmpty = conditionCount === 0
  const canAddMore = !hasMaxConditions(rootGroup)
  const canAddNested = getNestingDepth(rootGroup) < 5

  return (
    <div className="bg-white rounded-lg shadow-lg p-4 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-4 pb-4 border-b border-gray-200">
        <h2 className="text-lg font-semibold text-gray-800">Filter Builder</h2>
        <div className="flex items-center gap-2">
          {savedSegments.length > 0 && (
            <div className="relative">
              <button
                onClick={() => setShowSegmentList(!showSegmentList)}
                className="px-3 py-1.5 text-sm text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded"
              >
                Load Segment
              </button>
              {showSegmentList && (
                <div className="absolute right-0 mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                  <div className="p-2">
                    {savedSegments.map(segment => (
                      <button
                        key={segment.id}
                        onClick={() => handleLoadSegment(segment.id)}
                        className="w-full text-left px-3 py-2 text-sm hover:bg-gray-50 rounded"
                      >
                        {segment.name}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
          {onClose && (
            <button
              onClick={onClose}
              className="p-1.5 text-gray-400 hover:text-gray-600"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {/* Preview */}
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-2">
          {isLoading ? (
            <span className="text-sm text-gray-500">Updating preview...</span>
          ) : preview ? (
            <span className="text-sm text-gray-600">
              Matches <strong className="text-indigo-600">{preview.visitors.toLocaleString()}</strong> visitors
            </span>
          ) : isEmpty ? (
            <span className="text-sm text-gray-500">Add conditions to see preview</span>
          ) : (
            <span className="text-sm text-red-500">{errors[0]}</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          {history.length > 0 && (
            <button
              onClick={handleUndo}
              className="px-2 py-1 text-sm text-gray-500 hover:text-gray-700"
            >
              Undo
            </button>
          )}
        </div>
      </div>

      {/* Filter Groups */}
      <div className="space-y-3 mb-4">
        {/* Root conditions */}
        <FilterGroup
          group={rootGroup}
          onChange={handleRootChange}
          canAddNested={canAddNested}
        />
      </div>

      {/* Add Buttons */}
      <div className="flex flex-wrap gap-2 mb-4">
        <button
          onClick={handleAddCondition}
          disabled={!canAddMore}
          className="px-3 py-1.5 text-sm bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        >
          + Add Condition
        </button>
        <button
          onClick={handleAddGroup}
          disabled={!canAddNested}
          className="px-3 py-1.5 text-sm bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        >
          + Add Group
        </button>
        {!isEmpty && (
          <button
            onClick={handleClearAll}
            className="px-3 py-1.5 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded"
          >
            Clear All
          </button>
        )}
      </div>

      {/* Empty State */}
      {isEmpty && (
        <div className="text-center py-8 bg-gray-50 rounded-lg mb-4">
          <p className="text-gray-500 mb-2">No filter conditions added yet</p>
          <p className="text-sm text-gray-400">Add conditions to create a visitor segment</p>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
        <button
          onClick={() => setShowSaveModal(true)}
          disabled={isEmpty || !validateFilter(rootGroup).isValid}
          className="px-4 py-2 text-sm text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Save Segment
        </button>
        <button
          onClick={handleApply}
          disabled={isEmpty || !validateFilter(rootGroup).isValid}
          className="px-4 py-2 text-sm bg-indigo-600 text-white hover:bg-indigo-700 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Apply Filter
        </button>
      </div>

      {/* Save Modal */}
      {showSaveModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96">
            <h3 className="text-lg font-semibold mb-4">Save Segment</h3>
            <input
              type="text"
              value={segmentName}
              onChange={(e) => setSegmentName(e.target.value)}
              placeholder="Enter segment name..."
              className="w-full px-3 py-2 border border-gray-300 rounded mb-2 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              // eslint-disable-next-line jsx-a11y/no-autofocus
              autoFocus
            />
            {saveError && (
              <p className="text-sm text-red-500 mb-3">{saveError}</p>
            )}
            <div className="flex justify-end gap-2">
              <button
                onClick={() => {
                  setShowSaveModal(false)
                  setSegmentName('')
                  setSaveError(null)
                }}
                className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveSegment}
                disabled={isLoading}
                className="px-4 py-2 text-sm bg-indigo-600 text-white hover:bg-indigo-700 rounded disabled:opacity-50"
              >
                {isLoading ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default FilterBuilder
