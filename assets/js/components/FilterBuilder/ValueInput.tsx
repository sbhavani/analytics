import React from 'react'
import { VISITOR_FIELDS, DEVICE_OPTIONS } from '../lib/filterBuilder/types'
import { getOperatorType } from '../lib/filterBuilder/filterValidator'

interface ValueInputProps {
  field: string
  operator: string
  value: string
  onChange: (value: string) => void
  disabled?: boolean
}

export function ValueInput({ field, operator, value, onChange, disabled }: ValueInputProps) {
  if (!field || !operator) {
    return (
      <input
        type="text"
        value=""
        disabled
        placeholder="Select field and operator first"
        className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm bg-gray-100 dark:bg-gray-700 dark:border-gray-600"
      />
    )
  }

  const fieldDef = VISITOR_FIELDS.find((f) => f.key === field)
  const fieldType = getOperatorType(operator)
  const isMultiValue = operator === 'is_one_of' || operator === 'is_not_one_of'
  const isBoolean = operator === 'is_true' || operator === 'is_false'

  if (fieldType === 'boolean' || isBoolean) {
    return (
      <div className="flex items-center">
        <span className="text-sm text-gray-500 dark:text-gray-400">
          {operator === 'is_true' ? 'True' : operator === 'is_false' ? 'False' : 'Yes/No'}
        </span>
      </div>
    )
  }

  if (fieldType === 'set' || field.key === 'device') {
    return (
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        multiple={isMultiValue}
        className={`w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-100 disabled:opacity-50 ${isMultiValue ? 'h-24' : ''}`}
      >
        <option value="">{isMultiValue ? 'Select options...' : 'Select value...'}</option>
        {DEVICE_OPTIONS.map((device) => (
          <option key={device} value={device}>
            {device}
          </option>
        ))}
      </select>
    )
  }

  if (fieldType === 'number') {
    return (
      <input
        type="number"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        placeholder="Enter number..."
        className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-100 disabled:opacity-50"
      />
    )
  }

  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      placeholder={isMultiValue ? 'Enter values separated by commas...' : 'Enter value...'}
      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-100 disabled:opacity-50"
    />
  )
}
