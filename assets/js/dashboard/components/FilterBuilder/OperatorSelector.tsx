import type { FilterOperator } from '../../../types/filter-builder'
import { getOperatorsForAttribute, OPERATOR_DISPLAY_NAMES } from '../../util/filter-attributes'
import React, { forwardRef } from 'react'

interface OperatorSelectorProps {
  attribute: string
  value: FilterOperator
  onChange: (value: FilterOperator) => void
  onKeyDown?: (e: React.KeyboardEvent<HTMLSelectElement>) => void
  disabled?: boolean
}

export const OperatorSelector = forwardRef<HTMLSelectElement, OperatorSelectorProps>(
  function OperatorSelector({ attribute, value, onChange, onKeyDown, disabled = false }, ref) {
    const operators = attribute ? getOperatorsForAttribute(attribute) : []

    return (
      <select
        ref={ref}
        value={value}
        onChange={(e) => onChange(e.target.value as FilterOperator)}
        onKeyDown={onKeyDown}
        disabled={disabled || operators.length === 0}
        className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[140px]"
        aria-label="Select operator"
      >
        {operators.length === 0 ? (
          <option value="">Select attribute first</option>
        ) : (
          operators.map((op) => (
            <option key={op} value={op}>
              {OPERATOR_DISPLAY_NAMES[op] || op}
            </option>
          ))
        )}
      </select>
    )
  }
)
