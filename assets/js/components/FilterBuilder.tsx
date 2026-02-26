import React, { useState, useCallback, useEffect } from 'react'
import { FilterGroup, FilterGroupData } from './FilterGroup'
import { FilterField } from './FilterCondition'

const DEFAULT_FIELDS: FilterField[] = [
  { name: 'country', displayName: 'Country', dataType: 'string', operators: ['equals', 'not_equals', 'contains', 'is_empty', 'is_not_empty'], options: ['United States', 'United Kingdom', 'Germany', 'France', 'Canada'] },
  { name: 'pages_visited', displayName: 'Pages Visited', dataType: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than'] },
  { name: 'session_duration', displayName: 'Session Duration', dataType: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than'] },
  { name: 'total_spent', displayName: 'Total Spent', dataType: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than'] },
  { name: 'device_type', displayName: 'Device Type', dataType: 'string', operators: ['equals', 'not_equals', 'is_empty', 'is_not_empty'], options: ['Desktop', 'Mobile', 'Tablet'] },
  { name: 'referrer_source', displayName: 'Referrer Source', dataType: 'string', operators: ['equals', 'not_equals', 'contains', 'is_empty', 'is_not_empty'] }
]

const MAX_CONDITIONS = 10
const MAX_NESTING = 3
const PREVIEW_TIMEOUT_MS = 15000  // 15 seconds client-side timeout

function generateId(): string {
  return Math.random().toString(36).substring(2, 15)
}

interface FilterCondition {
  id: string
  field: string
  operator: string
  value: string
}

interface FilterTree {
  id: string
  operator: 'AND' | 'OR'
  conditions: FilterCondition[]
  groups: FilterTree[]
}

interface ValidationError {
  conditionId?: string
  field?: string
  message: string
}

interface FilterBuilderProps {
  siteId: string
  initialFilterTree?: FilterTree
  segmentId?: string
  onSave?: (filterTree: FilterTree, name: string) => Promise<void>
  onPreview?: (filterTree: FilterTree) => Promise<number>
}

export function FilterBuilder({
  siteId,
  initialFilterTree,
  segmentId,
  onSave,
  onPreview
}: FilterBuilderProps) {
  const [filterTree, setFilterTree] = useState<FilterTree>(() => {
    if (initialFilterTree) {
      return initialFilterTree
    }
    return {
      id: 'root',
      operator: 'AND',
      conditions: [],
      groups: []
    }
  })
  const [availableFields] = useState<FilterField[]>(DEFAULT_FIELDS)
  const [visitorCount, setVisitorCount] = useState<number | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isLoadingSlow, setIsLoadingSlow] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([])
  const [showSaveModal, setShowSaveModal] = useState(false)
  const [segmentName, setSegmentName] = useState('')
  const [timeoutError, setTimeoutError] = useState(false)

  // Validate a single condition
  const validateCondition = (condition: { id: string; field: string; operator: string; value: string }): ValidationError | null => {
    if (!condition.field || condition.field.trim() === '') {
      return { conditionId: condition.id, field: 'field', message: 'Please select a field' }
    }
    if (!condition.operator || condition.operator.trim() === '') {
      return { conditionId: condition.id, field: 'operator', message: 'Please select an operator' }
    }
    // Check if value is required for the operator
    const needsValue = !['is_empty', 'is_not_empty'].includes(condition.operator)
    if (needsValue && (!condition.value || condition.value.trim() === '')) {
      return { conditionId: condition.id, field: 'value', message: 'Please enter a value' }
    }
    return null
  }

  // Validate entire filter tree
  const validateFilterTree = (tree: FilterTree): ValidationError[] => {
    const errors: ValidationError[] = []

    // Check conditions
    for (const condition of tree.conditions) {
      const error = validateCondition(condition)
      if (error) {
        errors.push(error)
      }
    }

    // Check nested groups recursively
    for (const group of tree.groups) {
      const groupErrors = validateFilterTree(group)
      errors.push(...groupErrors)
    }

    return errors
  }

  // Check if filter tree has at least one valid condition
  const hasValidConditions = (tree: FilterTree): boolean => {
    if (tree.conditions.length === 0 && tree.groups.length === 0) {
      return false
    }

    // Check if at least one condition is complete (has field, operator, and value if needed)
    for (const condition of tree.conditions) {
      if (condition.field && condition.operator) {
        const needsValue = !['is_empty', 'is_not_empty'].includes(condition.operator)
        if (!needsValue || condition.value) {
          return true
        }
      }
    }

    // Check nested groups
    for (const group of tree.groups) {
      if (hasValidConditions(group)) {
        return true
      }
    }

    return false
  }

  // Validate filter tree before preview or save
  const validateBeforeAction = (): boolean => {
    const errors = validateFilterTree(filterTree)

    if (errors.length > 0) {
      setValidationErrors(errors)
      setError('Please fix the invalid filter conditions before continuing')
      return false
    }

    if (!hasValidConditions(filterTree)) {
      setError('Please add at least one complete filter condition')
      return false
    }

    setValidationErrors([])
    setError(null)
    return true
  }

  // Count total conditions
  const countConditions = useCallback((tree: FilterTree): number => {
    let count = tree.conditions.length
    for (const group of tree.groups) {
      count += countConditions(group)
    }
    return count
  }, [])

  const totalConditions = countConditions(filterTree)
  const canAddCondition = totalConditions < MAX_CONDITIONS

  // Calculate nesting depth
  const calculateDepth = useCallback((tree: FilterTree, depth = 0): number => {
    if (tree.groups.length === 0) return depth
    return Math.max(...tree.groups.map(g => calculateDepth(g, depth + 1)))
  }, [])

  const currentDepth = calculateDepth(filterTree)
  const canAddGroup = currentDepth < MAX_NESTING

  // Handlers
  const handleAddCondition = () => {
    if (!canAddCondition) {
      setError(`Maximum ${MAX_CONDITIONS} conditions allowed`)
      return
    }

    const newCondition = {
      id: generateId(),
      field: '',
      operator: '',
      value: ''
    }

    setFilterTree(prev => ({
      ...prev,
      conditions: [...prev.conditions, newCondition]
    }))
    setError(null)
  }

  const handleRemoveCondition = (conditionId: string) => {
    setFilterTree(prev => ({
      ...prev,
      conditions: prev.conditions.filter(c => c.id !== conditionId)
    }))
  }

  const handleUpdateCondition = (conditionId: string, updates: Partial<typeof filterTree.conditions[0]>) => {
    setFilterTree(prev => ({
      ...prev,
      conditions: prev.conditions.map(c =>
        c.id === conditionId ? { ...c, ...updates } : c
      )
    }))
  }

  const handleChangeOperator = (operator: 'AND' | 'OR') => {
    setFilterTree(prev => ({
      ...prev,
      operator
    }))
  }

  const handleAddGroup = () => {
    if (!canAddGroup) {
      setError(`Maximum ${MAX_NESTING} nesting levels allowed`)
      return
    }

    const newGroup: FilterTree = {
      id: generateId(),
      operator: 'AND',
      conditions: [],
      groups: []
    }

    setFilterTree(prev => ({
      ...prev,
      groups: [...prev.groups, newGroup]
    }))
    setError(null)
  }

  const handleRemoveGroup = (groupId: string) => {
    setFilterTree(prev => ({
      ...prev,
      groups: prev.groups.filter(g => g.id !== groupId)
    }))
  }

  // Helper to find and update a nested group
  const updateNestedGroup = (
    tree: FilterTree,
    parentId: string,
    nestedGroupId: string,
    updater: (group: FilterTree) => FilterTree
  ): FilterTree => {
    if (tree.id === parentId) {
      return {
        ...tree,
        groups: tree.groups.map(g =>
          g.id === nestedGroupId ? updater(g) : g
        )
      }
    }
    return {
      ...tree,
      groups: tree.groups.map(g => updateNestedGroup(g, parentId, nestedGroupId, updater))
    }
  }

  const handleAddNestedGroup = (parentId: string) => {
    if (!canAddGroup) {
      setError(`Maximum ${MAX_NESTING} nesting levels allowed`)
      return
    }

    const newGroup: FilterTree = {
      id: generateId(),
      operator: 'AND',
      conditions: [],
      groups: []
    }

    if (filterTree.id === parentId) {
      setFilterTree(prev => ({
        ...prev,
        groups: [...prev.groups, newGroup]
      }))
    } else {
      setFilterTree(prev => updateNestedGroup(prev, parentId, '', (parent) => ({
        ...parent,
        groups: [...parent.groups, newGroup]
      })))
    }
    setError(null)
  }

  const handleRemoveNestedGroup = (parentId: string, nestedGroupId: string) => {
    if (filterTree.id === parentId) {
      setFilterTree(prev => ({
        ...prev,
        groups: prev.groups.filter(g => g.id !== nestedGroupId)
      }))
    } else {
      setFilterTree(prev => updateNestedGroup(prev, parentId, nestedGroupId, (parent) => ({
        ...parent,
        groups: parent.groups.filter(g => g.id !== nestedGroupId)
      })))
    }
  }

  const handleUpdateNestedGroup = (
    parentId: string,
    nestedGroupId: string,
    updates: Partial<FilterTree>
  ) => {
    if (filterTree.id === parentId) {
      setFilterTree(prev => ({
        ...prev,
        groups: prev.groups.map(g =>
          g.id === nestedGroupId ? { ...g, ...updates } : g
        )
      }))
    } else {
      setFilterTree(prev => updateNestedGroup(prev, parentId, nestedGroupId, (group) => ({
        ...group,
        ...updates
      })))
    }
  }

  // Add condition to nested group
  const addConditionToNestedGroup = (groupId: string): FilterTree => {
    const newCondition: FilterCondition = {
      id: generateId(),
      field: '',
      operator: '',
      value: ''
    }

    const addCondition = (tree: FilterTree): FilterTree => {
      if (tree.id === groupId) {
        return { ...tree, conditions: [...tree.conditions, newCondition] }
      }
      return {
        ...tree,
        groups: tree.groups.map(g => addCondition(g))
      }
    }

    return addCondition(filterTree)
  }

  // Remove condition from nested group
  const removeConditionFromNestedGroup = (parentId: string, conditionId: string): FilterTree => {
    const removeCondition = (tree: FilterTree): FilterTree => {
      if (tree.id === parentId) {
        return { ...tree, conditions: tree.conditions.filter(c => c.id !== conditionId) }
      }
      return {
        ...tree,
        groups: tree.groups.map(g => removeCondition(g))
      }
    }

    return removeCondition(filterTree)
  }

  // Update condition in nested group
  const updateConditionInNestedGroup = (
    parentId: string,
    conditionId: string,
    updates: Partial<FilterCondition>
  ): FilterTree => {
    const updateCondition = (tree: FilterTree): FilterTree => {
      if (tree.id === parentId) {
        return {
          ...tree,
          conditions: tree.conditions.map(c =>
            c.id === conditionId ? { ...c, ...updates } : c
          )
        }
      }
      return {
        ...tree,
        groups: tree.groups.map(g => updateCondition(g))
      }
    }

    return updateCondition(filterTree)
  }

  const handlePreview = async () => {
    if (!onPreview) return

    // Validate before preview
    if (!validateBeforeAction()) {
      return
    }

    setIsLoading(true)
    setError(null)
    setTimeoutError(false)

    // Start a timer to show "slow query" warning after 5 seconds
    const slowWarningTimer = setTimeout(() => {
      setIsLoadingSlow(true)
    }, 5000)

    // Start client-side timeout timer
    const timeoutTimer = setTimeout(() => {
      setTimeoutError(true)
      setIsLoading(false)
      setIsLoadingSlow(false)
    }, PREVIEW_TIMEOUT_MS)

    try {
      const count = await onPreview(filterTree)
      clearTimeout(slowWarningTimer)
      clearTimeout(timeoutTimer)
      setVisitorCount(count)
      setTimeoutError(false)
    } catch (err) {
      clearTimeout(slowWarningTimer)
      clearTimeout(timeoutTimer)

      // Check if it's a timeout error (from backend or client-side)
      const errMessage = err instanceof Error ? err.message : String(err)
      if (errMessage.includes('timeout') || timeoutError) {
        setError('Query timed out. Try using fewer conditions or a narrower date range.')
        setTimeoutError(true)
      } else {
        setError(errMessage || 'Failed to preview segment')
      }
      setVisitorCount(null)
    } finally {
      setIsLoading(false)
      setIsLoadingSlow(false)
    }
  }

  const handleSave = async () => {
    // Validate before save
    if (!validateBeforeAction()) {
      setShowSaveModal(false)
      return
    }

    if (!segmentName.trim()) {
      setError('Please enter a segment name')
      return
    }

    if (!onSave) {
      setError('Save functionality not configured')
      return
    }

    try {
      await onSave(filterTree, segmentName)
      setShowSaveModal(false)
      setSegmentName('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save segment')
    }
  }

  const handleLoadSegment = (segment: { filter_tree: FilterTree; name: string }) => {
    setFilterTree(segment.filter_tree)
    setSegmentName(segment.name)
  }

  // Load initial segment if provided
  useEffect(() => {
    if (initialFilterTree) {
      setFilterTree(initialFilterTree)
    }
  }, [initialFilterTree])

  return (
    <div className="filter-builder max-w-4xl mx-auto p-6">
      <h2 className="text-xl font-semibold mb-4">Advanced Filter Builder</h2>

      {/* Error Display */}
      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md" role="alert">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Filter Tree */}
      <div className="filter-tree space-y-3 mb-6">
        <FilterGroup
          group={{
            id: 'root',
            operator: filterTree.operator,
            conditions: filterTree.conditions,
            groups: filterTree.groups
          }}
          level={0}
          availableFields={availableFields}
          onAddCondition={handleAddCondition}
          onRemoveCondition={handleRemoveCondition}
          onUpdateCondition={handleUpdateCondition}
          onChangeOperator={handleChangeOperator}
          onAddGroup={handleAddGroup}
          onRemoveGroup={() => {}}
          onAddNestedGroup={handleAddNestedGroup}
          onRemoveNestedGroup={handleRemoveNestedGroup}
          onUpdateNestedGroup={handleUpdateNestedGroup}
          validationErrors={validationErrors}
        />
      </div>

      {/* Preview Section */}
      <div className="preview-section flex items-center gap-4 p-4 bg-gray-50 rounded-lg mb-6">
        <button
          onClick={handlePreview}
          disabled={isLoading || filterTree.conditions.length === 0}
          className={`preview-btn px-4 py-2 rounded-md text-white disabled:opacity-50 disabled:cursor-not-allowed ${
            timeoutError
              ? 'bg-amber-500 hover:bg-amber-600'
              : isLoadingSlow
              ? 'bg-indigo-500 hover:bg-indigo-600 animate-pulse'
              : 'bg-indigo-600 hover:bg-indigo-700'
          }`}
        >
          {timeoutError
            ? 'Query Timed Out'
            : isLoading
            ? isLoadingSlow
              ? 'Calculating (this may take a while)...'
              : 'Calculating...'
            : 'Preview Segment'}
        </button>

        {visitorCount !== null && (
          <div className="visitor-count">
            <span className="text-lg font-medium">{visitorCount.toLocaleString()}</span>
            <span className="text-gray-600 ml-2">visitors match this segment</span>
          </div>
        )}

        {/* Timeout error hint */}
        {timeoutError && (
          <div className="text-sm text-amber-600">
            Try using fewer conditions or a narrower date range
          </div>
        )}

        <div className="flex-1" />

        <span className="text-sm text-gray-500">
          {totalConditions}/{MAX_CONDITIONS} conditions
        </span>
      </div>

      {/* Actions */}
      <div className="actions flex gap-3">
        <button
          onClick={() => setShowSaveModal(true)}
          disabled={filterTree.conditions.length === 0}
          className="save-btn px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Save Segment
        </button>
      </div>

      {/* Save Modal */}
      {showSaveModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold mb-4">Save Segment</h3>
            <input
              type="text"
              value={segmentName}
              onChange={(e) => setSegmentName(e.target.value)}
              placeholder="Enter segment name..."
              className="w-full px-3 py-2 border rounded-md mb-4"
              autoFocus
            />
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowSaveModal(false)}
                className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-md"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export type { FilterTree }
