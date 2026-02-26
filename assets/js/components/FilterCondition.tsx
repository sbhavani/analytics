import React from 'react'

export interface FilterField {
  name: string
  displayName: string
  dataType: 'string' | 'number' | 'date'
  operators: string[]
  options?: string[]
}

export interface FilterConditionData {
  id: string
  field: string
  operator: string
  value: string
}

export interface ValidationError {
  conditionId?: string
  field?: string
  message: string
}

interface FilterConditionProps {
  condition: FilterConditionData
  availableFields: FilterField[]
  onUpdate: (updates: Partial<FilterConditionData>) => void
  onRemove: () => void
  error?: ValidationError | null
}

const OPERATOR_LABELS: Record<string, string> = {
  equals: 'equals',
  not_equals: 'does not equal',
  greater_than: 'is greater than',
  less_than: 'is less than',
  contains: 'contains',
  is_empty: 'is empty',
  is_not_empty: 'is not empty'
}

export function FilterCondition({ condition, availableFields, onUpdate, onRemove, error }: FilterConditionProps) {
  const currentField = availableFields.find(f => f.name === condition.field)

  const handleFieldChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newField = e.target.value
    const field = availableFields.find(f => f.name === newField)
    onUpdate({
      field: newField,
      operator: field?.operators[0] || '',
      value: ''
    })
  }

  const handleOperatorChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onUpdate({ operator: e.target.value })
  }

  const handleValueChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    onUpdate({ value: e.target.value })
  }

  const needsValue = !['is_empty', 'is_not_empty'].includes(condition.operator)

  const hasFieldError = error?.field === 'field'
  const hasOperatorError = error?.field === 'operator'
  const hasValueError = error?.field === 'value'

  return (
    <div className={`filter-condition flex items-center gap-2 py-2 ${error ? 'bg-red-50 rounded-md -mx-2 px-2' : ''}`} role="group" aria-label="Filter condition">
      <select
        value={condition.field}
        onChange={handleFieldChange}
        className={`field-select px-3 py-2 border rounded-md bg-white text-sm ${hasFieldError ? 'border-red-500 ring-1 ring-red-500' : ''}`}
        aria-label="Filter field"
        aria-invalid={hasFieldError}
      >
        <option value="">Select field...</option>
        {availableFields.map(field => (
          <option key={field.name} value={field.name}>
            {field.displayName}
          </option>
        ))}
      </select>

      <select
        value={condition.operator}
        onChange={handleOperatorChange}
        className={`operator-select px-3 py-2 border rounded-md bg-white text-sm ${hasOperatorError ? 'border-red-500 ring-1 ring-red-500' : ''}`}
        aria-label="Operator"
        aria-invalid={hasOperatorError}
        disabled={!condition.field}
      >
        {currentField?.operators.map(op => (
          <option key={op} value={op}>
            {OPERATOR_LABELS[op] || op}
          </option>
        ))}
      </select>

      {needsValue && (
        currentField?.options ? (
          <select
            value={condition.value}
            onChange={handleValueChange}
            className={`value-select px-3 py-2 border rounded-md bg-white text-sm flex-1 ${hasValueError ? 'border-red-500 ring-1 ring-red-500' : ''}`}
            aria-label="Value"
            aria-invalid={hasValueError}
            disabled={!condition.operator}
          >
            <option value="">Select...</option>
            {currentField.options.map(opt => (
              <option key={opt} value={opt}>
                {opt}
              </option>
            ))}
          </select>
        ) : (
          <input
            type={currentField?.dataType === 'number' ? 'number' : 'text'}
            value={condition.value}
            onChange={handleValueChange}
            className={`value-input px-3 py-2 border rounded-md bg-white text-sm flex-1 ${hasValueError ? 'border-red-500 ring-1 ring-red-500' : ''}`}
            placeholder={currentField?.dataType === 'number' ? 'Enter number...' : 'Enter value...'}
            aria-label="Value"
            aria-invalid={hasValueError}
            disabled={!condition.operator}
          />
        )
      )}

      {error && (
        <span className="text-xs text-red-600" role="alert">
          {error.message}
        </span>
      )}

      <button
        onClick={onRemove}
        className="remove-btn p-2 text-gray-400 hover:text-red-500 rounded-md"
        aria-label="Remove condition"
        title="Remove condition"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}
