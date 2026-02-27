import React from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import { ConditionRow } from './ConditionRow'
import { isFilterGroup } from './filterTreeUtils'
import type { FilterGroup as FilterGroupType, FilterCondition as FilterConditionType } from './types'

interface ConditionGroupProps {
  group: FilterGroupType
  groupId: string
  depth: number
  isRoot?: boolean
}

export function ConditionGroup({ group, groupId, depth, isRoot = false }: ConditionGroupProps) {
  const { changeGroupOperator, addGroup, addCondition, deleteGroup } = useFilterBuilder()

  const handleOperatorChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    changeGroupOperator(groupId, e.target.value as 'and' | 'or')
  }

  const handleAddNestedGroup = () => {
    addGroup('or', groupId)
  }

  const handleAddCondition = () => {
    addCondition({ dimension: '', operator: 'is', values: [] }, groupId)
  }

  const handleDeleteGroup = () => {
    deleteGroup(groupId)
  }

  const canAddNestedGroup = depth < 2 // Max 3 levels (0, 1, 2)

  return (
    <div
      className={`condition-group condition-group--depth-${depth} ${isRoot ? 'condition-group--root' : ''}`}
      data-testid="condition-group"
      data-group-id={groupId}
    >
      {!isRoot && (
        <div className="condition-group__header">
          <select
            className="condition-group__operator"
            value={group.operator}
            onChange={handleOperatorChange}
            data-testid="group-operator-select"
          >
            <option value="and">AND</option>
            <option value="or">OR</option>
          </select>

          <button
            type="button"
            className="condition-group__delete"
            onClick={handleDeleteGroup}
            title="Delete group"
          >
            ×
          </button>
        </div>
      )}

      <div className="condition-group__children">
        {group.children.map((child) => {
          if (isFilterGroup(child)) {
            return (
              <ConditionGroup
                key={child.id}
                group={child}
                groupId={child.id}
                depth={depth + 1}
              />
            )
          }
          return (
            <ConditionRow
              key={child.id}
              condition={child}
              groupId={groupId}
            />
          )
        })}
      </div>

      <div className="condition-group__actions">
        <button
          type="button"
          className="condition-group__add-condition"
          onClick={handleAddCondition}
        >
          + Add condition
        </button>

        {canAddNestedGroup && (
          <button
            type="button"
            className="condition-group__add-group"
            onClick={handleAddNestedGroup}
          >
            + Add group
          </button>
        )}
      </div>
    </div>
  )
}
