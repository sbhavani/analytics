import React from 'react'
import {
  FilterGroup as FilterGroupType,
  FilterComposite,
  createFilterCondition,
  changeGroupFilterType,
  addConditionToGroup,
  removeConditionFromGroup,
  updateConditionInGroup,
  MAX_CHILDREN_PER_GROUP
} from '../util/filter-serializer'
import FilterCondition from './filter-condition'
import FilterConnector from './filter-connector'
import { NestedGroupIndicator } from './nested-group'

interface FilterGroupProps {
  group: FilterGroupType
  groupId: string
  depth: number
  availableDimensions: Dimension[]
  maxDepth?: number
  onChange: (group: FilterGroupType) => void
  onRemove?: () => void
  readOnly?: boolean
}

interface Dimension {
  key: string
  name: string
}

export const FilterGroup: React.FC<FilterGroupProps> = ({
  group,
  groupId,
  depth,
  availableDimensions,
  maxDepth = 2,
  onChange,
  onRemove,
  readOnly = false
}) => {
  const canAddChild = group.children.length < MAX_CHILDREN_PER_GROUP

  const handleFilterTypeChange = (filterType: 'and' | 'or') => {
    onChange(changeGroupFilterType(group, filterType))
  }

  const handleAddCondition = () => {
    if (!canAddChild) return
    const newCondition = createFilterCondition(availableDimensions[0]?.key || 'page', 'is', [''])
    onChange(addConditionToGroup(group, newCondition))
  }

  const handleConditionChange = (index: number, condition: FilterComposite) => {
    onChange(updateConditionInGroup(group, index, condition))
  }

  const handleConditionRemove = (index: number) => {
    if (group.children.length === 1 && onRemove) {
      // If this is the last condition and we're at root level, remove the whole group
      onRemove()
    } else {
      onChange(removeConditionFromGroup(group, index))
    }
  }

  const depthIndicator = depth > 0 && (
    <div className="absolute -left-3 top-1/2 -translate-y-1/2 w-6 h-px bg-gray-300" />
  )

  return (
    <div
      className={`relative p-4 rounded-lg border-2 ${
        depth > 0 ? 'border-indigo-200 bg-indigo-50' : 'border-gray-200 bg-gray-50'
      }`}
      role="group"
      aria-label={`Filter group at depth ${depth}`}
    >
      {/* Connector type selector */}
      {!readOnly && group.children.length > 0 && (
        <div className="mb-3">
          <FilterConnector
            filterType={group.filter_type}
            onChange={handleFilterTypeChange}
          />
        </div>
      )}

      {/* Connector type display when read-only */}
      {readOnly && group.children.length > 0 && (
        <div className="mb-3">
          <span className="px-3 py-1 text-sm font-medium rounded-md bg-indigo-100 text-indigo-700 border border-indigo-300">
            {group.filter_type.toUpperCase()}
          </span>
        </div>
      )}

      {/* Children */}
      <div className="space-y-2">
        {group.children.map((child, index) => (
          <div key={`${groupId}-${index}`} className="relative">
            {/* Connector between children */}
            {index > 0 && (
              <div className="flex items-center justify-center py-1">
                <span className="text-xs font-medium text-gray-500 uppercase">
                  {group.filter_type}
                </span>
              </div>
            )}

            {'filter_type' in child ? (
              // Nested group
              <FilterGroup
                group={child}
                groupId={`${groupId}-${index}`}
                depth={depth + 1}
                availableDimensions={availableDimensions}
                maxDepth={maxDepth}
                onChange={(updated) => handleConditionChange(index, updated)}
                onRemove={() => handleConditionRemove(index)}
                readOnly={readOnly}
              />
            ) : (
              // Leaf condition
              <FilterCondition
                condition={child}
                availableDimensions={availableDimensions}
                onChange={(condition) => handleConditionChange(index, condition)}
                onRemove={() => handleConditionRemove(index)}
              />
            )}
          </div>
        ))}
      </div>

      {/* Add condition button */}
      {!readOnly && canAddChild && (
        <div className="mt-3 pt-3 border-t border-gray-200">
          <button
            onClick={handleAddCondition}
            className="flex items-center gap-2 text-sm text-indigo-600 hover:text-indigo-800"
            aria-label="Add condition"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Condition
          </button>
        </div>
      )}

      {/* Max children warning */}
      {!readOnly && !canAddChild && (
        <div className="mt-3 pt-3 border-t border-gray-200">
          <p className="text-sm text-amber-600">
            Maximum {MAX_CHILDREN_PER_GROUP} conditions per group reached
          </p>
        </div>
      )}

      {/* Nesting depth indicator */}
      {!readOnly && (
        <div className="mt-3">
          <NestedGroupIndicator depth={depth} maxDepth={maxDepth} />
        </div>
      )}
    </div>
  )
}

export default FilterGroup
