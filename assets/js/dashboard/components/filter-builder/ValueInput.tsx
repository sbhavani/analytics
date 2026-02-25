import React, { useState, useEffect } from 'react'
import { useSuggestions } from './useSuggestions'

interface ValueInputProps {
  value: string | number | boolean
  onChange: (value: string | number | boolean) => void
  field: string
  operator: string
}

export default function ValueInput({ value, onChange, field, operator }: ValueInputProps) {
  const [inputValue, setInputValue] = useState(String(value || ''))
  const { suggestions, isLoading, fetchSuggestions } = useSuggestions(field)

  useEffect(() => {
    setInputValue(String(value || ''))
  }, [value])

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    setInputValue(newValue)
    onChange(newValue)
  }

  const handleBlur = () => {
    // Fetch suggestions on blur if needed
    if (inputValue.length > 0) {
      fetchSuggestions(inputValue)
    }
  }

  // Determine if we should show suggestions
  const shouldShowSuggestions =
    field &&
    !['contains', 'contains_not'].includes(operator) &&
    inputValue.length > 0

  return (
    <div className="relative">
      <input
        type={getInputType(field)}
        value={inputValue}
        onChange={handleInputChange}
        onBlur={handleBlur}
        placeholder={`Enter ${field}...`}
        className="block w-full rounded-md border border-gray-300 py-2 px-3 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm"
        list={`${field}-suggestions`}
      />

      {/* Datalist for browser autocomplete */}
      {shouldShowSuggestions && suggestions.length > 0 && (
        <datalist id={`${field}-suggestions`}>
          {suggestions.map((suggestion, index) => (
            <option key={index} value={suggestion} />
          ))}
        </datalist>
      )}

      {/* Loading indicator */}
      {isLoading && (
        <div className="absolute right-2 top-2">
          <div className="animate-spin h-4 w-4 border-2 border-indigo-500 border-t-transparent rounded-full" />
        </div>
      )}
    </div>
  )
}

function getInputType(field: string): string {
  // Numeric fields
  if (['browser_version', 'os_version', 'screen'].includes(field)) {
    return 'number'
  }

  return 'text'
}
