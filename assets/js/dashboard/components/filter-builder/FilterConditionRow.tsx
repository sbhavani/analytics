import React, { useState, useMemo } from 'react'
import { TrashIcon, PencilIcon, CheckIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { FilterCondition, LogicalOperator, FilterOperator } from './types'
import { useFilterBuilderContext } from './filter-builder-context'
import FieldSelector, { VISITOR_ATTRIBUTES } from './FieldSelector'
import OperatorSelector, { OPERATORS } from './OperatorSelector'
import ValueInput from './ValueInput'
import AddGroupButton from './AddGroupButton'

interface FilterConditionRowProps {
  condition: FilterCondition
  index: number
  showOperator?: LogicalOperator
  isLast: boolean
  groupId?: string
}

// Helper to get field label from key
function getFieldLabel(fieldKey: string): string {
  const field = VISITOR_ATTRIBUTES.find(attr => attr.key === fieldKey)
  return field?.label || fieldKey
}

// Helper to get operator display text
function getOperatorLabel(operator: FilterOperator): string {
  const op = OPERATORS.find(o => o.value === operator)
  return op?.label || operator
}

// Format condition as readable summary
function formatConditionSummary(condition: FilterCondition): string {
  const fieldLabel = getFieldLabel(condition.field)
  const operatorLabel = getOperatorLabel(condition.operator)

  if (condition.operator === 'is_set' || condition.operator === 'is_not_set') {
    return `${fieldLabel} ${operatorLabel}`
  }

  return `${fieldLabel} ${operatorLabel} "${condition.value}"`
}

export default function FilterConditionRow({
  condition,
  index,
  showOperator,
  isLast,
  groupId
}: FilterConditionRowProps) {
  const { updateCondition, removeCondition, addCondition, addGroup } = useFilterBuilderContext()
  const [isEditing, setIsEditing] = useState(true)

  const handleFieldChange = (field: string) => {
    updateCondition(condition.id, { field, value: '' })
  }

  const handleOperatorChange = (operator: FilterCondition['operator']) => {
    updateCondition(condition.id, { operator })
  }

  const handleValueChange = (value: string | number | boolean) => {
    updateCondition(condition.id, { value })
  }

  const handleDelete = () => {
    removeCondition(condition.id)
  }

  const handleAddCondition = () => {
    addCondition(groupId || null)
  }

  const handleAddGroup = () => {
    addGroup(groupId || null)
  }

  const handleToggleEdit = () => {
    setIsEditing(!isEditing)
  }

  const needsValue = condition.operator !== 'is_set' && condition.operator !== 'is_not_set'

  // Format condition summary for view mode
  const conditionSummary = useMemo(
    () => formatConditionSummary(condition),
    [condition.field, condition.operator, condition.value]
  )

  // Determine if we can show view mode (condition has required data)
  const canShowViewMode = condition.field && (condition.operator === 'is_set' || condition.operator === 'is_not_set' || condition.value)

  return (
    <div className="relative">
      {/* Show logical operator before this condition (if not first) */}
      {index > 0 && showOperator && (
        <div className="absolute -top-3 left-1/2 transform -translate-x-1/2 z-10">
          <span
            className={classNames(
              'px-2 py-0.5 text-xs font-medium rounded',
              {
                'bg-blue-100 text-blue-700': showOperator === 'AND',
                'bg-purple-100 text-purple-700': showOperator === 'OR'
              }
            )}
          >
            {showOperator}
          </span>
        </div>
      )}

      {/* View Mode - Read-only summary */}
      {!isEditing && (
        <div
          className={classNames(
            'flex items-center justify-between gap-2 p-3 rounded-md mb-2',
            'bg-gray-50 border border-gray-200 hover:border-gray-300 transition-colors cursor-pointer',
            { 'min-h-[44px]': !canShowViewMode }
          )}
          onClick={handleToggleEdit}
        >
          <div className="flex-1 text-sm text-gray-700">
            {canShowViewMode ? (
              conditionSummary
            ) : (
              <span className="text-gray-400 italic">Click to edit condition</span>
            )}
          </div>

          <div className="flex items-center gap-1">
            {/* Edit button */}
            <button
              onClick={handleToggleEdit}
              className="p-1 text-gray-400 hover:text-blue-500 transition-colors"
              title="Edit condition"
            >
              <PencilIcon className="w-5 h-5" />
            </button>
            {/* Delete button */}
            <button
              onClick={handleDelete}
              className="p-1 text-gray-400 hover:text-red-500 transition-colors"
              title="Remove condition"
            >
              <TrashIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {/* Edit Mode - Full editing UI */}
      {isEditing && (
        <div
          className={classNames(
            'flex items-center gap-2 p-3 rounded-md mb-2',
            'bg-white border border-gray-200 hover:border-gray-300 transition-colors'
          )}
        >
          {/* Field selector */}
          <div className="w-40">
            <FieldSelector
              value={condition.field}
              onChange={handleFieldChange}
            />
          </div>

          {/* Operator selector */}
          <div className="w-32">
            <OperatorSelector
              value={condition.operator}
              onChange={handleOperatorChange}
              field={condition.field}
            />
          </div>

          {/* Value input */}
          {needsValue && (
            <div className="flex-1">
              <ValueInput
                value={condition.value}
                onChange={handleValueChange}
                field={condition.field}
                operator={condition.operator}
              />
            </div>
          )}

          {/* Action buttons */}
          <div className="flex items-center gap-1">
            {/* Done/View button */}
            {canShowViewMode && (
              <button
                onClick={handleToggleEdit}
                className="p-1 text-gray-400 hover:text-green-500 transition-colors"
                title="Done editing"
              >
                <CheckIcon className="w-5 h-5" />
              </button>
            )}
            {/* Delete button */}
            <button
              onClick={handleDelete}
              className="p-1 text-gray-400 hover:text-red-500 transition-colors"
              title="Remove condition"
            >
              <TrashIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      {/* Add buttons - show after last condition */}
      {isLast && (
        <div className="flex gap-2 mt-2">
          <button
            onClick={handleAddCondition}
            className="px-3 py-1 text-sm text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded transition-colors"
          >
            + Add condition
          </button>
          <AddGroupButton onClick={handleAddGroup} />
        </div>
      )}
    </div>
  )
}
