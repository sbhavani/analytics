import React from 'react'
import { FilterGroup, FilterCondition } from '../../types/filter-expression'
import ConditionRow from './condition-row'

interface FilterGroupProps {
  group: FilterGroup
  onChange: (group: FilterGroup) => void
  onDelete?: () => void
  onAddCondition: () => void
  onUpdateCondition: (conditionId: string, condition: FilterCondition) => void
  onDeleteCondition: (conditionId: string) => void
  depth?: number
}

export function FilterGroupComponent({
  group,
  onChange,
  onDelete,
  onAddCondition,
  onUpdateCondition,
  onDeleteCondition,
  depth = 0
}: FilterGroupProps) {
  const maxDepth = 5
  const canNest = depth < maxDepth

  const handleOperatorChange = (newOperator: 'AND' | 'OR') => {
    onChange({ ...group, operator: newOperator })
  }

  const handleConnectorChange = (index: number, newConnector: 'AND' | 'OR') => {
    const currentConnectors = group.connectors || {}
    onChange({
      ...group,
      connectors: {
        ...currentConnectors,
        [index]: newConnector
      }
    })
  }

  const handleChildChange = (index: number, child: FilterCondition | FilterGroup) => {
    const newChildren = [...group.children]
    newChildren[index] = child
    // When children change, clean up orphaned connectors
    const newConnectors: Record<number, 'AND' | 'OR'> = {}
    Object.entries(group.connectors || {}).forEach(([key, value]) => {
      const idx = parseInt(key, 10)
      if (idx < newChildren.length - 1) {
        newConnectors[idx] = value
      }
    })
    onChange({ ...group, children: newChildren, connectors: newConnectors })
  }

  const handleDeleteChild = (index: number) => {
    const newChildren = group.children.filter((_, i) => i !== index)
    // When deleting a child, also clean up connectors
    const newConnectors: Record<number, 'AND' | 'OR'> = {}
    Object.entries(group.connectors || {}).forEach(([key, value]) => {
      const idx = parseInt(key, 10)
      if (idx < index) {
        newConnectors[idx] = value
      } else if (idx >= index) {
        // Shift connectors after the deleted index
        newConnectors[idx - 1] = value
      }
    })
    onChange({ ...group, children: newChildren, connectors: newConnectors })
  }

  return (
    <div className={`relative ${depth > 0 ? 'ml-4 pl-4 border-l-2 border-indigo-200' : ''}`}>
      {/* Group header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center space-x-2">
          <span className="text-sm font-medium text-gray-500">Group:</span>
          <select
            value={group.operator}
            onChange={(e) => handleOperatorChange(e.target.value as 'AND' | 'OR')}
            className="px-2 py-1 text-sm font-medium text-indigo-700 bg-indigo-50 border border-indigo-200 rounded hover:bg-indigo-100"
          >
            <option value="AND">AND (all match)</option>
            <option value="OR">OR (any match)</option>
          </select>
        </div>

        {onDelete && (
          <button
            type="button"
            onClick={onDelete}
            className="p-1 text-gray-400 hover:text-red-500 transition-colors"
            title="Remove group"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* Group children */}
      <div className="space-y-1">
        {group.children.map((child, index) => {
          if ('dimension' in child) {
            // It's a condition
            const isLast = index === group.children.length - 1
            // Find previous sibling - skip over nested groups
            const prevChild = index > 0 ? group.children[index - 1] : null
            // Use stored connector if available, otherwise fall back to group operator
            const storedConnector = !isLast && group.connectors?.[index]
            const connector = prevChild && !('dimension' in prevChild) ? undefined :
                              (prevChild && index > 0 ? (storedConnector || group.operator) : undefined)

            return (
              <ConditionRow
                key={child.id}
                condition={child}
                onChange={(updated) => onUpdateCondition(child.id, updated)}
                onDelete={() => onDeleteCondition(child.id)}
                isLast={isLast}
                connector={connector}
                onConnectorChange={(newConnector) => {
                  handleConnectorChange(index, newConnector)
                }}
              />
            )
          } else {
            // It's a nested group - render recursively
            return (
              <FilterGroupComponent
                key={child.id}
                group={child}
                onChange={(updated) => handleChildChange(index, updated)}
                onDelete={() => handleDeleteChild(index)}
                onAddCondition={() => {
                  const newChild = {
                    ...child,
                    children: [...child.children, {
                      id: Math.random().toString(36).substring(2, 11),
                      dimension: 'country',
                      operator: 'is',
                      value: ''
                    }]
                  }
                  handleChildChange(index, newChild)
                }}
                onUpdateCondition={(condId, cond) => {
                  const updateChild = (g: FilterGroup): FilterGroup => ({
                    ...g,
                    children: g.children.map(c => ('dimension' in c && c.id === condId) ? cond : c)
                  })
                  handleChildChange(index, updateChild(child))
                }}
                onDeleteCondition={(condId) => {
                  const deleteFromChild = (g: FilterGroup): FilterGroup => ({
                    ...g,
                    children: g.children.filter(c => !('dimension' in c) || c.id !== condId)
                  })
                  handleChildChange(index, deleteFromChild(child))
                }}
                depth={depth + 1}
              />
            )
          }
        })}
      </div>

      {/* Add condition button */}
      {canNest && (
        <button
          type="button"
          onClick={onAddCondition}
          className="mt-2 flex items-center text-sm text-indigo-600 hover:text-indigo-800"
        >
          <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Add condition
        </button>
      )}

      {!canNest && depth >= maxDepth && (
        <p className="mt-2 text-xs text-gray-500">
          Maximum nesting level reached ({maxDepth} levels)
        </p>
      )}
    </div>
  )
}

export default FilterGroupComponent
