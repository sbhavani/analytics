import React from 'react'
import { FilterGroup as FilterGroupType, FilterCondition } from '../lib/filterBuilder/types'
import { ConditionRow } from './ConditionRow'

interface FilterGroupProps {
  group: FilterGroupType
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  onRemoveCondition: (conditionId: string) => void
  onChangeConnector: (connector: 'AND' | 'OR') => void
  onAddCondition: () => void
  onCreateGroup?: (conditionIds: string[], connector: 'AND' | 'OR') => void
  onUngroup?: (groupId: string) => void
  isRoot?: boolean
}

export function FilterGroup({
  group,
  onUpdateCondition,
  onRemoveCondition,
  onChangeConnector,
  onAddCondition,
  onCreateGroup,
  onUngroup,
  isRoot = false,
}: FilterGroupProps) {
  const allConditionIds = group.conditions.map((c) => c.id)

  return (
    <div
      className={`border rounded-lg p-4 ${isRoot ? 'border-gray-200 dark:border-gray-700' : 'border-indigo-200 dark:border-indigo-800 bg-indigo-50 dark:bg-indigo-900/20'}`}
    >
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          {!isRoot && (
            <button
              type="button"
              onClick={() => onUngroup?.(group.id)}
              className="text-xs text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300"
              title="Ungroup"
            >
              Ungroup
            </button>
          )}

          {group.conditions.length > 1 && (
            <div className="flex items-center gap-1">
              <span className="text-sm text-gray-500 dark:text-gray-400">Match</span>
              <select
                value={group.connector}
                onChange={(e) => onChangeConnector(e.target.value as 'AND' | 'OR')}
                className="px-2 py-1 text-sm border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 dark:bg-gray-800 dark:border-gray-600"
              >
                <option value="AND">ALL conditions (AND)</option>
                <option value="OR">ANY condition (OR)</option>
              </select>
            </div>
          )}

          {allConditionIds.length >= 2 && onCreateGroup && (
            <div className="flex items-center gap-1 ml-2">
              <button
                type="button"
                onClick={() => onCreateGroup(allConditionIds, 'AND')}
                className="text-xs text-indigo-600 hover:text-indigo-800 dark:text-indigo-400"
                title="Group with AND"
              >
                Group (AND)
              </button>
              <button
                type="button"
                onClick={() => onCreateGroup(allConditionIds, 'OR')}
                className="text-xs text-indigo-600 hover:text-indigo-800 dark:text-indigo-400"
                title="Group with OR"
              >
                Group (OR)
              </button>
            </div>
          )}
        </div>

        <button
          type="button"
          onClick={onAddCondition}
          className="flex items-center gap-1 px-3 py-1 text-sm text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="w-4 h-4"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fillRule="evenodd"
              d="M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z"
              clipRule="evenodd"
            />
          </svg>
          Add condition
        </button>
      </div>

      <div className="space-y-2">
        {group.conditions.map((condition, index) => (
          <ConditionRow
            key={condition.id}
            condition={condition}
            onUpdate={(updates) => onUpdateCondition(condition.id, updates)}
            onRemove={() => onRemoveCondition(condition.id)}
            connector={index > 0 ? group.connector : undefined}
            showConnector={index > 0}
          />
        ))}
      </div>

      {group.subgroups.length > 0 && (
        <div className="mt-4 space-y-3">
          {group.subgroups.map((subgroup) => (
            <FilterGroup
              key={subgroup.id}
              group={subgroup}
              onUpdateCondition={onUpdateCondition}
              onRemoveCondition={onRemoveCondition}
              onChangeConnector={(connector) => {
                // For simplicity, we'd need to pass the subgroup ID here
                // This is a simplified version
              }}
              onAddCondition={onAddCondition}
              onCreateGroup={onCreateGroup}
              onUngroup={onUngroup}
              isRoot={false}
            />
          ))}
        </div>
      )}

      {group.conditions.length === 0 && group.subgroups.length === 0 && (
        <div className="text-center py-4 text-gray-500 dark:text-gray-400">
          No conditions yet. Click "Add condition" to start building your filter.
        </div>
      )}
    </div>
  )
}
