import { useState, useCallback } from 'react'
import { FilterTree, FilterCondition, FilterGroup, Connector } from './types'
import { validateFilterTree } from './filterValidator'

function generateId(): string {
  return Math.random().toString(36).substring(2, 10)
}

function createEmptyTree(): FilterTree {
  return {
    rootGroup: {
      id: generateId(),
      connector: 'AND',
      conditions: [],
      subgroups: [],
    },
  }
}

export function useFilterState(initialTree?: FilterTree) {
  const [tree, setTree] = useState<FilterTree>(initialTree || createEmptyTree())
  const [isDirty, setIsDirty] = useState(false)

  const addCondition = useCallback((groupId?: string) => {
    const newCondition: FilterCondition = {
      id: generateId(),
      field: '',
      operator: '',
      value: '',
    }

    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      if (!groupId || groupId === newTree.rootGroup.id) {
        newTree.rootGroup.conditions.push(newCondition)
      } else {
        const addToGroup = (group: FilterGroup): boolean => {
          if (group.id === groupId) {
            group.conditions.push(newCondition)
            return true
          }
          for (const subgroup of group.subgroups) {
            if (addToGroup(subgroup)) return true
          }
          return false
        }
        addToGroup(newTree.rootGroup)
      }

      return newTree
    })
    setIsDirty(true)
  }, [])

  const updateCondition = useCallback((conditionId: string, updates: Partial<FilterCondition>) => {
    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      const updateInGroup = (group: FilterGroup): boolean => {
        const conditionIndex = group.conditions.findIndex((c) => c.id === conditionId)
        if (conditionIndex >= 0) {
          group.conditions[conditionIndex] = { ...group.conditions[conditionIndex], ...updates }
          return true
        }
        for (const subgroup of group.subgroups) {
          if (updateInGroup(subgroup)) return true
        }
        return false
      }

      updateInGroup(newTree.rootGroup)
      return newTree
    })
    setIsDirty(true)
  }, [])

  const removeCondition = useCallback((conditionId: string) => {
    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      const removeFromGroup = (group: FilterGroup): boolean => {
        const initialLength = group.conditions.length
        group.conditions = group.conditions.filter((c) => c.id !== conditionId)
        if (group.conditions.length !== initialLength) return true

        for (const subgroup of group.subgroups) {
          if (removeFromGroup(subgroup)) return true
        }
        return false
      }

      removeFromGroup(newTree.rootGroup)
      return newTree
    })
    setIsDirty(true)
  }, [])

  const changeConnector = useCallback((groupId: string, connector: Connector) => {
    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      const updateGroup = (group: FilterGroup): boolean => {
        if (group.id === groupId) {
          group.connector = connector
          return true
        }
        for (const subgroup of group.subgroups) {
          if (updateGroup(subgroup)) return true
        }
        return false
      }

      updateGroup(newTree.rootGroup)
      return newTree
    })
    setIsDirty(true)
  }, [])

  const createGroup = useCallback((conditionIds: string[], connector: Connector) => {
    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      const extractConditions = (group: FilterGroup): FilterCondition[] => {
        const extracted: FilterCondition[] = []
        group.conditions = group.conditions.filter((c) => {
          if (conditionIds.includes(c.id)) {
            extracted.push(c)
            return false
          }
          return true
        })
        return extracted
      }

      const extracted = extractConditions(newTree.rootGroup)

      if (extracted.length > 0) {
        const newGroup: FilterGroup = {
          id: generateId(),
          connector,
          conditions: extracted,
          subgroups: [],
        }
        newTree.rootGroup.subgroups.push(newGroup)
      }

      return newTree
    })
    setIsDirty(true)
  }, [])

  const ungroup = useCallback((groupId: string) => {
    setTree((prev) => {
      const newTree = JSON.parse(JSON.stringify(prev))

      const moveToParent = (group: FilterGroup): boolean => {
        const subgroupIndex = group.subgroups.findIndex((s) => s.id === groupId)
        if (subgroupIndex >= 0) {
          const subgroup = group.subgroups[subgroupIndex]
          group.conditions.push(...subgroup.conditions)
          group.subgroups.push(...subgroup.subgroups)
          group.subgroups.splice(subgroupIndex, 1)
          return true
        }
        for (const subgroup of group.subgroups) {
          if (moveToParent(subgroup)) return true
        }
        return false
      }

      moveToParent(newTree.rootGroup)
      return newTree
    })
    setIsDirty(true)
  }, [])

  const loadTree = useCallback((newTree: FilterTree) => {
    setTree(newTree)
    setIsDirty(false)
  }, [])

  const resetTree = useCallback(() => {
    setTree(createEmptyTree())
    setIsDirty(false)
  }, [])

  const validation = validateFilterTree(tree)

  return {
    tree,
    isDirty,
    isValid: validation.isValid,
    errors: validation.errors,
    addCondition,
    updateCondition,
    removeCondition,
    changeConnector,
    createGroup,
    ungroup,
    loadTree,
    resetTree,
  }
}
