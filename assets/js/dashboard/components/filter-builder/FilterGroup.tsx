import React from 'react'
import classNames from 'classnames'
import { FilterGroup as FilterGroupType, isFilterGroup, LogicalOperator } from './types'
import { useFilterBuilderContext } from './filter-builder-context'
import FilterConditionRow from './FilterConditionRow'
import LogicalOperatorSelector from './LogicalOperatorSelector'

interface FilterGroupProps {
  group: FilterGroupType
  depth?: number
}

export default function FilterGroup({ group, depth = 0 }: FilterGroupProps) {
  const { updateGroupOperator, removeGroup } = useFilterBuilderContext()

  const handleOperatorChange = (operator: LogicalOperator) => {
    updateGroupOperator(group.id, operator)
  }

  const handleRemoveGroup = () => {
    removeGroup(group.id)
  }

  // Calculate visual indentation based on depth
  const indentation = depth * 4

  return (
    <div
      className={classNames(
        'relative rounded-lg border-2 transition-colors',
        {
          'border-blue-200 bg-blue-50/30': depth === 0,
          'border-purple-200 bg-purple-50/30': depth === 1,
          'border-indigo-200 bg-indigo-50/30': depth === 2,
          'border-red-200 bg-red-50/30': depth >= 3
        }
      )}
      style={{ marginLeft: `${indentation}px` }}
    >
      {/* Group header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wider">
            {depth === 0 ? 'Filter' : `Group ${depth}`}
          </span>
          <div className="w-24">
            <LogicalOperatorSelector
              value={group.operator}
              onChange={handleOperatorChange}
            />
          </div>
        </div>
        {depth > 0 && (
          <button
            onClick={handleRemoveGroup}
            className="text-xs text-red-500 hover:text-red-700"
          >
            Remove group
          </button>
        )}
      </div>

      {/* Group children */}
      <div className="p-3">
        {group.children.map((child, index) => {
          if (isFilterGroup(child)) {
            return (
              <FilterGroup
                key={child.id}
                group={child}
                depth={depth + 1}
              />
            )
          }

          return (
            <FilterConditionRow
              key={child.id}
              condition={child}
              index={index}
              showOperator={index > 0 ? group.operator : undefined}
              isLast={index === group.children.length - 1}
              groupId={group.id}
            />
          )
        })}

        {group.children.length === 0 && (
          <div className="text-center py-4 text-gray-500 text-sm">
            No conditions in this group
          </div>
        )}
      </div>
    </div>
  )
}
