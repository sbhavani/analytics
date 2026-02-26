/**
 * FilterConditionRow Component
 *
 * A single filter condition row in the Advanced Filter Builder.
 * Contains field selection, operator selection, and value input.
 */

import React, { useState, useMemo, useEffect } from 'react'
import {
  FilterCondition,
  FilterOperator,
  DEFAULT_FILTER_FIELDS
} from './types'
import { FieldSelect } from './filter-field-select'
import { OperatorSelect } from './filter-operator-select'
import { FilterValueInput } from './filter-value-input'

interface FilterConditionRowProps {
  /** The filter condition to display */
  condition: FilterCondition
  /** ID of the group containing this condition */
  groupId: string
  /** Callback when condition is updated */
  onUpdate: (updates: Partial<FilterCondition>) => void
  /** Callback when condition is removed */
  onRemove: () => void
  /** Whether the condition is disabled */
  disabled?: boolean
}

/**
 * FilterConditionRow - A single row for editing a filter condition
 *
 * Displays field, operator, and value inputs inline in a horizontal row.
 * Uses specialized sub-components for each input type.
 */
export function FilterConditionRow({
  condition,
  groupId,
  onUpdate,
  onRemove,
  disabled = false
}: FilterConditionRowProps) {
  const [field, setField] = useState(condition.field)
  const [operator, setOperator] = useState(condition.operator)
  const [value, setValue] = useState(condition.value)

  // Sync local state when condition prop changes (e.g., loading from saved segment)
  useEffect(() => {
    setField(condition.field)
    setOperator(condition.operator)
    setValue(condition.value)
  }, [condition.id, condition.field, condition.operator, condition.value])

  // Get field configuration to determine available operators
  const fieldConfig = useMemo(() => {
    return DEFAULT_FILTER_FIELDS.find(f => f.key === field)
  }, [field])

  const fieldType = fieldConfig?.type

  // Handle field change
  const handleFieldChange = (newField: string) => {
    setField(newField)
    // Reset operator when field changes since different fields support different operators
    setOperator('equals')
    onUpdate({ field: newField, operator: 'equals', value: null })
  }

  // Handle operator change
  const handleOperatorChange = (newOperator: FilterOperator) => {
    setOperator(newOperator)
    // Clear value when switching to/from is_set/is_not_set operators
    if (newOperator === 'is_set' || newOperator === 'is_not_set') {
      setValue(null)
      onUpdate({ operator: newOperator, value: null })
    } else {
      onUpdate({ operator: newOperator })
    }
  }

  // Handle value change
  const handleValueChange = (newValue: string | number | boolean | null) => {
    setValue(newValue)
    onUpdate({ value: newValue })
  }

  // Show value input only for operators that require a value
  const showValueInput = operator !== 'is_set' && operator !== 'is_not_set'

  return (
    <div className="filter-condition flex items-center gap-2 p-2 rounded-md bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
      {/* Field Select */}
      <div className="flex-shrink-0 w-40">
        <FieldSelect
          value={field}
          onChange={handleFieldChange}
          disabled={disabled}
          className="filter-condition__field w-full"
          placeholder="Select field..."
        />
      </div>

      {/* Operator Select */}
      <div className="flex-shrink-0 w-44">
        <OperatorSelect
          value={operator}
          onChange={handleOperatorChange}
          fieldType={fieldType}
          isDisabled={disabled || !field}
          className="filter-condition__operator"
        />
      </div>

      {/* Value Input */}
      {showValueInput && (
        <div className="flex-1 min-w-0">
          <FilterValueInput
            field={field}
            operator={operator}
            value={value}
            onChange={handleValueChange}
            disabled={disabled}
            className="filter-condition__value w-full"
            placeholder="Enter value..."
          />
        </div>
      )}

      {/* Remove Button */}
      <button
        type="button"
        onClick={onRemove}
        disabled={disabled}
        className="flex-shrink-0 p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        title="Remove condition"
        aria-label="Remove condition"
      >
        <svg
          className="w-5 h-5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    </div>
  )
}

export default FilterConditionRow
