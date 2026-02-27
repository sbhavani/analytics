import React, { useState, useCallback } from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import type { FilterOperator } from './types'

// Operators that don't require a value input
const NO_VALUE_OPERATORS = ['is_set', 'is_not_set']

// Operators that work with numeric values
const NUMERIC_OPERATORS = ['greater_than', 'less_than']

// Dimension types that have predefined value options
const DIMENSION_VALUE_OPTIONS: Record<string, { value: string; label: string }[]> = {
  country: [
    { value: 'US', label: 'United States' },
    { value: 'GB', label: 'United Kingdom' },
    { value: 'DE', label: 'Germany' },
    { value: 'FR', label: 'France' },
    { value: 'CA', label: 'Canada' },
    { value: 'AU', label: 'Australia' },
    { value: 'JP', label: 'Japan' },
    { value: 'BR', label: 'Brazil' },
    { value: 'IN', label: 'India' },
    { value: 'CN', label: 'China' }
  ],
  browser: [
    { value: 'Chrome', label: 'Chrome' },
    { value: 'Firefox', label: 'Firefox' },
    { value: 'Safari', label: 'Safari' },
    { value: 'Edge', label: 'Edge' },
    { value: 'Opera', label: 'Opera' },
    { value: 'Brave', label: 'Brave' }
  ],
  os: [
    { value: 'Windows', label: 'Windows' },
    { value: 'macOS', label: 'macOS' },
    { value: 'Linux', label: 'Linux' },
    { value: 'Android', label: 'Android' },
    { value: 'iOS', label: 'iOS' }
  ],
  screen: [
    { value: 'Mobile', label: 'Mobile' },
    { value: 'Tablet', label: 'Tablet' },
    { value: 'Desktop', label: 'Desktop' }
  ]
}

interface FilterValueInputProps {
  conditionId: string
  dimension: string
  operator: FilterOperator
  values: string[]
  onChange?: (values: string[]) => void
}

export function FilterValueInput({
  conditionId,
  dimension,
  operator,
  values,
  onChange
}: FilterValueInputProps) {
  const { updateCondition } = useFilterBuilder()
  const [inputValue, setInputValue] = useState(values[0] || '')

  const handleValueChange = useCallback(
    (newValue: string) => {
      setInputValue(newValue)
      const updatedValues = newValue ? [newValue] : []
      updateCondition(conditionId, { values: updatedValues })
      onChange?.(updatedValues)
    },
    [conditionId, updateCondition, onChange]
  )

  const handleSelectChange = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      const newValue = e.target.value
      updateCondition(conditionId, { values: [newValue] })
      setInputValue(newValue)
      onChange?.([newValue])
    },
    [conditionId, updateCondition, onChange]
  )

  const handleMultiValueAdd = useCallback(
    (e: React.KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter' || e.key === ',') {
        e.preventDefault()
        if (inputValue.trim()) {
          const newValues = [...values, inputValue.trim()]
          updateCondition(conditionId, { values: newValues })
          setInputValue('')
          onChange?.(newValues)
        }
      }
    },
    [conditionId, inputValue, onChange, updateCondition, values]
  )

  const handleMultiValueRemove = useCallback(
    (indexToRemove: number) => {
      const newValues = values.filter((_, index) => index !== indexToRemove)
      updateCondition(conditionId, { values: newValues })
      onChange?.(newValues)
    },
    [conditionId, onChange, updateCondition, values]
  )

  // Don't render input for operators that don't need values
  if (NO_VALUE_OPERATORS.includes(operator)) {
    return (
      <span className="filter-value-input__no-value" data-testid="no-value-indicator">
        (any value)
      </span>
    )
  }

  // Use dropdown for certain dimensions
  const dimensionOptions = DIMENSION_VALUE_OPTIONS[dimension]
  const useSelectDropdown = dimensionOptions && operator === 'is'

  // Use number input for numeric operators
  const useNumberInput = NUMERIC_OPERATORS.includes(operator)

  // Support multiple values for "is" operator
  const useMultiValue = operator === 'is' && !useSelectDropdown

  if (useSelectDropdown) {
    return (
      <div className="filter-value-input filter-value-input--select" data-testid="value-select">
        <select
          value={values[0] || ''}
          onChange={handleSelectChange}
          className="filter-value-input__select"
          data-testid="value-dropdown"
        >
          <option value="">Select value</option>
          {dimensionOptions.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
    )
  }

  if (useNumberInput) {
    return (
      <div className="filter-value-input filter-value-input--number" data-testid="value-number-input">
        <input
          type="number"
          value={values[0] || ''}
          onChange={(e) => handleValueChange(e.target.value)}
          placeholder="Enter number"
          className="filter-value-input__number"
          data-testid="value-input"
          step="any"
        />
      </div>
    )
  }

  if (useMultiValue) {
    return (
      <div className="filter-value-input filter-value-input--multi" data-testid="value-multi-input">
        <div className="filter-value-input__tags">
          {values.map((value, index) => (
            <span key={`${value}-${index}`} className="filter-value-input__tag">
              {value}
              <button
                type="button"
                className="filter-value-input__tag-remove"
                onClick={() => handleMultiValueRemove(index)}
                data-testid="remove-tag"
                aria-label={`Remove ${value}`}
              >
                ×
              </button>
            </span>
          ))}
        </div>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyDown={handleMultiValueAdd}
          placeholder={values.length === 0 ? 'Enter value and press Enter' : 'Add another...'}
          className="filter-value-input__multi"
          data-testid="value-input"
        />
      </div>
    )
  }

  // Default: text input
  return (
    <div className="filter-value-input filter-value-input--text" data-testid="value-text-input">
      <input
        type="text"
        value={values[0] || ''}
        onChange={(e) => handleValueChange(e.target.value)}
        placeholder="Enter value"
        className="filter-value-input__text"
        data-testid="value-input"
      />
    </div>
  )
}

// Helper function to check if operator needs a value input
export function operatorNeedsValue(operator: FilterOperator): boolean {
  return !NO_VALUE_OPERATORS.includes(operator)
}

// Helper function to get suggested values for a dimension
export function getDimensionSuggestions(dimension: string): { value: string; label: string }[] {
  return DIMENSION_VALUE_OPTIONS[dimension] || []
}
