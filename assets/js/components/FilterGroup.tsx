import React, { useState } from 'react'
import { FilterCondition, FilterConditionData, FilterField, ValidationError } from './FilterCondition'

export interface FilterGroupData {
  id: string
  operator: 'AND' | 'OR'
  conditions: FilterConditionData[]
  groups: FilterGroupData[]
}

interface FilterGroupProps {
  group: FilterGroupData
  level: number
  availableFields: FilterField[]
  onAddCondition: () => void
  onRemoveCondition: (conditionId: string) => void
  onUpdateCondition: (conditionId: string, updates: Partial<FilterConditionData>) => void
  onChangeOperator: (operator: 'AND' | 'OR') => void
  onAddGroup: () => void
  onRemoveGroup: () => void
  // Nested group handlers
  onAddNestedGroup?: (parentGroupId: string) => void
  onRemoveNestedGroup?: (parentGroupId: string, nestedGroupId: string) => void
  onUpdateNestedGroup?: (parentGroupId: string, nestedGroupId: string, updates: Partial<FilterGroupData>) => void
  // Validation errors for conditions
  validationErrors?: ValidationError[]
}

const MAX_NESTING_LEVEL = 3

export function FilterGroup({
  group,
  level,
  availableFields,
  onAddCondition,
  onRemoveCondition,
  onUpdateCondition,
  onChangeOperator,
  onAddGroup,
  onRemoveGroup,
  onAddNestedGroup,
  onRemoveNestedGroup,
  onUpdateNestedGroup,
  validationErrors = []
}: FilterGroupProps) {
  const [isExpanded, setIsExpanded] = useState(true)
  const canNest = level < MAX_NESTING_LEVEL

  // Get error for a specific condition
  const getConditionError = (conditionId: string): ValidationError | undefined => {
    return validationErrors.find(e => e.conditionId === conditionId)
  }

  const handleOperatorToggle = () => {
    onChangeOperator(group.operator === 'AND' ? 'OR' : 'AND')
  }

  const connectorLabel = group.operator === 'AND' ? 'AND' : 'OR'

  return (
    <div
      className={`filter-group border rounded-lg p-4 ${level > 0 ? 'ml-6 border-l-4' : ''}`}
      role="group"
      aria-label={`Filter group level ${level + 1}`}
    >
      {/* Group Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          {level > 0 && (
            <button
              onClick={() => setIsExpanded(!isExpanded)}
              className="expand-btn p-1 text-gray-500 hover:text-gray-700"
              aria-expanded={isExpanded}
              aria-label={isExpanded ? 'Collapse group' : 'Expand group'}
            >
              <svg
                className={`w-4 h-4 transition-transform ${isExpanded ? 'rotate-90' : ''}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          )}

          <span className="text-sm font-medium text-gray-600">
            {level === 0 ? 'Filter conditions' : `Group ${level + 1}`}
          </span>
        </div>

        <div className="flex items-center gap-2">
          {/* AND/OR Toggle */}
          {group.conditions.length > 1 && (
            <div className="flex rounded-md shadow-sm" role="group" aria-label="Operator toggle">
              <button
                onClick={handleOperatorToggle}
                className={`px-3 py-1 text-sm rounded-l-md ${
                  group.operator === 'AND'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
                aria-pressed={group.operator === 'AND'}
              >
                AND
              </button>
              <button
                onClick={handleOperatorToggle}
                className={`px-3 py-1 text-sm rounded-r-md ${
                  group.operator === 'OR'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
                aria-pressed={group.operator === 'OR'}
              >
                OR
              </button>
            </div>
          )}

          {/* Remove group button (only for nested groups) */}
          {level > 0 && (
            <button
              onClick={onRemoveGroup}
              className="p-1 text-gray-400 hover:text-red-500"
              aria-label="Remove group"
              title="Remove group"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {/* Group Content */}
      {isExpanded && (
        <div className="space-y-2">
          {/* Conditions */}
          {group.conditions.map((condition, index) => (
            <React.Fragment key={condition.id}>
              {index > 0 && (
                <div className="flex items-center gap-2 py-1">
                  <span className="text-xs font-medium text-gray-500 px-2">
                    {connectorLabel}
                  </span>
                </div>
              )}
              <FilterCondition
                condition={condition}
                availableFields={availableFields}
                onUpdate={(updates) => onUpdateCondition(condition.id, updates)}
                onRemove={() => onRemoveCondition(condition.id)}
                error={getConditionError(condition.id)}
              />
            </React.Fragment>
          ))}

          {/* Nested Groups */}
          {group.groups.map((nestedGroup, index) => (
            <React.Fragment key={nestedGroup.id}>
              {index > 0 || group.conditions.length > 0 ? (
                <div className="flex items-center gap-2 py-1">
                  <span className="text-xs font-medium text-gray-500 px-2">
                    {connectorLabel}
                  </span>
                </div>
              ) : null}
              <FilterGroup
                group={nestedGroup}
                level={level + 1}
                availableFields={availableFields}
                onAddCondition={() => onAddNestedGroup?.(nestedGroup.id)}
                onRemoveCondition={(conditionId) => onRemoveNestedGroup?.(nestedGroup.id, conditionId)}
                onUpdateCondition={(conditionId, updates) => onUpdateNestedGroup?.(nestedGroup.id, conditionId, { conditions: nestedGroup.conditions.map(c => c.id === conditionId ? { ...c, ...updates } : c) } as Partial<FilterGroupData>)}
                onChangeOperator={(operator) => onUpdateNestedGroup?.(nestedGroup.id, nestedGroup.id, { operator } as Partial<FilterGroupData>)}
                onAddGroup={() => onAddNestedGroup?.(nestedGroup.id)}
                onRemoveGroup={() => onRemoveNestedGroup?.(group.id, nestedGroup.id)}
                onAddNestedGroup={onAddNestedGroup}
                onRemoveNestedGroup={onRemoveNestedGroup}
                onUpdateNestedGroup={onUpdateNestedGroup}
                validationErrors={validationErrors}
              />
            </React.Fragment>
          ))}

          {/* Add Buttons */}
          <div className="flex gap-2 pt-2">
            <button
              onClick={onAddCondition}
              className="add-condition-btn flex items-center gap-1 px-3 py-1.5 text-sm text-indigo-600 hover:bg-indigo-50 rounded-md"
              aria-label="Add condition"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Add condition
            </button>

            {canNest && (
              <button
                onClick={onAddGroup}
                className="add-group-btn flex items-center gap-1 px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-100 rounded-md"
                aria-label="Add nested group"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16m-7 6h7" />
                </svg>
                Add group
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
