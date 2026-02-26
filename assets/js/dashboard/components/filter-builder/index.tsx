/**
 * FilterBuilder Component
 *
 * Main container component for the Advanced Filter Builder
 */

import React, { useState, useCallback } from 'react'
import {
  FilterExpression,
  FilterCondition,
  ConditionGroup,
  createEmptyExpression,
  createCondition,
  LogicalOperator,
  FilterBuilderError,
  generateId
} from './types'
import { validateExpression, expressionToHumanString } from './utils'
import { useSegmentsContext } from '../../filtering/segments-context'
import { useSaveSegment, useUpdateSegment } from './use-save-segment'
import { ConditionGroup as ConditionGroupComponent } from './condition-group'
import { FilterConditionRow } from './filter-condition'

interface FilterBuilderProps {
  /** Callback when segment is saved */
  onSave?: (name: string, expression: FilterExpression) => void
  /** Initial expression to load (for editing) */
  initialExpression?: FilterExpression
  /** Segment ID if editing existing segment */
  editingSegmentId?: number | null
}

export function FilterBuilder({
  onSave,
  initialExpression,
  editingSegmentId = null
}: FilterBuilderProps) {
  const [expression, setExpression] = useState<FilterExpression>(
    initialExpression || createEmptyExpression()
  )
  const [segmentName, setSegmentName] = useState('')
  const [errors, setErrors] = useState<FilterBuilderError[]>([])

  const { updateFilterBuilder } = useSegmentsContext()

  // Save segment hooks - use existing API
  const { saveSegment, isSaving: isSavingNew } = useSaveSegment({
    onError: (error) => {
      setErrors([{
        type: 'field_required',
        path: '/save',
        message: error.message || 'Failed to save segment'
      }])
    }
  })

  const { updateSegment, isUpdating: isUpdatingSegment } = useUpdateSegment({
    onError: (error) => {
      setErrors([{
        type: 'field_required',
        path: '/save',
        message: error.message || 'Failed to update segment'
      }])
    }
  })

  const isSaving = isSavingNew || isUpdatingSegment

  const handleAddCondition = useCallback((groupId: string) => {
    const newCondition = createCondition()
    setExpression((prev) => {
      const newExpr = addConditionToGroup(prev.rootGroup, groupId, newCondition)
      return { ...prev, rootGroup: newExpr }
    })
  }, [])

  const handleUpdateCondition = useCallback((
    groupId: string,
    conditionId: string,
    updates: Partial<FilterCondition>
  ) => {
    setExpression((prev) => {
      const newExpr = updateConditionInGroup(prev.rootGroup, groupId, conditionId, updates)
      return { ...prev, rootGroup: newExpr }
    })
  }, [])

  const handleRemoveCondition = useCallback((groupId: string, conditionId: string) => {
    setExpression((prev) => {
      const newExpr = removeConditionFromGroup(prev.rootGroup, groupId, conditionId)
      return { ...prev, rootGroup: newExpr }
    })
  }, [])

  const handleAddGroup = useCallback((parentGroupId: string) => {
    const newGroup: ConditionGroup = {
      id: generateId(),
      operator: 'AND',
      conditions: []
    }
    setExpression((prev) => {
      const newExpr = addNestedGroupToGroup(prev.rootGroup, parentGroupId, newGroup)
      return { ...prev, rootGroup: newExpr }
    })
  }, [])

  const handleUpdateGroupOperator = useCallback((groupId: string, operator: LogicalOperator) => {
    setExpression((prev) => {
      const newExpr = updateOperatorInGroup(prev.rootGroup, groupId, operator)
      return { ...prev, rootGroup: newExpr }
    })
  }, [])

  const handleRemoveGroup = useCallback((groupId: string) => {
    // Can't remove root group
    if (groupId === expression.rootGroup.id) return

    setExpression((prev) => {
      const newExpr = removeNestedGroup(prev.rootGroup, groupId)
      return { ...prev, rootGroup: newExpr }
    })
  }, [expression.rootGroup.id])

  const handleSave = useCallback(async () => {
    // Validate
    const validationErrors = validateExpression(expression)
    if (validationErrors.length > 0) {
      setErrors(validationErrors)
      return
    }

    if (!segmentName.trim()) {
      setErrors([{
        type: 'field_required',
        path: '/name',
        message: 'Please enter a segment name'
      }])
      return
    }

    // If custom onSave is provided, use it
    if (onSave) {
      await onSave(segmentName, expression)
      setErrors([])
      return
    }

    // Use existing API to save segment
    // Default to 'personal' segment type
    const segmentType: 'personal' | 'site' = 'personal'

    // If editing existing segment, update it; otherwise create new
    if (editingSegmentId) {
      updateSegment(editingSegmentId, segmentName, segmentType, expression)
    } else {
      saveSegment(segmentName, segmentType, expression)
    }

    // Clear errors on success (errors handled by hooks)
    setErrors([])
  }, [expression, segmentName, onSave, editingSegmentId, saveSegment, updateSegment])

  const isValid = errors.length === 0 && validateExpression(expression).length === 0
  const canSave = segmentName.trim().length > 0 && isValid

  return (
    <div className="filter-builder">
      {/* Header */}
      <div className="filter-builder__header">
        <h3>Filter Builder</h3>
        {expression.rootGroup.conditions.length > 0 && (
          <p className="filter-builder__summary">
            {expressionToHumanString(expression)}
          </p>
        )}
      </div>

      {/* Segment Name Input */}
      <div className="filter-builder__name-input">
        <label htmlFor="segment-name">Segment Name</label>
        <input
          id="segment-name"
          type="text"
          value={segmentName}
          onChange={(e) => setSegmentName(e.target.value)}
          placeholder="Enter segment name..."
          disabled={isSaving}
        />
      </div>

      {/* Errors */}
      {errors.length > 0 && (
        <div className="filter-builder__errors">
          {errors.map((error, index) => (
            <div key={index} className="filter-builder__error">
              {error.message}
            </div>
          ))}
        </div>
      )}

      {/* Empty State - shown when no conditions exist */}
      {expression.rootGroup.conditions.length === 0 && (
        <div className="flex flex-col items-center justify-center py-12 px-6 text-center border-2 border-dashed border-gray-200 rounded-lg bg-gray-50">
          <div className="text-gray-400 mb-4">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={1.5}
              stroke="currentColor"
              className="w-12 h-12"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 3c2.755 0 5.455.232 8.083.678.93.162 1.58.985 1.58 1.91v5.857c0 .925-.65 1.748-1.58 1.91-2.628.447-5.328.679-8.083.679s-5.455-.232-8.083-.678c-.93-.162-1.58-.985-1.58-1.91V5.61c0-.925.65-1.748 1.58-1.91C6.545 3.232 9.245 3 12 3zM12 9a3 3 0 100 6 3 3 0 000-6z"
              />
            </svg>
          </div>
          <h4 className="text-lg font-semibold text-gray-900 mb-2">No filter conditions</h4>
          <p className="text-gray-500 mb-6 max-w-sm">
            Create a visitor segment by adding conditions to filter your traffic data.
            For example, filter for visitors from a specific country or page.
          </p>
          <button
            className="inline-flex items-center px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors font-medium"
            onClick={() => handleAddCondition(expression.rootGroup.id)}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              className="w-5 h-5 mr-2"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 4.5v15m7.5-7.5h-15"
              />
            </svg>
            Add your first condition
          </button>
        </div>
      )}

      {/* Filter Groups - shown when there are conditions */}
      {expression.rootGroup.conditions.length > 0 && (
        <div className="filter-builder__groups">
          <ConditionGroupComponent
            group={expression.rootGroup}
            onAddCondition={handleAddCondition}
            onUpdateCondition={handleUpdateCondition}
            onRemoveCondition={handleRemoveCondition}
            onAddGroup={handleAddGroup}
            onUpdateGroupOperator={handleUpdateGroupOperator}
            onRemoveGroup={handleRemoveGroup}
            isRoot={true}
            errors={errors}
            conditionPath="/rootGroup"
          />
        </div>
      )}

      {/* Save Button */}
      <div className="filter-builder__actions">
        <button
          className="filter-builder__save-btn"
          onClick={handleSave}
          disabled={!canSave || isSaving}
        >
          {isSaving ? 'Saving...' : 'Save Segment'}
        </button>
        {editingSegmentId && (
          <button
            className="filter-builder__save-as-new-btn"
            onClick={() => {
              updateFilterBuilder({ editingSegmentId: null })
              handleSave()
            }}
            disabled={!canSave || isSaving}
          >
            Save as New
          </button>
        )}
      </div>
    </div>
  )
}

// Helper functions
function addConditionToGroup(rootGroup: ConditionGroup, groupId: string, condition: FilterCondition): ConditionGroup {
  if (rootGroup.id === groupId) {
    return { ...rootGroup, conditions: [...rootGroup.conditions, condition] }
  }
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return addConditionToGroup(c as ConditionGroup, groupId, condition)
    })
  }
}

function updateConditionInGroup(rootGroup: ConditionGroup, groupId: string, conditionId: string, updates: Partial<FilterCondition>): ConditionGroup {
  if (rootGroup.id === groupId) {
    return {
      ...rootGroup,
      conditions: rootGroup.conditions.map((c) => {
        if ('field' in c && (c as FilterCondition).id === conditionId) {
          return { ...c, ...updates }
        }
        return c
      })
    }
  }
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return updateConditionInGroup(c as ConditionGroup, groupId, conditionId, updates)
    })
  }
}

function removeConditionFromGroup(rootGroup: ConditionGroup, groupId: string, conditionId: string): ConditionGroup {
  if (rootGroup.id === groupId) {
    return {
      ...rootGroup,
      conditions: rootGroup.conditions.filter((c) => {
        if ('field' in c) return (c as FilterCondition).id !== conditionId
        return (c as ConditionGroup).id !== conditionId
      })
    }
  }
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return removeConditionFromGroup(c as ConditionGroup, groupId, conditionId)
    })
  }
}

function addNestedGroupToGroup(rootGroup: ConditionGroup, parentGroupId: string, nestedGroup: ConditionGroup): ConditionGroup {
  if (rootGroup.id === parentGroupId) {
    return { ...rootGroup, conditions: [...rootGroup.conditions, nestedGroup] }
  }
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return addNestedGroupToGroup(c as ConditionGroup, parentGroupId, nestedGroup)
    })
  }
}

function updateOperatorInGroup(rootGroup: ConditionGroup, groupId: string, operator: LogicalOperator): ConditionGroup {
  if (rootGroup.id === groupId) {
    return { ...rootGroup, operator }
  }
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return updateOperatorInGroup(c as ConditionGroup, groupId, operator)
    })
  }
}

function removeNestedGroup(rootGroup: ConditionGroup, groupId: string): ConditionGroup {
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.filter((c) => {
      if ('field' in c) return true
      return (c as ConditionGroup).id !== groupId
    }).map((c) => {
      if ('field' in c) return c
      return removeNestedGroup(c as ConditionGroup, groupId)
    })
  }
}

export default FilterBuilder
