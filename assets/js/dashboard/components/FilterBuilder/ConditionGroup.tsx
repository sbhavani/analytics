import React, { useCallback, useRef } from 'react'
import classNames from 'classnames'
import { useVirtualizer } from '@tanstack/react-virtual'
import { ConditionGroup as ConditionGroupType, ConnectorType } from '../../lib/filter-parser'
import { ConditionRow } from './ConditionRow'

// Threshold for using virtualization - use virtual list for 10+ conditions
const VIRTUALIZATION_THRESHOLD = 10

interface ConditionGroupProps {
  group: ConditionGroupType
  onUpdateCondition: (conditionId: string, updates: Partial<ConditionGroupType['conditions'][0]>) => void
  onRemoveCondition: (conditionId: string) => void
  onAddCondition: () => void
  onToggleConnector: () => void
  onAddGroup: () => void
  onRemoveGroup?: () => void
  onGroupConditions: (conditionIds: string[]) => void
  selectedConditionIds: string[]
  onToggleConditionSelection: (conditionId: string) => void
  canAddGroup: boolean
  canGroup: boolean
  level?: number
  loading?: boolean
}

// Memoized comparison function for ConditionGroup
const conditionGroupPropsAreEqual = (
  prevProps: ConditionGroupProps,
  nextProps: ConditionGroupProps
): boolean => {
  // Check group changes
  if (prevProps.group.id !== nextProps.group.id) return false
  if (prevProps.group.connector !== nextProps.group.connector) return false
  if (prevProps.group.conditions.length !== nextProps.group.conditions.length) return false
  if (prevProps.group.children.length !== nextProps.group.children.length) return false

  // Check each condition for changes
  for (let i = 0; i < prevProps.group.conditions.length; i++) {
    const prevCond = prevProps.group.conditions[i]
    const nextCond = nextProps.group.conditions[i]
    if (
      prevCond.id !== nextCond.id ||
      prevCond.dimension !== nextCond.dimension ||
      prevCond.operator !== nextCond.operator ||
      JSON.stringify(prevCond.value) !== JSON.stringify(nextCond.value)
    ) {
      return false
    }
  }

  // Check selected IDs
  if (prevProps.selectedConditionIds.length !== nextProps.selectedConditionIds.length) return false
  for (const id of prevProps.selectedConditionIds) {
    if (!nextProps.selectedConditionIds.includes(id)) return false
  }

  return (
    prevProps.canAddGroup === nextProps.canAddGroup &&
    prevProps.canGroup === nextProps.canGroup &&
    prevProps.level === nextProps.level &&
    prevProps.loading === nextProps.loading
  )
}

export const ConditionGroup = React.memo<ConditionGroupProps>(({
  group,
  onUpdateCondition,
  onRemoveCondition,
  onAddCondition,
  onToggleConnector,
  onAddGroup,
  onRemoveGroup,
  onGroupConditions,
  selectedConditionIds,
  onToggleConditionSelection,
  canAddGroup,
  canGroup,
  level = 0,
  loading = false
}) => {
  const hasConditions = group.conditions.length > 0 || group.children.length > 0
  const shouldVirtualize = group.conditions.length >= VIRTUALIZATION_THRESHOLD

  // Ref for the container element (used for virtualization)
  const parentRef = useRef<HTMLDivElement>(null)

  // Virtualizer for large condition lists (20+ conditions)
  const virtualizer = useVirtualizer({
    count: group.conditions.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 60, // Estimated height of each ConditionRow
    overscan: 3, // Render 3 extra items above/below viewport
    enabled: shouldVirtualize
  })

  // Memoize handler to prevent unnecessary re-renders
  const handleConditionClick = useCallback((conditionId: string) => {
    onToggleConditionSelection(conditionId)
  }, [onToggleConditionSelection])

  // Memoize wrapped handlers for ConditionRow
  const handleUpdateCondition = useCallback((conditionId: string, updates: Partial<ConditionGroupType['conditions'][0]>) => {
    onUpdateCondition(conditionId, updates)
  }, [onUpdateCondition])

  const handleRemoveCondition = useCallback((conditionId: string) => {
    onRemoveCondition(conditionId)
  }, [onRemoveCondition])

  // Render a single condition row (used by both virtualized and non-virtualized modes)
  const renderConditionRow = useCallback((condition: ConditionGroupType['conditions'][0], index: number) => {
    return (
      <div key={condition.id} className="relative" style={shouldVirtualize ? { height: virtualizer.getTotalSize() } : undefined}>
        {level === 0 && group.conditions.length > 1 && (
          <input
            type="checkbox"
            checked={selectedConditionIds.includes(condition.id)}
            onChange={() => handleConditionClick(condition.id)}
            className="absolute left-2 top-1/2 -translate-y-1/2 z-10"
            title="Select to group"
          />
        )}
        <div className={classNames(level === 0 && group.conditions.length > 1 && 'pl-6')}>
          <ConditionRow
            condition={condition}
            onUpdate={(updates) => handleUpdateCondition(condition.id, updates)}
            onRemove={() => handleRemoveCondition(condition.id)}
            loading={loading}
          />
        </div>
      </div>
    )
  }, [level, group.conditions.length, selectedConditionIds, handleConditionClick, handleUpdateCondition, handleRemoveCondition, loading, shouldVirtualize, virtualizer])

  return (
    <div
      className={classNames(
        'rounded-lg border',
        level > 0 && 'ml-6 border-l-4 border-l-indigo-300 dark:border-l-indigo-700',
        group.isRoot
          ? 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/50'
          : 'border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800'
      )}
    >
      <div className="p-3 space-y-3">
        {/* Group header with connector */}
        {!group.isRoot && (
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                Match
              </span>
              <button
                onClick={onToggleConnector}
                disabled={loading || (!hasConditions && level === 0)}
                className={classNames(
                  'px-3 py-1 rounded-md text-sm font-medium',
                  'transition-colors duration-150',
                  group.connector === 'and'
                    ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300'
                    : 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
                )}
              >
                {group.connector.toUpperCase()}
              </button>
              <span className="text-sm text-gray-500 dark:text-gray-400">
                of the following
              </span>
            </div>
            {onRemoveGroup && (
              <button
                onClick={onRemoveGroup}
                className="text-sm text-red-600 hover:text-red-700 dark:text-red-400"
              >
                Remove group
              </button>
            )}
          </div>
        )}

        {/* Root group connector */}
        {group.isRoot && group.conditions.length > 1 && (
          <div className="flex items-center justify-center py-2">
            <button
              onClick={onToggleConnector}
              disabled={loading}
              className={classNames(
                'px-4 py-1.5 rounded-md text-sm font-medium',
                'transition-colors duration-150',
                group.connector === 'and'
                  ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300'
                  : 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
              )}
            >
              {group.connector === 'and' ? 'AND' : 'OR'}
            </button>
          </div>
        )}

        {/* Conditions - use virtualization for 10+ conditions */}
        {shouldVirtualize ? (
          <div
            ref={parentRef}
            className="space-y-2"
            style={{ height: Math.min(group.conditions.length * 60, 400), overflow: 'auto' }}
          >
            <div
              style={{
                height: `${virtualizer.getTotalSize()}px`,
                width: '100%',
                position: 'relative',
              }}
            >
              {virtualizer.getVirtualItems().map((virtualItem) => {
                const condition = group.conditions[virtualItem.index]
                return (
                  <div
                    key={condition.id}
                    style={{
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      width: '100%',
                      transform: `translateY(${virtualItem.start}px)`,
                    }}
                    className="relative"
                  >
                    {level === 0 && group.conditions.length > 1 && (
                      <input
                        type="checkbox"
                        checked={selectedConditionIds.includes(condition.id)}
                        onChange={() => handleConditionClick(condition.id)}
                        className="absolute left-2 top-1/2 -translate-y-1/2 z-10"
                        title="Select to group"
                      />
                    )}
                    <div className={classNames(level === 0 && group.conditions.length > 1 && 'pl-6')}>
                      <ConditionRow
                        condition={condition}
                        onUpdate={(updates) => handleUpdateCondition(condition.id, updates)}
                        onRemove={() => handleRemoveCondition(condition.id)}
                        loading={loading}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        ) : (
          <div className="space-y-2">
            {group.conditions.map(condition => (
              <div key={condition.id} className="relative">
                {level === 0 && group.conditions.length > 1 && (
                  <input
                    type="checkbox"
                    checked={selectedConditionIds.includes(condition.id)}
                    onChange={() => handleConditionClick(condition.id)}
                    className="absolute left-2 top-1/2 -translate-y-1/2 z-10"
                    title="Select to group"
                  />
                )}
                <div className={classNames(level === 0 && group.conditions.length > 1 && 'pl-6')}>
                  <ConditionRow
                    condition={condition}
                    onUpdate={(updates) => handleUpdateCondition(condition.id, updates)}
                    onRemove={() => handleRemoveCondition(condition.id)}
                    loading={loading}
                  />
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Nested groups */}
        {group.children.map(child => (
          <ConditionGroup
            key={child.id}
            group={child}
            onUpdateCondition={onUpdateCondition}
            onRemoveCondition={onRemoveCondition}
            onAddCondition={onAddCondition}
            onToggleConnector={onToggleConnector}
            onAddGroup={onAddGroup}
            onRemoveGroup={() => {}}
            onGroupConditions={onGroupConditions}
            selectedConditionIds={selectedConditionIds}
            onToggleConditionSelection={onToggleConditionSelection}
            canAddGroup={canAddGroup}
            canGroup={canGroup}
            level={level + 1}
            loading={loading}
          />
        ))}

        {/* Actions */}
        <div className="flex items-center gap-2 pt-2">
          <button
            onClick={onAddCondition}
            disabled={loading}
            className={classNames(
              'text-sm font-medium text-indigo-600 hover:text-indigo-700',
              'dark:text-indigo-400 dark:hover:text-indigo-300',
              'transition-colors duration-150'
            )}
          >
            + Add condition
          </button>

          {canAddGroup && (
            <button
              onClick={onAddGroup}
              disabled={loading}
              className={classNames(
                'text-sm font-medium text-indigo-600 hover:text-indigo-700',
                'dark:text-indigo-400 dark:hover:text-indigo-300',
                'transition-colors duration-150'
              )}
            >
              + Add group
            </button>
          )}

          {canGroup && selectedConditionIds.length >= 2 && (
            <button
              onClick={() => onGroupConditions(selectedConditionIds)}
              disabled={loading}
              className={classNames(
                'text-sm font-medium text-indigo-600 hover:text-indigo-700',
                'dark:text-indigo-400 dark:hover:text-indigo-300',
                'transition-colors duration-150'
              )}
            >
              + Group selected ({selectedConditionIds.length})
            </button>
          )}
        </div>
      </div>
    </div>
  )
}, conditionGroupPropsAreEqual)

export default ConditionGroup
