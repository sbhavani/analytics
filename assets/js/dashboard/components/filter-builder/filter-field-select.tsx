/**
 * FieldSelect Component
 *
 * Dropdown component for selecting a filter field in the Advanced Filter Builder
 */

import React from 'react'
import { DEFAULT_FILTER_FIELDS, FilterField } from './types'

interface FieldSelectProps {
  /** Currently selected field key */
  value: string
  /** Callback when field is selected */
  onChange: (fieldKey: string) => void
  /** Additional CSS classes */
  className?: string
  /** Whether the field select is disabled */
  disabled?: boolean
  /** Custom filter fields to use (optional, defaults to DEFAULT_FILTER_FIELDS) */
  fields?: FilterField[]
  /** Placeholder text when no field is selected */
  placeholder?: string
}

/**
 * FieldSelect dropdown component for choosing filter fields
 */
export function FieldSelect({
  value,
  onChange,
  className = '',
  disabled = false,
  fields = DEFAULT_FILTER_FIELDS,
  placeholder = 'Select field...'
}: FieldSelectProps) {
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange(e.target.value)
  }

  return (
    <select
      value={value}
      onChange={handleChange}
      disabled={disabled}
      className={`filter-field-select ${className}`.trim()}
    >
      <option value="" disabled>
        {placeholder}
      </option>
      {fields.map((field) => (
        <option key={field.key} value={field.key}>
          {field.name}
        </option>
      ))}
    </select>
  )
}

export default FieldSelect
