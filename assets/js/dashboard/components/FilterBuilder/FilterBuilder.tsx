import React, { useState, useCallback } from 'react'
import classNames from 'classnames'
import { useFilterBuilder } from '../../hooks/useFilterBuilder'
import { ConditionGroup } from './ConditionGroup'
import { FilterPreview } from './FilterPreview'
import { SavedSegment, SegmentType } from '../../filtering/segments'

interface FilterBuilderProps {
  siteId: string
  initialTree?: ReturnType<typeof useFilterBuilder>['filterTree']
  existingSegments?: SavedSegment[]
  onSave?: (tree: ReturnType<typeof useFilterBuilder>['filterTree'], name: string, type: SegmentType) => Promise<void>
  onLoad?: (segment: SavedSegment) => void
  onClose?: () => void
}

export const FilterBuilder: React.FC<FilterBuilderProps> = ({
  siteId,
  initialTree,
  existingSegments = [],
  onSave,
  onLoad,
  onClose
}) => {
  const [loading, setLoading] = useState(false)
  const [showSaveForm, setShowSaveForm] = useState(false)
  const [segmentName, setSegmentName] = useState('')
  const [segmentType, setSegmentType] = useState<SegmentType>(SegmentType.personal)
  const [selectedConditionIds, setSelectedConditionIds] = useState<string[]>([])
  const [showLoadMenu, setShowLoadMenu] = useState(false)

  const {
    filterTree,
    isValid,
    validationErrors,
    isDirty,
    addCondition,
    removeCondition,
    updateCondition,
    addGroup,
    removeGroup,
    toggleConnector,
    groupConditions,
    reset,
    setFilterTree
  } = useFilterBuilder({
    initialTree,
    maxConditions: 20,
    maxDepth: 3
  })

  const canAddGroup = filterTree.rootGroup.children.length < 2
  const canGroup = selectedConditionIds.length >= 2

  const handleSave = useCallback(async () => {
    if (!segmentName.trim() || !onSave) return

    setLoading(true)
    try {
      await onSave(filterTree, segmentName.trim(), segmentType)
      setShowSaveForm(false)
      setSegmentName('')
    } catch (error) {
      console.error('Failed to save segment:', error)
    } finally {
      setLoading(false)
    }
  }, [filterTree, segmentName, segmentType, onSave])

  const handleLoad = useCallback((segment: SavedSegment) => {
    // Convert saved segment to filter tree
    // This would need to use the backendToFilterTree function
    setShowLoadMenu(false)
    onLoad?.(segment)
  }, [onLoad])

  const handleAddCondition = useCallback(() => {
    addCondition()
  }, [addCondition])

  const handleUpdateCondition = useCallback((
    conditionId: string,
    updates: Parameters<typeof updateCondition>[1]
  ) => {
    updateCondition(conditionId, updates)
  }, [updateCondition])

  const handleRemoveCondition = useCallback((conditionId: string) => {
    removeCondition(conditionId)
    setSelectedConditionIds(prev => prev.filter(id => id !== conditionId))
  }, [removeCondition])

  const handleToggleConnector = useCallback(() => {
    toggleConnector(filterTree.rootGroup.id)
  }, [toggleConnector, filterTree.rootGroup.id])

  const handleAddGroup = useCallback(() => {
    addGroup()
  }, [addGroup])

  const handleGroupConditions = useCallback((conditionIds: string[]) => {
    groupConditions(conditionIds)
    setSelectedConditionIds([])
  }, [groupConditions])

  const handleToggleConditionSelection = useCallback((conditionId: string) => {
    setSelectedConditionIds(prev =>
      prev.includes(conditionId)
        ? prev.filter(id => id !== conditionId)
        : [...prev, conditionId]
    )
  }, [])

  const handleReset = useCallback(() => {
    reset()
    setSelectedConditionIds([])
  }, [reset])

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-gray-700">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
          Advanced Filter Builder
        </h2>
        <div className="flex items-center gap-2">
          {existingSegments.length > 0 && (
            <div className="relative">
              <button
                onClick={() => setShowLoadMenu(!showLoadMenu)}
                className={classNames(
                  'px-3 py-1.5 text-sm font-medium rounded-md',
                  'border border-gray-300 dark:border-gray-600',
                  'text-gray-700 dark:text-gray-300',
                  'hover:bg-gray-50 dark:hover:bg-gray-800',
                  'transition-colors duration-150'
                )}
              >
                Load Template
              </button>
              {showLoadMenu && (
                <div className="absolute right-0 mt-1 w-64 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg z-10">
                  <div className="py-1 max-h-64 overflow-y-auto">
                    {existingSegments.map(segment => (
                      <button
                        key={segment.id}
                        onClick={() => handleLoad(segment)}
                        className="w-full px-4 py-2 text-left text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                      >
                        <div className="font-medium">{segment.name}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          {segment.type === SegmentType.personal ? 'Personal' : 'Site'} segment
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
          <button
            onClick={onClose}
            className={classNames(
              'p-1.5 rounded-md',
              'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300',
              'hover:bg-gray-100 dark:hover:bg-gray-800',
              'transition-colors duration-150'
            )}
          >
            <span className="sr-only">Close</span>
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4">
        {/* Filter Builder */}
        <ConditionGroup
          group={filterTree.rootGroup}
          onUpdateCondition={handleUpdateCondition}
          onRemoveCondition={handleRemoveCondition}
          onAddCondition={handleAddCondition}
          onToggleConnector={handleToggleConnector}
          onAddGroup={handleAddGroup}
          onRemoveGroup={undefined}
          onGroupConditions={handleGroupConditions}
          selectedConditionIds={selectedConditionIds}
          onToggleConditionSelection={handleToggleConditionSelection}
          canAddGroup={canAddGroup}
          canGroup={canGroup}
          loading={loading}
        />

        {/* Validation errors */}
        {!isValid && validationErrors.length > 0 && (
          <div className="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
            <h4 className="text-sm font-medium text-red-800 dark:text-red-300">
              Validation Errors
            </h4>
            <ul className="mt-1 list-disc list-inside text-sm text-red-700 dark:text-red-400">
              {validationErrors.map((error, idx) => (
                <li key={idx}>{error}</li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50">
        <div className="flex items-center gap-3">
          <FilterPreview
            filterTree={filterTree}
            siteId={siteId}
            loading={loading}
          />
        </div>

        <div className="flex items-center gap-2">
          {isDirty && (
            <button
              onClick={handleReset}
              disabled={loading}
              className={classNames(
                'px-3 py-1.5 text-sm font-medium rounded-md',
                'text-gray-700 dark:text-gray-300',
                'hover:bg-gray-100 dark:hover:bg-gray-800',
                'transition-colors duration-150'
              )}
            >
              Reset
            </button>
          )}

          <button
            onClick={() => setShowSaveForm(true)}
            disabled={!isValid || loading}
            className={classNames(
              'px-4 py-1.5 text-sm font-medium rounded-md',
              'bg-indigo-600 text-white',
              'hover:bg-indigo-700',
              'disabled:opacity-50 disabled:cursor-not-allowed',
              'transition-colors duration-150'
            )}
          >
            Save Segment
          </button>
        </div>
      </div>

      {/* Save Form Modal */}
      {showSaveForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md bg-white dark:bg-gray-800 rounded-lg shadow-xl p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
              Save Segment
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Segment Name
                </label>
                <input
                  type="text"
                  value={segmentName}
                  onChange={(e) => setSegmentName(e.target.value)}
                  placeholder="e.g., US Mobile Visitors"
                  className={classNames(
                    'w-full rounded-md border',
                    'border-gray-300 dark:border-gray-600',
                    'focus:ring-indigo-500 focus:border-indigo-500',
                    'dark:bg-gray-700 dark:text-gray-200'
                  )}
                  autoFocus
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Segment Type
                </label>
                <select
                  value={segmentType}
                  onChange={(e) => setSegmentType(e.target.value as SegmentType)}
                  className={classNames(
                    'w-full rounded-md border',
                    'border-gray-300 dark:border-gray-600',
                    'focus:ring-indigo-500 focus:border-indigo-500',
                    'dark:bg-gray-700 dark:text-gray-200'
                  )}
                >
                  <option value={SegmentType.personal}>Personal Segment</option>
                  <option value={SegmentType.site}>Site Segment</option>
                </select>
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                onClick={() => setShowSaveForm(false)}
                className={classNames(
                  'px-4 py-2 text-sm font-medium rounded-md',
                  'text-gray-700 dark:text-gray-300',
                  'hover:bg-gray-100 dark:hover:bg-gray-800',
                  'transition-colors duration-150'
                )}
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={!segmentName.trim() || loading}
                className={classNames(
                  'px-4 py-2 text-sm font-medium rounded-md',
                  'bg-indigo-600 text-white',
                  'hover:bg-indigo-700',
                  'disabled:opacity-50 disabled:cursor-not-allowed',
                  'transition-colors duration-150'
                )}
              >
                {loading ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default FilterBuilder
