/**
 * FilterValueInput Component
 *
 * A reusable component for inputting filter values based on field type and operator.
 * Supports string, number, boolean, and enum field types.
 */

import React, { useState, useEffect, useMemo } from 'react'
import {
  FilterOperator,
  FilterField,
  DEFAULT_FILTER_FIELDS,
  OPERATORS_BY_FIELD_TYPE
} from './types'

interface FilterValueInputProps {
  /** Current field key */
  field: string
  /** Current operator */
  operator: FilterOperator
  /** Current value */
  value: string | number | boolean | null
  /** Callback when value changes */
  onChange: (value: string | number | boolean | null) => void
  /** Optional CSS class name */
  className?: string
  /** Optional placeholder text */
  placeholder?: string
  /** Optional disabled state */
  disabled?: boolean
}

/**
 * Get field configuration by key
 */
function getFieldConfig(fieldKey: string): FilterField | undefined {
  return DEFAULT_FILTER_FIELDS.find(f => f.key === fieldKey)
}

/**
 * FilterValueInput Component
 */
export function FilterValueInput({
  field,
  operator,
  value,
  onChange,
  className = '',
  placeholder = 'Value...',
  disabled = false
}: FilterValueInputProps) {
  const [inputValue, setInputValue] = useState<string>('')

  // Get field configuration
  const fieldConfig = useMemo(() => getFieldConfig(field), [field])
  const fieldType = fieldConfig?.type

  // Update internal state when external value changes
  useEffect(() => {
    if (value === null || value === undefined) {
      setInputValue('')
    } else {
      setInputValue(String(value))
    }
  }, [value])

  // For is_set and is_not_set operators, don't show any input
  const showValueInput = operator !== 'is_set' && operator !== 'is_not_set'

  // Handle text input change
  const handleTextChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    setInputValue(newValue)

    // Convert based on field type
    if (fieldType === 'number') {
      const numValue = parseFloat(newValue)
      onChange(isNaN(numValue) ? null : numValue)
    } else {
      onChange(newValue || null)
    }
  }

  // Handle select change (for enum fields)
  const handleSelectChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newValue = e.target.value
    onChange(newValue || null)
  }

  // Render boolean input
  if (fieldType === 'boolean') {
    return (
      <select
        value={value === null ? '' : String(value)}
        onChange={handleSelectChange}
        className={`filter-value-input filter-value-input--boolean ${className}`}
        disabled={disabled}
      >
        <option value="">Select...</option>
        <option value="true">True</option>
        <option value="false">False</option>
      </select>
    )
  }

  // Render enum input (dropdown)
  if (fieldType === 'enum' && showValueInput) {
    return (
      <select
        value={value === null ? '' : String(value)}
        onChange={handleSelectChange}
        className={`filter-value-input filter-value-input--enum ${className}`}
        disabled={disabled}
      >
        <option value="">Select {fieldConfig?.name || field}...</option>
        {getEnumOptions(field).map(option => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    )
  }

  // Render number input
  if (fieldType === 'number' && showValueInput) {
    return (
      <input
        type="number"
        value={inputValue}
        onChange={handleTextChange}
        placeholder={placeholder}
        className={`filter-value-input filter-value-input--number ${className}`}
        disabled={disabled}
        step="any"
      />
    )
  }

  // Render string input (default)
  if (showValueInput) {
    return (
      <input
        type="text"
        value={inputValue}
        onChange={handleTextChange}
        placeholder={placeholder}
        className={`filter-value-input filter-value-input--string ${className}`}
        disabled={disabled}
      />
    )
  }

  // For is_set/is_not_set, render a hidden input or null
  return null
}

/**
 * Get available options for enum fields
 */
function getEnumOptions(field: string): Array<{ value: string; label: string }> {
  // These options should match the backend filter options
  // In a real implementation, these would likely come from an API or configuration
  const enumOptions: Record<string, Array<{ value: string; label: string }>> = {
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
      { value: 'ES', label: 'Spain' },
      { value: 'IT', label: 'Italy' },
      { value: 'NL', label: 'Netherlands' },
      { value: 'PL', label: 'Poland' },
      { value: 'SE', label: 'Sweden' },
      { value: 'CH', label: 'Switzerland' },
      { value: 'BE', label: 'Belgium' },
      { value: 'AT', label: 'Austria' },
      { value: 'IE', label: 'Ireland' },
      { value: 'NO', label: 'Norway' },
      { value: 'DK', label: 'Denmark' },
      { value: 'FI', label: 'Finland' },
      { value: 'PT', label: 'Portugal' },
      { value: 'CZ', label: 'Czech Republic' },
      { value: 'RO', label: 'Romania' },
      { value: 'HU', label: 'Hungary' },
      { value: 'GR', label: 'Greece' },
      { value: 'SK', label: 'Slovakia' },
      { value: 'BG', label: 'Bulgaria' },
      { value: 'HR', label: 'Croatia' },
      { value: 'SI', label: 'Slovenia' }
    ],
    browser: [
      { value: 'Chrome', label: 'Chrome' },
      { value: 'Firefox', label: 'Firefox' },
      { value: 'Safari', label: 'Safari' },
      { value: 'Edge', label: 'Edge' },
      { value: 'Opera', label: 'Opera' },
      { value: 'Brave', label: 'Brave' },
      { value: 'IE', label: 'Internet Explorer' },
      { value: 'Samsung Browser', label: 'Samsung Browser' },
      { value: 'UC Browser', label: 'UC Browser' },
      { value: 'Other', label: 'Other' }
    ],
    os: [
      { value: 'Windows', label: 'Windows' },
      { value: 'macOS', label: 'macOS' },
      { value: 'Linux', label: 'Linux' },
      { value: 'iOS', label: 'iOS' },
      { value: 'Android', label: 'Android' },
      { value: 'Chrome OS', label: 'Chrome OS' },
      { value: 'FreeBSD', label: 'FreeBSD' },
      { value: 'Other', label: 'Other' }
    ],
    device: [
      { value: 'Desktop', label: 'Desktop' },
      { value: 'Mobile', label: 'Mobile' },
      { value: 'Tablet', label: 'Tablet' },
      { value: 'Other', label: 'Other' }
    ],
    screen_size: [
      { value: 'desktop', label: 'Desktop' },
      { value: 'laptop', label: 'Laptop' },
      { value: 'tablet', label: 'Tablet' },
      { value: 'mobile', label: 'Mobile' },
      { value: 'other', label: 'Other' }
    ]
  }

  return enumOptions[field] || []
}

/**
 * Hook to get available operators for a field
 */
export function useFieldOperators(field: string): FilterOperator[] {
  const fieldConfig = useMemo(() => getFieldConfig(field), [field])

  if (!fieldConfig) {
    return OPERATORS_BY_FIELD_TYPE.string
  }

  if (fieldConfig.supportedOperators) {
    return fieldConfig.supportedOperators
  }

  return OPERATORS_BY_FIELD_TYPE[fieldConfig.type] || OPERATORS_BY_FIELD_TYPE.string
}

export default FilterValueInput
