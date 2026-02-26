import React, { useCallback, useRef } from 'react'
import type { FilterGroup as FilterGroupType, FilterCondition, FilterLogic } from '../../../types/filter-builder'
import { FilterConditionRow } from './FilterConditionRow'

interface FilterGroupProps {
  group: FilterGroupType
  depth?: number
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  onRemoveCondition: (conditionId: string) => void
  onAddCondition: () => void
  onToggleLogic: () => void
  onSetLogic: (logic: FilterLogic) => void
  onAddNestedGroup: () => void
  onRemoveNestedGroup?: (nestedGroupId: string) => void
  disabled?: boolean
}

// Get only the actual conditions (not nested groups) from a group
function getConditions(group: FilterGroupType): FilterCondition[] {
  return group.conditions.filter((c): c is FilterCondition => 'operator' in c)
}

export function FilterGroup({
  group,
  depth = 0,
  onUpdateCondition,
  onRemoveCondition,
  onAddCondition,
  onToggleLogic,
  onSetLogic,
  onAddNestedGroup,
  onRemoveNestedGroup,
  disabled = false
}: FilterGroupProps) {
  const maxDepth = 3

  const handleConditionUpdate = useCallback(
    (conditionId: string, updates: Partial<FilterCondition>) => {
      onUpdateCondition(conditionId, updates)
    },
    [onUpdateCondition]
  )

  const handleConditionRemove = useCallback(
    (conditionId: string) => {
      onRemoveCondition(conditionId)
    },
    [onRemoveCondition]
  )

  return (
    <div
      className={`filter-group p-3 rounded-lg border-2 ${
        depth === 0 ? 'border-gray-200 bg-gray-50' : 'border-dashed border-gray-300 bg-white'
      }`}
      style={{ marginLeft: depth > 0 ? `${depth * 16}px` : 0 }}
    >
      {/* Group Header with Logic Selector */}
      <div className="flex items-center gap-2 mb-2">
        <span className="text-sm font-medium text-gray-600">
          Match
        </span>
        <select
          value={group.logic}
          onChange={(e) => onSetLogic(e.target.value as FilterLogic)}
          disabled={disabled}
          className="px-2 py-1 text-sm font-semibold border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="AND">ALL</option>
          <option value="OR">ANY</option>
        </select>
        <span className="text-sm text-gray-600">
          of the following conditions:
        </span>
      </div>

      {/* Conditions */}
      <div className="space-y-2">
        {group.conditions.map((condition, index) => {
          if ('logic' in condition) {
            // Nested group
            return (
              <FilterGroup
                key={condition.id}
                group={condition}
                depth={depth + 1}
                onUpdateCondition={(conditionId, updates) =>
                  // Update condition in nested group
                  onUpdateCondition(conditionId, updates)
                }
                onRemoveCondition={(conditionId) =>
                  onRemoveCondition(conditionId)
                }
                onAddCondition={() => {
                  // Can't add to nested group from here
                }}
                onToggleLogic={() => {
                  // Toggle nested group logic
                }}
                onSetLogic={(logic) => {
                  // Set nested group logic
                }}
                onAddNestedGroup={
                  depth + 1 < maxDepth ? onAddNestedGroup : () => {}
                }
                onRemoveNestedGroup={
                  depth > 0
                    ? () => onRemoveNestedGroup?.(condition.id)
                    : undefined
                }
                disabled={disabled}
              />
            )
          }

          // Regular condition
          const conditions = getConditions(group)
          const isFirst = conditions.length > 0 && conditions[0].id === condition.id
          const isLast = conditions.length > 0 && conditions[conditions.length - 1].id === condition.id

          return (
            <FilterConditionRow
              key={condition.id}
              condition={condition}
              onUpdate={(updates) => handleConditionUpdate(condition.id, updates)}
              onRemove={() => handleConditionRemove(condition.id)}
              onAddCondition={onAddCondition}
              isFirst={isFirst}
              isLast={isLast}
              disabled={disabled}
            />
          )
        })}
      </div>

      {/* Action Buttons */}
      <div className="flex items-center gap-2 mt-3">
        <button
          type="button"
          onClick={onAddCondition}
          disabled={disabled}
          className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-blue-600 bg-blue-50 rounded-md hover:bg-blue-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <svg
            className="w-4 h-4 mr-1"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 4v16m8-8H4"
            />
          </svg>
          Add Condition
        </button>

        {depth + 1 < maxDepth && (
          <button
            type="button"
            onClick={onAddNestedGroup}
            disabled={disabled}
            className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-purple-600 bg-purple-50 rounded-md hover:bg-purple-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg
              className="w-4 h-4 mr-1"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
              />
            </svg>
            Add Group
          </button>
        )}

        {depth > 0 && onRemoveNestedGroup && (
          <button
            type="button"
            onClick={() => onRemoveNestedGroup(group.id)}
            disabled={disabled}
            className="inline-flex items-center px-3 py-1.5 text-sm font-medium text-red-600 bg-red-50 rounded-md hover:bg-red-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg
              className="w-4 h-4 mr-1"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
            Remove Group
          </button>
        )}
      </div>
    </div>
  )
}
