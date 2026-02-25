import React, { useState } from 'react'
import { FilterGroup as FilterGroupType, FilterCondition as FilterConditionType } from './types'
import { FilterCondition } from './FilterCondition'
import { createFilterCondition, createFilterGroup, getNestingDepth } from './filter-utils'

interface FilterGroupProps {
  group: FilterGroupType
  onChange: (group: FilterGroupType) => void
  onRemove?: () => void
  canAddNested?: boolean
  maxDepth?: number
}

export function FilterGroup({
  group,
  onChange,
  onRemove,
  canAddNested = true,
  maxDepth = 5
}: FilterGroupProps) {
  const [isCollapsed, setIsCollapsed] = useState(false)

  const currentDepth = getNestingDepth(group, 0)
  const canAddMoreNested = canAddNested && currentDepth < maxDepth - 1

  const handleConditionChange = (index: number, condition: FilterConditionType) => {
    const newConditions = [...group.conditions]
    newConditions[index] = condition
    onChange({ ...group, conditions: newConditions })
  }

  const handleConditionRemove = (index: number) => {
    const newConditions = group.conditions.filter((_, i) => i !== index)
    onChange({ ...group, conditions: newConditions })
  }

  const handleAddCondition = () => {
    const newConditions = [...group.conditions, createFilterCondition()]
    onChange({ ...group, conditions: newConditions })
  }

  const handleLogicToggle = () => {
    onChange({ ...group, logic: group.logic === 'AND' ? 'OR' : 'AND' })
  }

  const handleAddNestedGroup = () => {
    const newGroups = [...group.groups, createFilterGroup('AND')]
    onChange({ ...group, groups: newGroups })
  }

  const handleNestedGroupChange = (index: number, nestedGroup: FilterGroupType) => {
    const newGroups = [...group.groups]
    newGroups[index] = nestedGroup
    onChange({ ...group, groups: newGroups })
  }

  const handleNestedGroupRemove = (index: number) => {
    const newGroups = group.groups.filter((_, i) => i !== index)
    onChange({ ...group, groups: newGroups })
  }

  const conditionCount = group.conditions.length + group.groups.reduce(
    (acc, g) => acc + g.conditions.length + g.groups.reduce((a, gg) => a + gg.conditions.length, 0),
    0
  )

  return (
    <div className={`border rounded-lg ${group.logic === 'OR' ? 'border-indigo-200 bg-indigo-50' : 'border-gray-200 bg-gray-50'} p-3`}>
      {/* Group Header */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          {/* Logic Toggle */}
          <button
            onClick={handleLogicToggle}
            className={`px-3 py-1 text-sm font-medium rounded transition-colors ${
              group.logic === 'OR'
                ? 'bg-indigo-100 text-indigo-700 hover:bg-indigo-200'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            {group.logic}
          </button>

          {/* Collapse Toggle */}
          {conditionCount > 0 && (
            <button
              onClick={() => setIsCollapsed(!isCollapsed)}
              className="p-1 text-gray-500 hover:text-gray-700"
            >
              <svg
                className={`w-4 h-4 transition-transform ${isCollapsed ? '' : 'rotate-90'}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          )}

          {/* Summary */}
          {isCollapsed && conditionCount > 0 && (
            <span className="text-sm text-gray-500">
              {conditionCount} condition{conditionCount !== 1 ? 's' : ''}
            </span>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2">
          <button
            onClick={handleAddCondition}
            className="px-2 py-1 text-sm text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 rounded"
          >
            + Add condition
          </button>
          {canAddMoreNested && (
            <button
              onClick={handleAddNestedGroup}
              className="px-2 py-1 text-sm text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 rounded"
            >
              + Add group
            </button>
          )}
          {onRemove && (
            <button
              onClick={onRemove}
              className="p-1 text-gray-400 hover:text-red-500"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {/* Group Content */}
      {!isCollapsed && (
        <div className="space-y-2">
          {/* Conditions */}
          {group.conditions.map((condition, index) => (
            <FilterCondition
              key={condition.id}
              condition={condition}
              onChange={(c) => handleConditionChange(index, c)}
              onRemove={() => handleConditionRemove(index)}
            />
          ))}

          {/* Nested Groups */}
          {group.groups.map((nestedGroup, index) => (
            <FilterGroup
              key={nestedGroup.id}
              group={nestedGroup}
              onChange={(g) => handleNestedGroupChange(index, g)}
              onRemove={() => handleNestedGroupRemove(index)}
              canAddNested={canAddNested}
              maxDepth={maxDepth}
            />
          ))}

          {/* Empty State */}
          {group.conditions.length === 0 && group.groups.length === 0 && (
            <div className="text-center py-4 text-gray-500 text-sm">
              Click &quot;Add condition&quot; to start building your filter
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default FilterGroup
