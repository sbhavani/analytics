import React, { useState, useCallback } from 'react'
import { TrashIcon } from '@heroicons/react/20/solid'
import { FilterCondition, FilterAttribute, FILTER_ATTRIBUTES } from './types'
import DimensionSelector from './DimensionSelector'
import OperatorSelector from './OperatorSelector'

interface ConditionRowProps {
  condition: FilterCondition
  isFirst: boolean
  connector?: 'AND' | 'OR'
  onUpdate: (updates: Partial<FilterCondition>) => void
  onDelete: () => void
}

export function ConditionRow({
  condition,
  isFirst,
  connector = 'AND',
  onUpdate,
  onDelete
}: ConditionRowProps) {
  const [isEditing, setIsEditing] = useState(!condition.attribute)

  const handleAttributeChange = useCallback((attribute: FilterAttribute) => {
    onUpdate({ attribute })
    setIsEditing(false)
  }, [onUpdate])

  const handleOperatorChange = useCallback((operator: string) => {
    onUpdate({ operator: operator as FilterCondition['operator'] })
  }, [onUpdate])

  const handleValueChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    onUpdate({ value: e.target.value })
  }, [onUpdate])

  const selectedDimension = FILTER_ATTRIBUTES.find(d => d.key === condition.attribute)
  const needsValue = condition.attribute && !['is_set', 'is_not_set'].includes(condition.operator)

  return (
    <div className="flex items-center gap-2 p-2 bg-white rounded-md border border-gray-200">
      {/* Connector (AND/OR) - shown for all but first item */}
      {!isFirst && (
        <div className="flex-shrink-0">
          <span
            className={`
              inline-flex items-center px-2 py-1 text-xs font-medium rounded
              ${connector === 'AND'
                ? 'bg-blue-100 text-blue-800'
                : 'bg-purple-100 text-purple-800'
              }
            `}
          >
          </span>
            {connector}
        </div>
      )}

      {/* Dimension selector */}
      <div className="flex-shrink-0 w-40">
        <DimensionSelector
          value={condition.attribute}
          onChange={handleAttributeChange}
          disabled={!isEditing}
        />
      </div>

      {/* Operator selector */}
      <div className="flex-shrink-0 w-36">
        <OperatorSelector
          value={condition.operator}
          onChange={handleOperatorChange}
          dimension={condition.attribute}
        />
      </div>

      {/* Value input */}
      <div className="flex-1 min-w-0">
        {needsValue ? (
          <input
            type="text"
            value={condition.value}
            onChange={handleValueChange}
            placeholder={selectedDimension?.placeholder || 'Enter value'}
            className={`
              w-full rounded-md border-gray-300 shadow-sm
              focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm
              ${!condition.value && condition.attribute ? 'border-red-300' : ''}
            `}
            aria-label={`Value for ${selectedDimension?.label || 'filter'}`}
          />
        ) : (
          <div className="text-sm text-gray-500 py-2">
            {condition.operator === 'is_set' ? 'Field is set' : 'Field is not set'}
          </div>
        )}
      </div>

      {/* Delete button */}
      <div className="flex-shrink-0">
        <button
          type="button"
          onClick={onDelete}
          className="inline-flex items-center p-1 text-gray-400 hover:text-red-500 rounded-md hover:bg-red-50 transition-colors"
          aria-label="Delete condition"
        >
          <TrashIcon className="h-5 w-5" />
        </button>
      </div>
    </div>
  )
}

export default ConditionRow
