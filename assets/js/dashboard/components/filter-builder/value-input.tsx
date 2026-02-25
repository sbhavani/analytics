import React from 'react'
import { FilterOperator, FilterDimension } from '../../types/filter-expression'

interface ValueInputProps {
  value: string | number | string[] | null
  onChange: (value: string | number | string[] | null) => void
  dimension: FilterDimension
  operator: FilterOperator
  disabled?: boolean
  suggestions?: string[]
}

const COUNTRY_SUGGESTIONS = [
  'US', 'GB', 'DE', 'FR', 'CA', 'AU', 'JP', 'BR', 'IN', 'IT',
  'ES', 'NL', 'SE', 'NO', 'CH', 'BE', 'AT', 'PL', 'MX', 'SG'
]

const DEVICE_SUGGESTIONS = ['Desktop', 'Mobile', 'Tablet']

const BROWSER_SUGGESTIONS = [
  'Chrome', 'Firefox', 'Safari', 'Edge', 'Opera', 'Samsung Internet', 'UC Browser'
]

const OS_SUGGESTIONS = [
  'Windows', 'Mac', 'Linux', 'Android', 'iOS', 'Chrome OS'
]

const SCREEN_SUGGESTIONS = ['Desktop', 'Mobile', 'Tablet']

export function ValueInput({ value, onChange, dimension, operator, disabled, suggestions = [] }: ValueInputProps) {
  const [inputValue, setInputValue] = React.useState('')
  const [isOpen, setIsOpen] = React.useState(false)

  React.useEffect(() => {
    if (value) {
      setInputValue(Array.isArray(value) ? value.join(', ') : String(value))
    } else {
      setInputValue('')
    }
  }, [value])

  // Don't show input for is-set and is-not-set operators
  if (operator === 'is-set' || operator === 'is-not-set') {
    return (
      <div className="px-3 py-2 text-sm text-gray-500 bg-gray-50 border border-gray-300 rounded-md">
        (Any value)
      </div>
    )
  }

  // Get suggestions based on dimension
  const getSuggestions = (): string[] => {
    if (suggestions.length > 0) return suggestions

    switch (dimension) {
      case 'country':
        return COUNTRY_SUGGESTIONS
      case 'device':
        return DEVICE_SUGGESTIONS
      case 'browser':
        return BROWSER_SUGGESTIONS
      case 'os':
        return OS_SUGGESTIONS
      case 'screen':
        return SCREEN_SUGGESTIONS
      default:
        return []
    }
  }

  const dimensionSuggestions = getSuggestions()
  const showSuggestions = dimensionSuggestions.length > 0 && operator === 'is'

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    setInputValue(newValue)
    onChange(newValue)
  }

  const handleSuggestionClick = (suggestion: string) => {
    setInputValue(suggestion)
    onChange(suggestion)
    setIsOpen(false)
  }

  return (
    <div className="relative flex-1">
      <input
        type="text"
        value={inputValue}
        onChange={handleInputChange}
        onFocus={() => showSuggestions && setIsOpen(true)}
        onBlur={() => setTimeout(() => setIsOpen(false), 200)}
        disabled={disabled}
        placeholder={`Enter ${dimension}...`}
        className="w-full px-3 py-2 text-sm text-gray-900 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
      />

      {showSuggestions && isOpen && dimensionSuggestions.length > 0 && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-48 overflow-y-auto">
          {dimensionSuggestions.map((suggestion) => (
            <button
              key={suggestion}
              type="button"
              onClick={() => handleSuggestionClick(suggestion)}
              className="w-full px-3 py-2 text-left text-sm hover:bg-gray-100 text-gray-900"
            >
              {suggestion}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export default ValueInput
