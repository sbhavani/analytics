import React from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import { countFilters } from './filterTreeUtils'

export function CountFilters() {
  const { state } = useFilterBuilder()

  const filterCount = countFilters(state.filterTree)

  if (filterCount === 0) {
    return (
      <div className="filter-summary filter-summary--empty" data-testid="filter-summary">
        No filters applied
      </div>
    )
  }

  return (
    <div className="filter-summary" data-testid="filter-summary">
      {filterCount} filter{filterCount !== 1 ? 's' : ''} applied
    </div>
  )
}

export function FilterSummary() {
  const { state } = useFilterBuilder()

  const renderTree = (depth: number = 0): React.ReactNode => {
    const { rootGroup } = state.filterTree
    return renderGroup(rootGroup, depth)
  }

  const renderGroup = (group: typeof state.filterTree.rootGroup, depth: number): React.ReactNode => {
    return (
      <div className="filter-summary__group" key={group.id}>
        {depth > 0 && (
          <span className="filter-summary__operator">
            {group.operator.toUpperCase()}
          </span>
        )}
        <div className="filter-summary__children">
          {group.children.map((child) => {
            if ('children' in child) {
              return renderGroup(child, depth + 1)
            }
            return (
              <span key={child.id} className="filter-summary__condition">
                {child.dimension} {child.operator.replace('_', ' ')} {child.values.join(', ')}
              </span>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className="filter-summary__tree" data-testid="filter-summary-tree">
      {renderTree()}
    </div>
  )
}
