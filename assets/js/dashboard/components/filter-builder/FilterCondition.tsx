import React from 'react'
import { FilterCondition as FilterConditionType, FilterOperator } from './types'
import { VISITOR_PROPERTIES, getOperatorsForProperty, getOperatorDisplayName } from './properties'
import { ValueInput } from './ValueInput'

interface FilterConditionProps {
  condition: FilterConditionType
  onChange: (condition: FilterConditionType) => void
  onRemove: () => void
}

export function FilterCondition({ condition, onChange, onRemove }: FilterConditionProps) {
  const availableOperators = getOperatorsForProperty(condition.property)

  const handlePropertyChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newProperty = e.target.value
    // Reset operator to first available for new property
    const newOperators = getOperatorsForProperty(newProperty)
    onChange({
      ...condition,
      property: newProperty,
      operator: newOperators[0] || 'equals',
      value: ''
    })
  }

  const handleOperatorChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({
      ...condition,
      operator: e.target.value as FilterOperator
    })
  }

  const handleValueChange = (value: string | string[]) => {
    onChange({
      ...condition,
      value
    })
  }

  return (
    <div className="flex flex-wrap items-center gap-2 p-2 bg-white rounded border border-gray-200">
      {/* Property Select */}
      <select
        value={condition.property}
        onChange={handlePropertyChange}
        className="px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
      >
        <option value="">Select property...</option>
        {VISITOR_PROPERTIES.map(prop => (
          <option key={prop.key} value={prop.key}>
            {prop.name}
          </option>
        ))}
      </select>

      {/* Operator Select */}
      <select
        value={condition.operator}
        onChange={handleOperatorChange}
        disabled={!condition.property}
        className="px-3 py-1.5 text-sm border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:bg-gray-100 disabled:cursor-not-allowed"
      >
        {availableOperators.map(op => (
          <option key={op} value={op}>
            {getOperatorDisplayName(op)}
          </option>
        ))}
      </select>

      {/* Value Input */}
      {condition.property && (
        <ValueInput
          property={condition.property}
          operator={condition.operator}
          value={condition.value}
          onChange={handleValueChange}
          disabled={!condition.property}
          placeholder="Enter value..."
        />
      )}

      {/* Remove Button */}
      <button
        onClick={onRemove}
        className="p-1.5 text-gray-400 hover:text-red-500 transition-colors"
        title="Remove condition"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}

export default FilterCondition
