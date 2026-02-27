import { useCallback, useMemo, useState, useRef } from 'react'
import {
  FilterTree,
  FilterCondition,
  ConditionGroup,
  ConnectorType,
  createEmptyCondition,
  createEmptyGroup,
  createEmptyFilterTree,
  validateFilterTree
} from '../lib/filter-parser'

export interface UseFilterBuilderOptions {
  initialTree?: FilterTree
  onChange?: (tree: FilterTree) => void
  maxConditions?: number
  maxDepth?: number
}

export interface UseFilterBuilderReturn {
  // State
  filterTree: FilterTree
  isValid: boolean
  validationErrors: string[]
  isDirty: boolean

  // Condition operations
  addCondition: (groupId?: string) => void
  removeCondition: (conditionId: string, groupId?: string) => void
  updateCondition: (conditionId: string, updates: Partial<FilterCondition>, groupId?: string) => void

  // Group operations
  addGroup: (parentGroupId?: string) => void
  removeGroup: (groupId: string) => void
  toggleConnector: (groupId: string) => void

  // Grouping operations (combine conditions)
  groupConditions: (conditionIds: string[], groupId?: string) => void
  ungroupGroup: (groupId: string) => void

  // Reset
  reset: () => void
  setFilterTree: (tree: FilterTree) => void
}

// Efficient deep clone function - faster than JSON.parse(JSON.stringify(...))
function deepCloneFilterTree(tree: FilterTree): FilterTree {
  return {
    rootGroup: deepCloneGroup(tree.rootGroup),
    labels: { ...tree.labels }
  }
}

function deepCloneGroup(group: ConditionGroup): ConditionGroup {
  return {
    id: group.id,
    connector: group.connector,
    conditions: group.conditions.map(c => ({ ...c })),
    children: group.children.map(child => deepCloneGroup(child)),
    isRoot: group.isRoot
  }
}

export function useFilterBuilder({
  initialTree,
  onChange,
  maxConditions = 20,
  maxDepth = 3
}: UseFilterBuilderOptions = {}): UseFilterBuilderReturn {
  const [filterTree, setFilterTreeState] = useState<FilterTree>(
    initialTree || createEmptyFilterTree()
  )
  const [isDirty, setIsDirty] = useState(false)

  // Use ref for cache that can be cleared on tree changes
  const conditionCountCache = useRef<Map<string, number>>(new Map())
  const depthCache = useRef<Map<string, number>>(new Map())

  // Clear caches when tree changes
  const clearCaches = useCallback(() => {
    conditionCountCache.current.clear()
    depthCache.current.clear()
  }, [])

  // Optimized count conditions with caching
  const countConditions = useCallback((group: ConditionGroup): number => {
    const key = group.id
    if (conditionCountCache.current.has(key)) {
      return conditionCountCache.current.get(key)!
    }
    let count = group.conditions.length
    for (const child of group.children) {
      count += countConditions(child)
    }
    conditionCountCache.current.set(key, count)
    return count
  }, [])

  // Optimized get max depth with caching
  const getMaxDepth = useCallback((group: ConditionGroup): number => {
    const key = `depth-${group.id}`
    if (depthCache.current.has(key)) {
      return depthCache.current.get(key)!
    }
    let depth: number
    if (group.children.length === 0) {
      depth = 1
    } else {
      depth = 1 + Math.max(...group.children.map(child => getMaxDepth(child)), 0)
    }
    depthCache.current.set(key, depth)
    return depth
  }, [])

  // Get depth of specific group
  const getDepth = useCallback((group: ConditionGroup, targetId: string, depth: number = 0): number => {
    if (group.id === targetId) return depth
    for (const child of group.children) {
      const found = getDepth(child, targetId, depth + 1)
      if (found >= 0) return found
    }
    return -1
  }, [])

  // Validate on every change - memoized to avoid re-computation
  const { valid: isValid, errors: validationErrors } = useMemo(() => {
    return validateFilterTree(filterTree)
  }, [filterTree])

  // Notify parent of changes
  const handleChange = useCallback((newTree: FilterTree) => {
    setFilterTreeState(newTree)
    setIsDirty(true)
    clearCaches()
    onChange?.(newTree)
  }, [onChange, clearCaches])

  // Find a group by ID - memoized
  const findGroup = useCallback((
    group: ConditionGroup,
    groupId: string
  ): ConditionGroup | null => {
    if (group.id === groupId) return group
    for (const child of group.children) {
      const found = findGroup(child, groupId)
      if (found) return found
    }
    return null
  }, [])

  // Find parent group - memoized
  const findParentGroup = useCallback((group: ConditionGroup, childId: string): ConditionGroup | null => {
    for (const child of group.children) {
      if (child.id === childId) {
        return group
      }
      const found = findParentGroup(child, childId)
      if (found) return found
    }
    return null
  }, [])

  // Add a new condition
  const addCondition = useCallback((groupId?: string) => {
    const currentConditions = countConditions(filterTree.rootGroup)
    if (currentConditions >= maxConditions) {
      return // Can't add more conditions
    }

    const newCondition = createEmptyCondition()
    const targetGroupId = groupId || filterTree.rootGroup.id

    if (targetGroupId === filterTree.rootGroup.id) {
      // Add to root group - shallow clone is sufficient
      handleChange({
        ...filterTree,
        rootGroup: {
          ...filterTree.rootGroup,
          conditions: [...filterTree.rootGroup.conditions, newCondition]
        }
      })
    } else {
      // Add to nested group - need deep clone
      const newTree = deepCloneFilterTree(filterTree)
      const group = findGroup(newTree.rootGroup, targetGroupId)
      if (group && group.conditions.length < maxConditions) {
        group.conditions.push(newCondition)
        handleChange(newTree)
      }
    }
  }, [filterTree, maxConditions, handleChange, findGroup, countConditions, getMaxDepth])

  // Remove a condition
  const removeCondition = useCallback((conditionId: string, groupId?: string) => {
    const targetGroupId = groupId || filterTree.rootGroup.id

    if (targetGroupId === filterTree.rootGroup.id) {
      const newConditions = filterTree.rootGroup.conditions.filter(c => c.id !== conditionId)
      // If no conditions left, add an empty one
      if (newConditions.length === 0) {
        handleChange({
          ...filterTree,
          rootGroup: {
            ...filterTree.rootGroup,
            conditions: [createEmptyCondition()]
          }
        })
      } else {
        handleChange({
          ...filterTree,
          rootGroup: {
            ...filterTree.rootGroup,
            conditions: newConditions
          }
        })
      }
    } else {
      const newTree = deepCloneFilterTree(filterTree)
      const group = findGroup(newTree.rootGroup, targetGroupId)
      if (group) {
        const newConditions = group.conditions.filter(c => c.id !== conditionId)
        if (newConditions.length === 0 && group.children.length === 0) {
          // Remove empty group
          removeGroupFromParent(newTree.rootGroup, targetGroupId)
        } else if (newConditions.length === 0) {
          group.conditions.push(createEmptyCondition())
        } else {
          group.conditions = newConditions
        }
        handleChange(newTree)
      }
    }
  }, [filterTree, handleChange, findGroup])

  function removeGroupFromParent(parent: ConditionGroup, groupId: string): boolean {
    const idx = parent.children.findIndex(c => c.id === groupId)
    if (idx >= 0) {
      parent.children.splice(idx, 1)
      return true
    }
    for (const child of parent.children) {
      if (removeGroupFromParent(child, groupId)) return true
    }
    return false
  }

  // Update a condition
  const updateCondition = useCallback((
    conditionId: string,
    updates: Partial<FilterCondition>,
    groupId?: string
  ) => {
    const targetGroupId = groupId || filterTree.rootGroup.id

    if (targetGroupId === filterTree.rootGroup.id) {
      handleChange({
        ...filterTree,
        rootGroup: {
          ...filterTree.rootGroup,
          conditions: filterTree.rootGroup.conditions.map(c =>
            c.id === conditionId ? { ...c, ...updates } : c
          )
        }
      })
    } else {
      const newTree = deepCloneFilterTree(filterTree)
      const group = findGroup(newTree.rootGroup, targetGroupId)
      if (group) {
        group.conditions = group.conditions.map(c =>
          c.id === conditionId ? { ...c, ...updates } : c
        )
        handleChange(newTree)
      }
    }
  }, [filterTree, handleChange, findGroup])

  // Add a new group
  const addGroup = useCallback((parentGroupId?: string) => {
    const currentDepth = getMaxDepth(filterTree.rootGroup)
    if (currentDepth >= maxDepth) {
      return // Can't nest deeper
    }

    const newGroup = createEmptyGroup(false)
    const targetGroupId = parentGroupId || filterTree.rootGroup.id

    if (targetGroupId === filterTree.rootGroup.id) {
      handleChange({
        ...filterTree,
        rootGroup: {
          ...filterTree.rootGroup,
          children: [...filterTree.rootGroup.children, newGroup]
        }
      })
    } else {
      const newTree = deepCloneFilterTree(filterTree)
      const parentGroup = findGroup(newTree.rootGroup, targetGroupId)
      if (parentGroup) {
        const depth = getDepth(newTree.rootGroup, targetGroupId)
        if (depth < maxDepth - 1) {
          parentGroup.children.push(newGroup)
          handleChange(newTree)
        }
      }
    }
  }, [filterTree, maxDepth, handleChange, findGroup, getMaxDepth, getDepth])

  // Remove a group
  const removeGroup = useCallback((groupId: string) => {
    if (groupId === filterTree.rootGroup.id) {
      return // Can't remove root
    }

    const newTree = deepCloneFilterTree(filterTree)
    removeGroupFromParent(newTree.rootGroup, groupId)
    handleChange(newTree)
  }, [filterTree, handleChange])

  // Toggle connector (AND/OR)
  const toggleConnector = useCallback((groupId: string) => {
    if (groupId === filterTree.rootGroup.id) {
      handleChange({
        ...filterTree,
        rootGroup: {
          ...filterTree.rootGroup,
          connector: filterTree.rootGroup.connector === 'and' ? 'or' : 'and'
        }
      })
    } else {
      const newTree = deepCloneFilterTree(filterTree)
      const group = findGroup(newTree.rootGroup, groupId)
      if (group) {
        group.connector = group.connector === 'and' ? 'or' : 'and'
        handleChange(newTree)
      }
    }
  }, [filterTree, handleChange, findGroup])

  // Group conditions together
  const groupConditions = useCallback((conditionIds: string[], groupId?: string) => {
    const targetGroupId = groupId || filterTree.rootGroup.id
    const currentDepth = getMaxDepth(filterTree.rootGroup)
    if (currentDepth >= maxDepth) {
      return
    }

    if (conditionIds.length < 2) return

    const newTree = deepCloneFilterTree(filterTree)
    const parentGroup = findGroup(newTree.rootGroup, targetGroupId)
    if (!parentGroup) return

    const conditionsToGroup = parentGroup.conditions.filter(c => conditionIds.includes(c.id))
    if (conditionsToGroup.length < 2) return

    // Remove conditions from parent
    parentGroup.conditions = parentGroup.conditions.filter(c => !conditionIds.includes(c.id))

    // Create new group
    const newGroup: ConditionGroup = {
      id: `group-${Math.random().toString(36).substr(2, 9)}`,
      connector: 'and',
      conditions: conditionsToGroup,
      children: [],
      isRoot: false
    }

    parentGroup.children.push(newGroup)
    handleChange(newTree)
  }, [filterTree, maxDepth, handleChange, findGroup, getMaxDepth])

  // Ungroup a group
  const ungroupGroup = useCallback((groupId: string) => {
    if (groupId === filterTree.rootGroup.id) {
      return // Can't ungroup root
    }

    const newTree = deepCloneFilterTree(filterTree)

    // Find parent of this group
    const parentGroup = findParentGroup(newTree.rootGroup, groupId)
    if (!parentGroup) return

    const groupToUngroup = parentGroup.children.find(c => c.id === groupId)
    if (!groupToUngroup) return

    // Move conditions to parent
    parentGroup.conditions = [...parentGroup.conditions, ...groupToUngroup.conditions]

    // Move children to parent
    parentGroup.children = [
      ...parentGroup.children.filter(c => c.id !== groupId),
      ...groupToUngroup.children
    ]

    handleChange(newTree)
  }, [filterTree, handleChange, findParentGroup])

  // Reset to initial state
  const reset = useCallback(() => {
    setFilterTreeState(initialTree || createEmptyFilterTree())
    setIsDirty(false)
    clearCaches()
  }, [initialTree, clearCaches])

  // Set filter tree directly
  const setFilterTree = useCallback((tree: FilterTree) => {
    handleChange(tree)
  }, [handleChange])

  return {
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
    ungroupGroup,
    reset,
    setFilterTree
  }
}
