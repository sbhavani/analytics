import React, { useState, useEffect } from 'react'
import { FilterOperator } from './types'
import { getPropertyType } from './properties'

interface ValueInputProps {
  property: string
  operator: FilterOperator
  value: string | string[]
  onChange: (value: string | string[]) => void
  disabled?: boolean
  placeholder?: string
}

/**
 * Type-aware input component for filter values
 * Handles string, numeric, and list (is_one_of) property types
 */
export function ValueInput({
  property,
  operator,
  value,
  onChange,
  disabled = false,
  placeholder = 'Enter value...'
}: ValueInputProps) {
  const [inputValue, setInputValue] = useState('')
  const [listValues, setListValues] = useState<string[]>([])

  const propertyType = getPropertyType(property)
  const isListOperator = operator === 'is_one_of'

  // Sync internal state with external value prop
  useEffect(() => {
    if (isListOperator && Array.isArray(value)) {
      setListValues(value)
    } else if (typeof value === 'string') {
      setInputValue(value)
    }
  }, [value, isListOperator])

  // Handle text/number input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    setInputValue(newValue)
    onChange(newValue)
  }

  // Handle list input changes (comma-separated values)
  const handleListInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value
    setInputValue(input)

    // Parse comma-separated values
    const parsed = input
      .split(',')
      .map(v => v.trim())
      .filter(v => v.length > 0)

    setListValues(parsed)
    onChange(parsed)
  }

  // Handle blur for list input to finalize values
  const handleListBlur = () => {
    // Filter out empty values and update
    const finalValues = listValues.filter(v => v.length > 0)
    setListValues(finalValues)
    onChange(finalValues)
    setInputValue(finalValues.join(', '))
  }

  // Render numeric input
  if (propertyType === 'numeric') {
    return (
      <input
        type="number"
        value={inputValue}
        onChange={handleInputChange}
        disabled={disabled}
        placeholder={placeholder}
        className="flex-1 min-w-[120px] px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
      />
    )
  }

  // Render list input for is_one_of operator
  if (isListOperator) {
    return (
      <div className="flex-1 min-w-[200px]">
        <input
          type="text"
          value={inputValue}
          onChange={handleListInputChange}
          onBlur={handleListBlur}
          disabled={disabled}
          placeholder="Enter values separated by commas..."
          className="w-full px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
        />
        {listValues.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-1">
            {listValues.map((val, index) => (
              <span
                key={index}
                className="inline-flex items-center px-2 py-0.5 text-xs bg-indigo-100 text-indigo-800 rounded"
              >
                {val}
              </span>
            ))}
          </div>
        )}
      </div>
    )
  }

  // Default: render text input for string properties
  return (
    <input
      type="text"
      value={inputValue}
      onChange={handleInputChange}
      disabled={disabled}
      placeholder={placeholder}
      className="flex-1 min-w-[120px] px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
    />
  )
}

export default ValueInput
