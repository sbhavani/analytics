import React from 'react'
import { FilterOperator, getSupportedOperators, getOperatorDisplayName, FilterDimension } from '../../types/filter-expression'

interface OperatorSelectorProps {
  value: FilterOperator
  dimension: FilterDimension
  onChange: (operator: FilterOperator) => void
  disabled?: boolean
}

export function OperatorSelector({ value, dimension, onChange, disabled }: OperatorSelectorProps) {
  const [isOpen, setIsOpen] = React.useState(false)
  const operators = getSupportedOperators(dimension)

  const handleSelect = (operator: FilterOperator) => {
    onChange(operator)
    setIsOpen(false)
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => !disabled && setIsOpen(!isOpen)}
        disabled={disabled}
        className="flex items-center justify-between w-full px-3 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span>{getOperatorDisplayName(value)}</span>
        <svg className="w-5 h-5 ml-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg">
          {operators.map((operator) => (
            <button
              key={operator}
              type="button"
              onClick={() => handleSelect(operator)}
              className={`w-full px-3 py-2 text-left text-sm hover:bg-gray-100 ${
                operator === value ? 'bg-indigo-50 text-indigo-700' : 'text-gray-900'
              }`}
            >
              {getOperatorDisplayName(operator)}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export default OperatorSelector
