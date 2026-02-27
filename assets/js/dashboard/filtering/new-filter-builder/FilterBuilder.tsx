import React, { useState } from 'react'
import { useFilterBuilder, FilterBuilderProvider } from './FilterBuilderContext'
import { ConditionGroup } from './ConditionGroup'
import { CountFilters } from './FilterSummary'
import { countFilters, validateFilterTree } from './filterTreeUtils'
import type { Filter } from '../dashboard-state'

interface FilterBuilderProps {
  initialFilters?: Filter[]
  onApply?: (filters: Filter[]) => void
  onSave?: () => void
  onLoadSegment?: (segmentId: number) => void
  showUndoRedo?: boolean
}

function FilterBuilderInner({ onApply, onSave, showUndoRedo = true }: FilterBuilderProps) {
  const { state, clearAll, addCondition, getSerializedFilters, undo, redo, canUndo, canRedo } = useFilterBuilder()
  const [showValidation, setShowValidation] = useState(false)

  const handleApply = () => {
    const validation = validateFilterTree(state.filterTree)
    if (!validation.valid) {
      setShowValidation(true)
      return
    }
    setShowValidation(false)
    const filters = getSerializedFilters()
    onApply?.(filters)
  }

  const handleAddFilter = () => {
    addCondition({ dimension: '', operator: 'is', values: [] })
    setShowValidation(false)
  }

  const filterCount = countFilters(state.filterTree)

  return (
    <div className="filter-builder" data-testid="filter-builder">
      <div className="filter-builder__header">
        <h3 className="filter-builder__title">Filters</h3>

        {showUndoRedo && (
          <div className="filter-builder__history">
            <button
              type="button"
              className="filter-builder__undo"
              onClick={undo}
              disabled={!canUndo}
              title="Undo"
            >
              ↩
            </button>
            <button
              type="button"
              className="filter-builder__redo"
              onClick={redo}
              disabled={!canRedo}
              title="Redo"
            >
              ↪
            </button>
          </div>
        )}

        <button
          type="button"
          className="filter-builder__clear"
          onClick={clearAll}
          disabled={filterCount === 0}
        >
          Clear all
        </button>
      </div>

      <div className="filter-builder__content">
        <ConditionGroup
          group={state.filterTree.rootGroup}
          groupId={state.filterTree.rootGroup.id}
          depth={0}
          isRoot
        />
      </div>

      {showValidation && state.validationErrors.length > 0 && (
        <div className="filter-builder__errors" data-testid="validation-errors">
          {state.validationErrors.map((error, index) => (
            <div key={index} className="filter-builder__error">
              {error}
            </div>
          ))}
        </div>
      )}

      <div className="filter-builder__actions">
        <button
          type="button"
          className="filter-builder__add"
          onClick={handleAddFilter}
        >
          + Add filter
        </button>

        <div className="filter-builder__primary-actions">
          {onSave && (
            <button
              type="button"
              className="filter-builder__save"
              onClick={onSave}
            >
              Save as segment
            </button>
          )}

          <button
            type="button"
            className="filter-builder__apply"
            onClick={handleApply}
            disabled={!state.isValid}
          >
            Apply filters
          </button>
        </div>
      </div>

      <div className="filter-builder__footer">
        <CountFilters />
      </div>
    </div>
  )
}

export function FilterBuilder(props: FilterBuilderProps) {
  return (
    <FilterBuilderProvider initialFilters={props.initialFilters}>
      <FilterBuilderInner
        onApply={props.onApply}
        onSave={props.onSave}
        showUndoRedo={props.showUndoRedo}
      />
    </FilterBuilderProvider>
  )
}

export { useFilterBuilder } from './FilterBuilderContext'
export { FilterBuilderProvider } from './FilterBuilderContext'
