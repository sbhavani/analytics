/**
 * ConditionGroup Component
 *
 * Renders a group of filter conditions with AND/OR toggle selector
 */

import React from 'react'
import {
  FilterCondition,
  ConditionGroup as ConditionGroupType,
  LogicalOperator,
  FilterBuilderError
} from './types'
import { getConditionErrors } from './utils'

interface ConditionGroupProps {
  group: ConditionGroupType
  onAddCondition: (groupId: string) => void
  onUpdateCondition: (groupId: string, conditionId: string, updates: Partial<FilterCondition>) => void
  onRemoveCondition: (groupId: string, conditionId: string) => void
  onAddGroup: (parentGroupId: string) => void
  onUpdateGroupOperator: (groupId: string, operator: LogicalOperator) => void
  onRemoveGroup: (groupId: string) => void
  isRoot?: boolean
  errors?: FilterBuilderError[]
  conditionPath?: string
}

export function ConditionGroup({
  group,
  onAddCondition,
  onUpdateCondition,
  onRemoveCondition,
  onAddGroup,
  onUpdateGroupOperator,
  onRemoveGroup,
  isRoot = false,
  errors = [],
  conditionPath = ''
}: ConditionGroupProps) {
  return (
    <div className={`condition-group ${isRoot ? 'condition-group--root' : ''}`}>
      {/* Group Header with AND/OR Toggle Selector */}
      {!isRoot && (
        <div className="condition-group__header">
          <div className="condition-group__operator-toggle">
            <button
              type="button"
              className={`operator-btn ${group.operator === 'AND' ? 'operator-btn--active' : ''}`}
              onClick={() => onUpdateGroupOperator(group.id, 'AND')}
              aria-pressed={group.operator === 'AND'}
            >
              AND
            </button>
            <button
              type="button"
              className={`operator-btn ${group.operator === 'OR' ? 'operator-btn--active' : ''}`}
              onClick={() => onUpdateGroupOperator(group.id, 'OR')}
              aria-pressed={group.operator === 'OR'}
            >
              OR
            </button>
          </div>
          <button
            type="button"
            className="condition-group__remove-btn"
            onClick={() => onRemoveGroup(group.id)}
          >
            Remove Group
          </button>
        </div>
      )}

      {/* Conditions and Nested Groups */}
      <div className="condition-group__conditions">
        {group.conditions.map((condition, index) => {
          if ('field' in condition) {
            const conditionPathPrefix = `${conditionPath}/conditions/${index}`
            const conditionErrors = getConditionErrors(errors, conditionPathPrefix)
            return (
              <FilterConditionRow
                key={condition.id}
                condition={condition}
                groupId={group.id}
                errors={conditionErrors}
                conditionPath={conditionPathPrefix}
                onUpdate={(updates) => onUpdateCondition(group.id, condition.id, updates)}
                onRemove={() => onRemoveCondition(group.id, condition.id)}
              />
            )
          } else {
            const nestedPath = `${conditionPath}/conditions/${index}`
            return (
              <ConditionGroup
                key={condition.id}
                group={condition}
                onAddCondition={onAddCondition}
                onUpdateCondition={onUpdateCondition}
                onRemoveCondition={onRemoveCondition}
                onAddGroup={onAddGroup}
                onUpdateGroupOperator={onUpdateGroupOperator}
                onRemoveGroup={onRemoveGroup}
                isRoot={false}
                errors={errors}
                conditionPath={nestedPath}
              />
            )
          }
        })}
      </div>

      {/* Add Condition / Add Group Buttons */}
      <div className="condition-group__actions">
        <button
          type="button"
          className="condition-group__add-btn"
          onClick={() => onAddCondition(group.id)}
        >
          + Add Condition
        </button>
        <button
          type="button"
          className="condition-group__add-group-btn"
          onClick={() => onAddGroup(group.id)}
        >
          + Add Group
        </button>
      </div>
    </div>
  )
}

// Filter Condition Row Component
interface FilterConditionRowProps {
  condition: FilterCondition
  groupId: string
  errors?: FilterBuilderError[]
  conditionPath?: string
  onUpdate: (updates: Partial<FilterCondition>) => void
  onRemove: () => void
}

function FilterConditionRow({
  condition,
  errors = [],
  conditionPath = '',
  onUpdate,
  onRemove
}: FilterConditionRowProps) {
  const [field, setField] = React.useState(condition.field)
  const [operator, setOperator] = React.useState(condition.operator)
  const [value, setValue] = React.useState(condition.value)

  const handleFieldChange = (newField: string) => {
    setField(newField)
    onUpdate({ field: newField })
  }

  const handleOperatorChange = (newOperator: string) => {
    setOperator(newOperator as any)
    onUpdate({ operator: newOperator as any })
  }

  const handleValueChange = (newValue: string | number | boolean | null) => {
    setValue(newValue)
    onUpdate({ value: newValue })
  }

  const hasFieldError = errors.some((e) => e.path === `${conditionPath}/field`)
  const hasOperatorError = errors.some((e) => e.path === `${conditionPath}/operator`)
  const hasValueError = errors.some((e) => e.path === `${conditionPath}/value`)

  return (
    <div className={`filter-condition flex items-center gap-2 mb-2 ${errors.length > 0 ? 'bg-red-50 p-2 rounded' : ''}`}>
      <div className="filter-condition__field-wrapper flex-1">
        <select
          value={field}
          onChange={(e) => handleFieldChange(e.target.value)}
          className={`w-full px-2 py-1 border rounded ${hasFieldError ? 'border-red-500 bg-red-50' : 'border-gray-300'}`}
        >
          <option value="">Select field...</option>
          <option value="country">Country</option>
          <option value="region">Region</option>
          <option value="city">City</option>
          <option value="source">Source</option>
          <option value="referrer">Referrer</option>
          <option value="page">Page</option>
          <option value="entry_page">Entry Page</option>
          <option value="exit_page">Exit Page</option>
          <option value="hostname">Hostname</option>
          <option value="browser">Browser</option>
          <option value="os">Operating System</option>
          <option value="device">Device</option>
          <option value="screen_size">Screen Size</option>
          <option value="utm_medium">UTM Medium</option>
          <option value="utm_source">UTM Source</option>
          <option value="utm_campaign">UTM Campaign</option>
        </select>
        {hasFieldError && (
          <span className="text-red-600 text-xs block mt-1">
            {errors.find((e) => e.path === `${conditionPath}/field`)?.message}
          </span>
        )}
      </div>

      <div className="filter-condition__operator-wrapper flex-1">
        <select
          value={operator}
          onChange={(e) => handleOperatorChange(e.target.value)}
          className={`w-full px-2 py-1 border rounded ${hasOperatorError ? 'border-red-500 bg-red-50' : 'border-gray-300'}`}
        >
          <option value="equals">is</option>
          <option value="not_equals">is not</option>
          <option value="contains">contains</option>
          <option value="not_contains">does not contain</option>
          <option value="greater_than">is greater than</option>
          <option value="less_than">is less than</option>
          <option value="is_set">is set</option>
          <option value="is_not_set">is not set</option>
        </select>
        {hasOperatorError && (
          <span className="text-red-600 text-xs block mt-1">
            {errors.find((e) => e.path === `${conditionPath}/operator`)?.message}
          </span>
        )}
      </div>

      {operator !== 'is_set' && operator !== 'is_not_set' && (
        <div className="filter-condition__value-wrapper flex-1">
          <input
            type="text"
            value={(value as string) || ''}
            onChange={(e) => handleValueChange(e.target.value)}
            placeholder="Value..."
            className={`w-full px-2 py-1 border rounded ${hasValueError ? 'border-red-500 bg-red-50' : 'border-gray-300'}`}
          />
          {hasValueError && (
            <span className="text-red-600 text-xs block mt-1">
              {errors.find((e) => e.path === `${conditionPath}/value`)?.message}
            </span>
          )}
        </div>
      )}

      <button
        type="button"
        className="filter-condition__remove-btn text-red-500 hover:text-red-700 font-bold px-2"
        onClick={onRemove}
      >
        ×
      </button>
    </div>
  )
}

export default ConditionGroup
