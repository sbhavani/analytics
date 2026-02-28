import React from 'react'
import { PlusIcon, FolderPlusIcon, XMarkIcon } from '@heroicons/react/20/solid'
import { FilterGroup, FilterCondition } from './types'
import ConditionRow from './ConditionRow'
import { createCondition, createGroup } from './filterTreeUtils'

interface ConditionGroupProps {
  group: FilterGroup
  groupId: string
  level?: number
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  onDeleteCondition: (conditionId: string) => void
  onAddCondition: (groupId: string) => void
  onUpdateConnector: (groupId: string, connector: 'AND' | 'OR') => void
  onAddNestedGroup: (groupId: string) => void
  onDeleteNestedGroup?: (groupId: string) => void
  canDeleteGroup?: boolean
}

export function ConditionGroup({
  group,
  groupId,
  level = 0,
  onUpdateCondition,
  onDeleteCondition,
  onAddCondition,
  onUpdateConnector,
  onAddNestedGroup,
  onDeleteNestedGroup,
  canDeleteGroup = false
}: ConditionGroupProps) {
  const isRootGroup = level === 0

  return (
    <div
      className={`
        ${level > 0 ? 'ml-6 pl-4 border-l-2 border-indigo-200' : ''}
        ${level > 0 ? 'mt-2' : ''}
      `}
      role="group"
      aria-label={isRootGroup ? 'Filter conditions' : `Nested condition group ${level}`}
    >
      {/* Connector selector for non-root groups */}
      {level > 0 && (
        <div className="flex items-center gap-2 mb-2">
          <span className="text-sm text-gray-500">Match</span>
          <select
            value={group.connector}
            onChange={(e) => onUpdateConnector(groupId, e.target.value as 'AND' | 'OR')}
            className="
              rounded-md border-gray-300 py-1 pl-2 pr-8 text-sm
              focus:border-indigo-500 focus:ring-indigo-500
            "
            aria-label="Connector type"
          >
            <option value="AND">ALL conditions (AND)</option>
            <option value="OR">ANY condition (OR)</option>
          </select>
          <span className="text-sm text-gray-500">of the following:</span>

          {canDeleteGroup && onDeleteNestedGroup && (
            <button
              type="button"
              onClick={() => onDeleteNestedGroup(groupId)}
              className="ml-auto inline-flex items-center p-1 text-gray-400 hover:text-red-500 rounded-md hover:bg-red-50"
              aria-label="Delete group"
            >
              <XMarkIcon className="h-4 w-4" />
            </button>
          )}
        </div>
      )}

      {/* Conditions list */}
      <div className="space-y-2" role="list" aria-label="Filter conditions">
        {group.conditions.map((condition, index) => (
          <ConditionRow
            key={condition.id}
            condition={condition}
            isFirst={index === 0}
            connector={index > 0 ? group.connector : undefined}
            onUpdate={(updates) => onUpdateCondition(condition.id, updates)}
            onDelete={() => onDeleteCondition(condition.id)}
          />
        ))}
      </div>

      {/* Nested groups */}
      {group.nestedGroups.map((nestedGroup) => (
        <ConditionGroup
          key={nestedGroup.id}
          group={nestedGroup}
          groupId={nestedGroup.id}
          level={level + 1}
          onUpdateCondition={onUpdateCondition}
          onDeleteCondition={onDeleteCondition}
          onAddCondition={(id) => onAddCondition(nestedGroup.id)}
          onUpdateConnector={(connector) => onUpdateConnector(nestedGroup.id, connector)}
          onAddNestedGroup={(id) => onAddNestedGroup(nestedGroup.id)}
          onDeleteNestedGroup={(id) => onDeleteNestedGroup?.(nestedGroup.id)}
          canDeleteGroup={true}
        />
      ))}

      {/* Add buttons */}
      <div className="flex items-center gap-2 mt-3">
        <button
          type="button"
          onClick={() => onAddCondition(groupId)}
          className="
            inline-flex items-center px-3 py-1.5 text-sm font-medium
            text-indigo-700 bg-indigo-50 rounded-md
            hover:bg-indigo-100 transition-colors
            focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2
          "
          aria-label="Add condition"
        >
          <PlusIcon className="h-4 w-4 mr-1" />
          Add condition
        </button>

        {level < 4 && (
          <button
            type="button"
            onClick={() => onAddNestedGroup(groupId)}
            className="
              inline-flex items-center px-3 py-1.5 text-sm font-medium
              text-gray-700 bg-white border border-gray-300 rounded-md
              hover:bg-gray-50 transition-colors
              focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2
            "
            aria-label="Add nested group"
          >
            <FolderPlusIcon className="h-4 w-4 mr-1" />
            Add group
          </button>
        )}
      </div>
    </div>
  )
}

export default ConditionGroup
