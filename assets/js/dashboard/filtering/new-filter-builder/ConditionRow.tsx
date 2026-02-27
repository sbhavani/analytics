import React from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import { FILTER_MODAL_TO_FILTER_GROUP, FILTER_OPERATIONS } from '../util/filters'
import type { FilterCondition, FilterOperator } from './types'

interface ConditionRowProps {
  condition: FilterCondition
  groupId: string
}

const DIMENSION_OPTIONS = Object.entries(FILTER_MODAL_TO_FILTER_GROUP).flatMap(
  ([category, dimensions]) =>
    dimensions.map((dim) => ({
      value: dim,
      label: dim.charAt(0).toUpperCase() + dim.slice(1).replace('_', ' ')
    }))
)

const OPERATOR_OPTIONS = [
  { value: FILTER_OPERATIONS.is, label: 'is' },
  { value: FILTER_OPERATIONS.isNot, label: 'is not' },
  { value: FILTER_OPERATIONS.contains, label: 'contains' },
  { value: FILTER_OPERATIONS.contains_not, label: 'does not contain' },
  { value: 'matches', label: 'matches regex' },
  { value: 'is_set', label: 'is set' },
  { value: 'is_not_set', label: 'is not set' },
  { value: 'greater_than', label: 'greater than' },
  { value: 'less_than', label: 'less than' }
]

export function ConditionRow({ condition, groupId }: ConditionRowProps) {
  const { updateCondition, removeItem } = useFilterBuilder()

  const handleDimensionChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    updateCondition(condition.id, { dimension: e.target.value })
  }

  const handleOperatorChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    updateCondition(condition.id, { operator: e.target.value as FilterOperator })
  }

  const handleValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    updateCondition(condition.id, { values: value ? [value] : [] })
  }

  const handleRemove = () => {
    removeItem(condition.id)
  }

  const needsValue = !['is_set', 'is_not_set'].includes(condition.operator)

  return (
    <div className="condition-row" data-testid="condition-row" data-condition-id={condition.id}>
      <select
        className="condition-row__dimension"
        value={condition.dimension}
        onChange={handleDimensionChange}
        data-testid="dimension-select"
      >
        <option value="">Select dimension</option>
        {DIMENSION_OPTIONS.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>

      <select
        className="condition-row__operator"
        value={condition.operator}
        onChange={handleOperatorChange}
        data-testid="operator-select"
      >
        {OPERATOR_OPTIONS.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>

      {needsValue && (
        <input
          type="text"
          className="condition-row__value"
          value={condition.values[0] || ''}
          onChange={handleValueChange}
          placeholder="Enter value"
          data-testid="value-input"
        />
      )}

      <button
        type="button"
        className="condition-row__remove"
        onClick={handleRemove}
        title="Remove filter"
        data-testid="remove-button"
      >
        ×
      </button>
    </div>
  )
}
