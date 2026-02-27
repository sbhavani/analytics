import React, { useState, useCallback } from 'react'
import {
  FilterTree,
  FilterGroupNode,
  FilterConditionNode,
  FilterBuilderState,
  SavedSegment,
  PreviewResult
} from '../lib/types/filter-tree'
import {
  createEmptyTree,
  createEmptyGroup,
  createCondition,
  addCondition,
  removeCondition,
  updateCondition,
  addGroup,
  countConditions
} from '../lib/filter-tree'
import { previewSegment } from '../lib/api/segments'
import FilterGroup from './FilterGroup'
import SegmentPreview from './SegmentPreview'

interface FilterBuilderProps {
  siteId: string
  initialTree?: FilterTree
  savedSegments?: SavedSegment[]
  onSave?: (name: string, tree: FilterTree) => Promise<void>
  onCancel?: () => void
}

export const FilterBuilder: React.FC<FilterBuilderProps> = ({
  siteId,
  initialTree,
  savedSegments = [],
  onSave,
  onCancel
}) => {
  const [state, setState] = useState<FilterBuilderState>({
    tree: initialTree || createEmptyTree(),
    isDirty: false,
    lastSaved: null,
    previewStatus: 'idle',
    validationErrors: []
  })

  const [previewResult, setPreviewResult] = useState<PreviewResult | null>(null)
  const [previewError, setPreviewError] = useState<string | null>(null)

  const handleAddCondition = useCallback(() => {
    const newCondition = createCondition()
    const newTree = addCondition(state.tree, state.tree.root.id, newCondition)
    setState(prev => ({
      ...prev,
      tree: newTree,
      isDirty: true
    }))
  }, [state.tree])

  const handleAddGroup = useCallback(() => {
    const newGroup = createEmptyGroup('and')
    const newTree = addGroup(state.tree, state.tree.root.id, newGroup)
    setState(prev => ({
      ...prev,
      tree: newTree,
      isDirty: true
    }))
  }, [state.tree])

  const handleUpdateCondition = useCallback((conditionId: string, updates: Partial<FilterConditionNode>) => {
    const newTree = updateCondition(state.tree, conditionId, updates)
    setState(prev => ({
      ...prev,
      tree: newTree,
      isDirty: true
    }))
  }, [state.tree])

  const handleRemoveCondition = useCallback((conditionId: string) => {
    const newTree = removeCondition(state.tree, conditionId)
    setState(prev => ({
      ...prev,
      tree: newTree,
      isDirty: true
    }))
  }, [state.tree])

  const handlePreview = useCallback(async () => {
    setState(prev => ({ ...prev, previewStatus: 'loading' }))
    setPreviewError(null)

    try {
      const result = await previewSegment(siteId, state.tree)
      setPreviewResult(result)
      setState(prev => ({ ...prev, previewStatus: 'success' }))
    } catch      const message = error instanceof Error ? (error) {
 error.message : 'Failed to preview segment'
      setPreviewError(message)
      setState(prev => ({ ...prev, previewStatus: 'error' }))
    }
  }, [siteId, state.tree])

  const handleSave = useCallback(async (name: string) => {
    if (onSave) {
      await onSave(name, state.tree)
      setState(prev => ({
        ...prev,
        isDirty: false,
        lastSaved: new Date()
      }))
    }
  }, [onSave, state.tree])

  const hasConditions = countConditions(state.tree) > 0

  return (
    <div className="filter-builder max-w-4xl mx-auto p-4">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Advanced Filter Builder</h2>
        <div className="flex gap-2">
          <button
            onClick={handlePreview}
            disabled={!hasConditions || state.previewStatus === 'loading'}
            className="px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-md disabled:opacity-50"
          >
            {state.previewStatus === 'loading' ? 'Loading...' : 'Preview'}
          </button>
          {onCancel && (
            <button
              onClick={onCancel}
              className="px-4 py-2 border rounded-md hover:bg-gray-50"
            >
              Cancel
            </button>
          )}
          {onSave && (
            <button
              onClick={() => handleSave('Untitled Segment')}
              disabled={!hasConditions}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              Save Segment
            </button>
          )}
        </div>
      </div>

      {/* Preview Error */}
      {previewError && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700">
          {previewError}
        </div>
      )}

      {/* Empty State */}
      {!hasConditions && (
        <div className="text-center py-12 bg-gray-50 rounded-lg mb-4">
          <p className="text-gray-500 mb-4">No filter conditions yet</p>
          <button
            onClick={handleAddCondition}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Add Your First Condition
          </button>
        </div>
      )}

      {/* Filter Tree Editor */}
      {hasConditions && (
        <div className="mb-4">
          <FilterGroup
            group={state.tree.root}
            onChange={(updated) => setState(prev => ({ ...prev, tree: { ...prev.tree, root: updated }, isDirty: true }))}
            siteId={siteId}
            depth={0}
            onAddCondition={handleAddCondition}
            onAddGroup={handleAddGroup}
            onRemoveCondition={handleRemoveCondition}
            onUpdateCondition={handleUpdateCondition}
          />
        </div>
      )}

      {/* Preview Panel */}
      {previewResult && state.previewStatus === 'success' && (
        <SegmentPreview result={previewResult} />
      )}

      {/* Saved Segments */}
      {savedSegments.length > 0 && (
        <div className="mt-6">
          <h3 className="text-lg font-medium mb-2">Saved Segments</h3>
          <div className="grid grid-cols-2 gap-2">
            {savedSegments.map(segment => (
              <button
                key={segment.id}
                onClick={() => {
                  if (segment.filter_tree) {
                    setState(prev => ({
                      ...prev,
                      tree: segment.filter_tree,
                      isDirty: false
                    }))
                  }
                }}
                className="p-3 text-left border rounded-md hover:bg-gray-50"
              >
                <div className="font-medium">{segment.name}</div>
                <div className="text-sm text-gray-500">
                  {segment.filter_tree ? 'Custom filter' : 'Basic filter'}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default FilterBuilder
