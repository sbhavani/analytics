import React from 'react'
import { VISITOR_FIELDS } from '../lib/filterBuilder/types'

interface FieldSelectProps {
  value: string
  onChange: (value: string) => void
  disabled?: boolean
}

export function FieldSelect({ value, onChange, disabled }: FieldSelectProps) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-100 disabled:opacity-50"
    >
      <option value="">Select field...</option>
      {VISITOR_FIELDS.map((field) => (
        <option key={field.key} value={field.key}>
          {field.label}
        </option>
      ))}
    </select>
  )
}
