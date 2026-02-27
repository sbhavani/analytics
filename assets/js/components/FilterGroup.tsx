import React from 'react'
import { FilterGroupNode, FilterConditionNode, GroupOperator } from '../lib/types/filter-tree'
import { createCondition, canAddCondition, canAddGroup } from '../lib/filter-tree'
import FilterConditionEditor from './FilterConditionEditor'

interface FilterGroupProps {
  group: FilterGroupNode
  onChange: (updated: FilterGroupNode) => void
  siteId: string
  depth?: number
  onAddCondition: (condition: FilterConditionNode) => void
  onAddGroup: () => void
  onRemoveCondition: (conditionId: string) => void
  onUpdateCondition: (conditionId: string, updates: Partial<FilterConditionNode>) => void
}

export const FilterGroup: React.FC<FilterGroupProps> = ({
  group,
  onChange,
  siteId,
  depth = 0,
  onAddCondition,
  onAddGroup,
  onRemoveCondition,
  onUpdateCondition
}) => {
  const handleOperatorChange = (operator: GroupOperator) => {
    onChange({ ...group, operator })
  }

  const handleConditionChange = (conditionId: string, updates: Partial<FilterConditionNode>) => {
    onUpdateCondition(conditionId, updates)
  }

  const handleConditionRemove = (conditionId: string) => {
    onRemoveCondition(conditionId)
  }

  const isNested = depth > 0

  return (
    <div
      className={`filter-group ${isNested ? 'ml-6 border-l-2 border-gray-200 pl-4' : ''}`}
      role="group"
      aria-label={`Filter group with ${group.operator} logic`}
    >
      {/* Group Header with Operator Toggle */}
      <div className="flex items-center gap-2 mb-2">
        <div className="flex rounded-md shadow-sm" role="group">
          <button
            type="button"
            onClick={() => handleOperatorChange('and')}
            className={`px-4 py-2 text-sm font-medium rounded-l-md ${
              group.operator === 'and'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-50 border'
            }`}
            aria-pressed={group.operator === 'and'}
          >
            AND
          </button>
          <button
            type="button"
            onClick={() => handleOperatorChange('or')}
            className={`px-4 py-2 text-sm font-medium rounded-r-md ${
              group.operator === 'or'
                ? 'bg-blue-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-50 border'
            }`}
            aria-pressed={group.operator === 'or'}
          >
            OR
          </button>
        </div>

        <span className="text-sm text-gray-500">
          {group.children.length} {group.children.length === 1 ? 'condition' : 'conditions'}
        </span>
      </div>

      {/* Children */}
      <div className="space-y-2">
        {group.children.map((child, index) => {
          if (child.type === 'condition') {
            return (
              <div key={child.id} className="relative">
                {/* Show connector for AND/OR between conditions */}
                {index > 0 && (
                  <div className="absolute -top-3 left-4 text-xs text-gray-500 bg-white px-2 z-10">
                    {group.operator.toUpperCase()}
                  </div>
                )}
                <FilterConditionEditor
                  condition={child}
                  onChange={(updated) => handleConditionChange(child.id, updated)}
                  onRemove={() => handleConditionRemove(child.id)}
                  siteId={siteId}
                />
              </div>
            )
          }
          // Nested group - recursive rendering would go here
          return null
        })}
      </div>

      {/* Action Buttons */}
      <div className="flex gap-2 mt-3">
        <button
          type="button"
          onClick={onAddCondition}
          disabled={!canAddCondition({ version: 1, root: group } as any)}
          className="px-3 py-1.5 text-sm text-blue-600 hover:bg-blue-50 rounded-md border border-blue-200 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          + Add Condition
        </button>

        {canAddGroup({ version: 1, root: group } as any, group.id) && (
          <button
            type="button"
            onClick={onAddGroup}
            className="px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-50 rounded-md border border-gray-200"
          >
            + Add Group
          </button>
        )}
      </div>
    </div>
  )
}

export default FilterGroup
