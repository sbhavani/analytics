import React, { useState, useCallback, useRef, useEffect, useMemo } from 'react'
import classNames from 'classnames'
import { FilterCondition, AVAILABLE_DIMENSIONS, getOperatorsForDimension, FilterDimension } from '../../lib/filter-parser'
import { XIcon, ChevronDownIcon } from '@heroicons/react/solid'

interface ConditionRowProps {
  condition: FilterCondition
  onUpdate: (updates: Partial<FilterCondition>) => void
  onRemove: () => void
  loading?: boolean
}

// Memoized comparison function for ConditionRow - prevents unnecessary re-renders
const conditionRowPropsAreEqual = (
  prevProps: ConditionRowProps,
  nextProps: ConditionRowProps
): boolean => {
  return (
    prevProps.condition.id === nextProps.condition.id &&
    prevProps.condition.dimension === nextProps.condition.dimension &&
    prevProps.condition.operator === nextProps.condition.operator &&
    JSON.stringify(prevProps.condition.value) === JSON.stringify(nextProps.condition.value) &&
    prevProps.loading === nextProps.loading
  )
}

export const ConditionRow = React.memo<ConditionRowProps>(({
  condition,
  onUpdate,
  onRemove,
  loading = false
}) => {
  const [dimensionSearch, setDimensionSearch] = useState('')
  const [dimensionDropdownOpen, setDimensionDropdownOpen] = useState(false)
  const dimensionInputRef = useRef<HTMLInputElement>(null)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Memoize filtered dimensions to avoid recalculating on every render
  const filteredDimensions = useMemo(() => {
    if (!dimensionSearch) return AVAILABLE_DIMENSIONS
    const searchLower = dimensionSearch.toLowerCase()
    return AVAILABLE_DIMENSIONS.filter(d =>
      d.label.toLowerCase().includes(searchLower) ||
      d.key.toLowerCase().includes(searchLower)
    )
  }, [dimensionSearch])

  // Group dimensions by category for better UX - memoized
  const groupedDimensions = useMemo(() => {
    const groups: Record<string, FilterDimension[]> = {}
    for (const dim of filteredDimensions) {
      if (!groups[dim.group]) {
        groups[dim.group] = []
      }
      groups[dim.group].push(dim)
    }
    return groups
  }, [filteredDimensions])

  // Memoize selected dimension lookup
  const selectedDimension = useMemo(() => {
    return AVAILABLE_DIMENSIONS.find(d => d.key === condition.dimension)
  }, [condition.dimension])

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setDimensionDropdownOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Memoize handlers
  const handleDimensionSelect = useCallback((dimension: FilterDimension) => {
    onUpdate({ dimension: dimension.key, value: [] })
    setDimensionSearch('')
    setDimensionDropdownOpen(false)
  }, [onUpdate])

  const handleDimensionInputClick = useCallback(() => {
    setDimensionDropdownOpen(true)
  }, [])

  // Memoize operators to avoid recalculating
  const operators = useMemo(() => {
    return getOperatorsForDimension(condition.dimension)
  }, [condition.dimension])

  const handleOperatorChange = useCallback((e: React.ChangeEvent<HTMLSelectElement>) => {
    onUpdate({ operator: e.target.value as FilterCondition['operator'] })
  }, [onUpdate])

  const handleValueChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value.split(',').map(v => v.trim()).filter(Boolean)
    onUpdate({ value: newValue })
  }, [onUpdate])

  return (
    <div className="flex items-center gap-2 p-2 bg-white dark:bg-gray-800 rounded-md border border-gray-200 dark:border-gray-700">
      {/* Dimension selector - searchable dropdown */}
      <div className="relative flex-shrink-0 min-w-[180px]" ref={dropdownRef}>
        <div className="relative">
          <input
            ref={dimensionInputRef}
            type="text"
            value={dimensionSearch || (selectedDimension ? selectedDimension.label : '')}
            onChange={(e) => {
              setDimensionSearch(e.target.value)
              if (!dimensionDropdownOpen) setDimensionDropdownOpen(true)
            }}
            onFocus={() => setDimensionDropdownOpen(true)}
            onClick={handleDimensionInputClick}
            placeholder="Select property..."
            className={classNames(
              'w-full rounded-md text-sm pr-8',
              'border-gray-300 dark:border-gray-600',
              'focus:ring-indigo-500 focus:border-indigo-500',
              'dark:bg-gray-700 dark:text-gray-200',
              'cursor-pointer'
            )}
            disabled={loading}
            autoComplete="off"
          />
          <div className="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
            <ChevronDownIcon className="w-4 h-4 text-gray-400" />
          </div>
        </div>

        {/* Dropdown menu */}
        {dimensionDropdownOpen && (
          <div className="absolute z-10 w-full mt-1 bg-white dark:bg-gray-800 rounded-md shadow-lg border border-gray-200 dark:border-gray-700 max-h-64 overflow-y-auto">
            {filteredDimensions.length === 0 ? (
              <div className="px-3 py-2 text-sm text-gray-500 dark:text-gray-400">
                No dimensions found
              </div>
            ) : (
              Object.entries(groupedDimensions).map(([group, dims]) => (
                <div key={group}>
                  <div className="px-3 py-1 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase bg-gray-50 dark:bg-gray-700/50">
                    {group}
                  </div>
                  {dims.map(dim => (
                    <button
                      key={dim.key}
                      type="button"
                      onClick={() => handleDimensionSelect(dim)}
                      className={classNames(
                        'w-full px-3 py-2 text-left text-sm',
                        'hover:bg-gray-100 dark:hover:bg-gray-700',
                        'focus:outline-none focus:bg-gray-100 dark:focus:bg-gray-700',
                        condition.dimension === dim.key
                          ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300'
                          : 'text-gray-700 dark:text-gray-200'
                      )}
                    >
                      {dim.label}
                    </button>
                  ))}
                </div>
              ))
            )}
          </div>
        )}
      </div>

      {/* Operator selector */}
      <select
        value={condition.operator}
        onChange={handleOperatorChange}
        className={classNames(
          'flex-shrink-0 rounded-md text-sm',
          'border-gray-300 dark:border-gray-600',
          'focus:ring-indigo-500 focus:border-indigo-500',
          'dark:bg-gray-700 dark:text-gray-200',
          'min-w-[120px]',
          { 'opacity-50': !condition.dimension }
        )}
        disabled={loading || !condition.dimension}
      >
        {operators.map(op => (
          <option key={op} value={op}>
            {formatOperator(op)}
          </option>
        ))}
      </select>

      {/* Value input */}
      <input
        type="text"
        value={condition.value.join(', ')}
        onChange={handleValueChange}
        placeholder={getValuePlaceholder(condition.dimension, condition.operator)}
        className={classNames(
          'flex-1 rounded-md text-sm',
          'border-gray-300 dark:border-gray-600',
          'focus:ring-indigo-500 focus:border-indigo-500',
          'dark:bg-gray-700 dark:text-gray-200',
          { 'opacity-50': !condition.dimension || !condition.operator }
        )}
        disabled={loading || !condition.dimension || !condition.operator}
      />

      {/* Remove button */}
      <button
        onClick={onRemove}
        className={classNames(
          'flex-shrink-0 p-1 rounded-md',
          'text-gray-400 hover:text-red-500',
          'hover:bg-red-50 dark:hover:bg-red-900/20',
          'transition-colors duration-150'
        )}
        disabled={loading}
        title="Remove condition"
      >
        <XIcon className="w-5 h-5" />
      </button>
    </div>
  )
}, conditionRowPropsAreEqual)

function formatOperator(operator: string): string {
  const operatorMap: Record<string, string> = {
    is: 'equals',
    is_not: 'does not equal',
    contains: 'contains',
    matches: 'matches regex',
    matches_wildcard: 'matches wildcard',
    has_done: 'has done',
    has_not_done: 'has not done',
    greater_than: 'greater than',
    less_than: 'less than'
  }
  return operatorMap[operator] || operator
}

function getValuePlaceholder(dimension: string, operator: string): string {
  if (operator === 'has_done' || operator === 'has_not_done') {
    return 'Select goal...'
  }
  if (dimension.includes('country')) {
    return 'e.g., US, GB, DE'
  }
  if (dimension.includes('device')) {
    return 'e.g., Desktop, Mobile, Tablet'
  }
  return 'Enter value...'
}

export default ConditionRow
