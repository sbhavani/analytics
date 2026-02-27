import React from 'react'
import { VISITOR_FIELDS } from '../lib/filterBuilder/types'

interface OperatorSelectProps {
  field: string
  value: string
  onChange: (value: string) => void
  disabled?: boolean
}

const OPERATOR_LABELS: Record<string, string> = {
  equals: 'equals',
  does_not_equal: 'does not equal',
  contains: 'contains',
  does_not_contain: 'does not contain',
  is_one_of: 'is one of',
  is_not_one_of: 'is not one of',
  matches_regex: 'matches regex',
  not_equals: 'not equals',
  greater_than: 'greater than',
  less_than: 'less than',
  greater_or_equal: 'greater or equal',
  less_or_equal: 'less or equal',
  is_true: 'is true',
  is_false: 'is false',
}

export function OperatorSelect({ field, value, onChange, disabled }: OperatorSelectProps) {
  const fieldDef = VISITOR_FIELDS.find((f) => f.key === field)
  const operators = fieldDef?.operators || []

  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled || !field}
      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-100 disabled:opacity-50"
    >
      <option value="">Select operator...</option>
      {operators.map((op) => (
        <option key={op} value={op}>
          {OPERATOR_LABELS[op] || op}
        </option>
      ))}
    </select>
  )
}
