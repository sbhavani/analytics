import React from 'react'
import { PlusIcon, TrashIcon } from '@heroicons/react/20/solid'
import { ConditionGroup as ConditionGroupType, FilterCondition, createFilterCondition } from '../../filtering/segments'
import { ConditionRow } from './condition-row'
import { LogicSelector } from './logic-selector'

interface ConditionGroupProps {
  group: ConditionGroupType
  onAddCondition: () => void
  onUpdateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  onRemoveCondition: (conditionId: string) => void
  onUpdateLogic: (logic: 'AND' | 'OR') => void
}

export function ConditionGroupComponent({
  group,
  onAddCondition,
  onUpdateCondition,
  onRemoveCondition,
  onUpdateLogic
}: ConditionGroupProps) {
  const depth = group.depth || 1

  return (
    <div
      className="condition-group"
      style={{
        marginLeft: `${(depth - 1) * 16}px`,
        borderLeft: depth > 1 ? '2px solid #e5e7eb' : 'none',
        paddingLeft: depth > 1 ? '12px' : '0'
      }}
    >
      <div className="condition-group__header flex items-center justify-between mb-2">
        <LogicSelector
          value={group.logic}
          onChange={onUpdateLogic}
        />
        <span className="text-xs text-gray-500">
          {group.children.length} condition{group.children.length !== 1 ? 's' : ''}
        </span>
      </div>

      <div className="condition-group__conditions space-y-2">
        {group.children.map((child, index) => {
          if ('children' in child) {
            // Nested group
            return (
              <ConditionGroupComponent
                key={child.id}
                group={child}
                onAddCondition={() => {
                  // For nested groups, we'd need to pass the parent id
                  console.warn('Nested group add not implemented')
                }}
                onUpdateCondition={() => {}}
                onRemoveCondition={() => {}}
                onUpdateLogic={() => {}}
              />
            )
          }

          return (
            <div key={child.id} className="flex items-start gap-2">
              {index > 0 && (
                <div className="flex items-center justify-center w-16 py-2">
                  <span className="text-xs font-medium text-gray-500 uppercase bg-white px-2">
                    {group.logic}
                  </span>
                </div>
              )}
              <div className="flex-1">
                <ConditionRow
                  condition={child}
                  onChange={(updates) => onUpdateCondition(child.id, updates)}
                  onRemove={() => onRemoveCondition(child.id)}
                />
              </div>
            </div>
          )
        })}
      </div>

      <button
        onClick={onAddCondition}
        className="mt-2 flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
      >
        <PlusIcon className="w-4 h-4" />
        Add Condition
      </button>
    </div>
  )
}
