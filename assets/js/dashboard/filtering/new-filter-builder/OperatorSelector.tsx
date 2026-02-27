import React from 'react'
import { FILTER_OPERATIONS } from '../util/filters'
import type { FilterOperator } from './types'

interface OperatorSelectorProps {
  value: FilterOperator
  onChange: (operator: FilterOperator) => void
  dimension?: string
  className?: string
  'data-testid'?: string
}

const OPERATOR_OPTIONS = [
  { value: FILTER_OPERATIONS.is, label: 'is' },
  { value: FILTER_OPERATIONS.isNot, label: 'is not' },
  { value: FILTER_OPERATIONS.contains, label: 'contains' },
  { value: FILTER_OPERATIONS.contains_not, label: 'does not contain' },
  { value: 'matches', label: 'matches regex' },
  { value: 'does_not_match', label: 'does not match regex' },
  { value: 'is_set', label: 'is set' },
  { value: 'is_not_set', label: 'is not set' },
  { value: 'greater_than', label: 'greater than' },
  { value: 'less_than', label: 'less than' }
]

// Operators that don't require a value input
const NO_VALUE_OPERATORS = ['is_set', 'is_not_set']

export function OperatorSelector({
  value,
  onChange,
  className = '',
  'data-testid': dataTestId
}: OperatorSelectorProps) {
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange(e.target.value as FilterOperator)
  }

  return (
    <select
      className={`operator-selector ${className}`.trim()}
      value={value}
      onChange={handleChange}
      data-testid={dataTestId || 'operator-select'}
    >
      {OPERATOR_OPTIONS.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  )
}

// Helper function to check if operator requires value input
export function operatorRequiresValue(operator: FilterOperator | string): boolean {
  return !NO_VALUE_OPERATORS.includes(operator)
}

// Get all available operators
export function getOperatorOptions() {
  return OPERATOR_OPTIONS
}

// Get operator display label
export function getOperatorLabel(operator: FilterOperator): string {
  const found = OPERATOR_OPTIONS.find(opt => opt.value === operator)
  return found?.label || operator
}
