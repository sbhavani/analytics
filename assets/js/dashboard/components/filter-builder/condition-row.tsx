import React from 'react'
import { FilterCondition, FilterDimension, FilterOperator, createFilterCondition } from '../../types/filter-expression'
import DimensionSelector from './dimension-selector'
import OperatorSelector from './operator-selector'
import ValueInput from './value-input'
import ConditionConnector from './condition-connector'

interface ConditionRowProps {
  condition: FilterCondition
  onChange: (condition: FilterCondition) => void
  onDelete: () => void
  onEdit?: () => void
  isEditing?: boolean
  isLast?: boolean
  connector?: 'AND' | 'OR'
  onConnectorChange?: (connector: 'AND' | 'OR') => void
}

export function ConditionRow({
  condition,
  onChange,
  onDelete,
  isEditing = true,
  isLast = false,
  connector,
  onConnectorChange
}: ConditionRowProps) {
  const handleDimensionChange = (dimension: FilterDimension) => {
    onChange({ ...condition, dimension })
  }

  const handleOperatorChange = (operator: FilterOperator) => {
    onChange({ ...condition, operator })
  }

  const handleValueChange = (value: string | number | string[] | null) => {
    onChange({ ...condition, value })
  }

  return (
    <div className="flex flex-col space-y-2">
      {/* Connector between conditions */}
      {connector && !isLast && (
        <ConditionConnector
          connector={connector}
          onChange={onConnectorChange}
        />
      )}

      {/* Condition row */}
      <div className="flex items-start space-x-2 p-3 bg-white border border-gray-200 rounded-lg">
        <div className="flex-1 grid grid-cols-1 sm:grid-cols-3 gap-2">
          <DimensionSelector
            value={condition.dimension}
            onChange={handleDimensionChange}
            disabled={!isEditing}
          />
          <OperatorSelector
            value={condition.operator}
            dimension={condition.dimension}
            onChange={handleOperatorChange}
            disabled={!isEditing}
          />
          <ValueInput
            value={condition.value}
            onChange={handleValueChange}
            dimension={condition.dimension}
            operator={condition.operator}
            disabled={!isEditing}
          />
        </div>

        {/* Delete button */}
        <button
          type="button"
          onClick={onDelete}
          className="p-2 text-gray-400 hover:text-red-500 transition-colors"
          title="Remove condition"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  )
}

export default ConditionRow
