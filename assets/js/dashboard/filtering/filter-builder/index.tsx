import React, { useState, useEffect } from 'react'
import {
  FilterComposite,
  FilterGroup,
  flatToNested,
  isValidNestingDepth,
  isValidChildCount,
  createEmptyFilterGroup,
  getNestingDepth,
  getAllLeafConditions,
  MAX_NESTING_DEPTH
} from '../util/filter-serializer'
import FilterGroupComponent from './filter-group'

// Re-export for convenience
export { FilterCondition } from './filter-condition'
export { FilterConnector } from './filter-connector'
export { FilterGroup } from './filter-group'
export { NestedGroupIndicator } from './nested-group'

interface Dimension {
  key: string
  name: string
}

interface FilterBuilderProps {
  /** Current filter configuration - can be flat array or nested */
  filter: FilterComposite | unknown[]
  /** Callback when filter changes */
  onChange: (filter: FilterComposite) => void
  /** Available filter dimensions */
  availableDimensions: Dimension[]
  /** Maximum nesting depth allowed */
  maxDepth?: number
  /** Maximum children per group */
  maxChildren?: number
  /** Whether the builder is read-only */
  readOnly?: boolean
  /** Callback when user wants to save as segment */
  onSaveSegment?: () => void
  /** Whether there are unsaved changes */
  hasUnsavedChanges?: boolean
}

export const FilterBuilder: React.FC<FilterBuilderProps> = ({
  filter,
  onChange,
  availableDimensions,
  maxDepth = MAX_NESTING_DEPTH,
  readOnly = false,
  onSaveSegment,
  hasUnsavedChanges = false
}) => {
  // Normalize filter to nested format
  const [currentFilter, setCurrentFilter] = useState<FilterComposite>(() => {
    if (Array.isArray(filter)) {
      // Check if it's already a nested format or flat array
      if (filter.length > 0 && 'filter_type' in filter[0]) {
        return filter[0] as FilterComposite
      }
      return flatToNested(filter as any[])
    }
    return filter as FilterComposite
  })

  const [validationError, setValidationError] = useState<string | null>(null)

  // Update when prop changes
  useEffect(() => {
    if (Array.isArray(filter)) {
      if (filter.length > 0 && 'filter_type' in filter[0]) {
        setCurrentFilter(filter[0] as FilterComposite)
      } else {
        setCurrentFilter(flatToNested(filter as any[]))
      }
    } else {
      setCurrentFilter(filter as FilterComposite)
    }
  }, [filter])

  // Validate filter on change
  useEffect(() => {
    validateFilter(currentFilter)
  }, [currentFilter])

  const validateFilter = (f: FilterComposite) => {
    if (!isValidNestingDepth(f)) {
      setValidationError(`Maximum nesting depth of ${maxDepth} exceeded`)
      return
    }
    if (!isValidChildCount(f)) {
      setValidationError('Maximum children per group exceeded')
      return
    }
    setValidationError(null)
  }

  const handleFilterChange = (newFilter: FilterComposite) => {
    setCurrentFilter(newFilter)
    onChange(newFilter)
  }

  const handleAddGroup = () => {
    const newGroup = createEmptyFilterGroup()
    handleFilterChange(newGroup)
  }

  // Check if we have a valid group
  const isGroup = (f: FilterComposite): f is FilterGroup => {
    return 'filter_type' in f
  }

  // Calculate stats
  const conditionCount = getAllLeafConditions(currentFilter).length
  const currentDepth = getNestingDepth(currentFilter)

  return (
    <div className="filter-builder" role="region" aria-label="Filter Builder">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Filter Builder</h3>
          <p className="text-sm text-gray-500">
            {conditionCount} condition{conditionCount !== 1 ? 's' : ''} • Depth: {currentDepth}
          </p>
        </div>
        {onSaveSegment && (
          <button
            onClick={onSaveSegment}
            disabled={!!validationError || conditionCount === 0}
            className="px-4 py-2 bg-indigo-600 text-white rounded-md text-sm hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
            aria-label="Save as segment"
          >
            Save Segment
            {hasUnsavedChanges && <span className="ml-1">*</span>}
          </button>
        )}
      </div>

      {/* Validation error */}
      {validationError && (
        <div
          className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg text-amber-700 text-sm"
          role="alert"
        >
          {validationError}
        </div>
      )}

      {/* Filter content */}
      <div className="filter-content">
        {isGroup(currentFilter) ? (
          <FilterGroupComponent
            group={currentFilter}
            groupId="root"
            depth={0}
            availableDimensions={availableDimensions}
            maxDepth={maxDepth}
            onChange={handleFilterChange}
            readOnly={readOnly}
          />
        ) : (
          // Single condition - wrap in a group
          <FilterGroupComponent
            group={{ filter_type: 'and', children: [currentFilter] }}
            groupId="root"
            depth={0}
            availableDimensions={availableDimensions}
            maxDepth={maxDepth}
            onChange={handleFilterChange}
            readOnly={readOnly}
          />
        )}
      </div>

      {/* Add group button (only at root) */}
      {!readOnly && (
        <div className="mt-4 pt-4 border-t border-gray-200">
          <button
            onClick={handleAddGroup}
            className="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-800"
            aria-label="Create new filter group"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"
              />
            </svg>
            Create Filter Group
          </button>
        </div>
      )}

      {/* Help text */}
      <div className="mt-4 text-xs text-gray-500">
        <p>
          Use AND to narrow results (all conditions must match).
          Use OR to broaden results (any condition can match).
        </p>
        <p className="mt-1">
          Nest groups to create complex filters like (Country=US AND Device=Mobile) OR (Country=UK).
        </p>
      </div>
    </div>
  )
}

export default FilterBuilder
