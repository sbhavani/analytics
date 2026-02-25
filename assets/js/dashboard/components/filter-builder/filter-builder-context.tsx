import React, {
  createContext,
  useCallback,
  useContext,
  useReducer,
  useMemo,
  ReactNode
} from 'react'
import {
  FilterBuilderState,
  FilterBuilderContextValue,
  FilterCondition,
  FilterGroup,
  LogicalOperator,
  createInitialState,
  createEmptyCondition,
  createEmptyGroup,
  findParentGroup,
  validateFilterStructure,
  isFilterGroup,
  getGroupDepth
} from './types'

const MAX_NESTING_DEPTH = 3

type Action =
  | { type: 'ADD_CONDITION'; parentId: string | null }
  | { type: 'REMOVE_CONDITION'; conditionId: string }
  | { type: 'UPDATE_CONDITION'; conditionId: string; updates: Partial<FilterCondition> }
  | { type: 'ADD_GROUP'; parentId: string | null }
  | { type: 'REMOVE_GROUP'; groupId: string }
  | { type: 'UPDATE_GROUP_OPERATOR'; groupId: string; operator: LogicalOperator }
  | { type: 'CLEAR_ALL' }
  | { type: 'LOAD_SEGMENT'; filterGroup: FilterGroup }
  | { type: 'SET_LOADING'; loading: boolean }
  | { type: 'SET_ERROR'; error: string | null }

function reducer(state: FilterBuilderState, action: Action): FilterBuilderState {
  switch (action.type) {
    case 'ADD_CONDITION': {
      const newCondition = createEmptyCondition()
      const parentId = action.parentId

      if (!parentId) {
        // Add to root group
        return {
          ...state,
          rootGroup: {
            ...state.rootGroup,
            children: [...state.rootGroup.children, newCondition]
          },
          isDirty: true
        }
      }

      // Find parent group and add condition
      const result = findParentGroup(state.rootGroup, parentId)
      if (result) {
        const { parent, childIndex } = result
        const newParent = {
          ...parent,
          children: [
            ...parent.children.slice(0, childIndex),
            newCondition,
            ...parent.children.slice(childIndex)
          ]
        }

        return {
          ...state,
          rootGroup: replaceGroup(state.rootGroup, parentId, newParent),
          isDirty: true
        }
      }

      return state
    }

    case 'REMOVE_CONDITION': {
      const result = findParentGroup(state.rootGroup, action.conditionId)
      if (result) {
        const { parent, childIndex } = result
        return {
          ...state,
          rootGroup: {
            ...state.rootGroup,
            children: [
              ...parent.children.slice(0, childIndex),
              ...parent.children.slice(childIndex + 1)
            ]
          },
          isDirty: true
        }
      }
      return state
    }

    case 'UPDATE_CONDITION': {
      const { conditionId, updates } = action
      const newRoot = updateConditionInGroup(state.rootGroup, conditionId, updates)
      return {
        ...state,
        rootGroup: newRoot,
        isDirty: true
      }
    }

    case 'ADD_GROUP': {
      const parentId = action.parentId

      // Check nesting depth
      if (parentId) {
        const parentResult = findParentGroup(state.rootGroup, parentId)
        if (parentResult) {
          const depth = getGroupDepth(state.rootGroup)
          if (depth >= MAX_NESTING_DEPTH) {
            // Can't add more nested groups
            return state
          }
        }
      }

      const newGroup = createEmptyGroup('AND')

      if (!parentId) {
        return {
          ...state,
          rootGroup: {
            ...state.rootGroup,
            children: [...state.rootGroup.children, newGroup]
          },
          isDirty: true
        }
      }

      const result = findParentGroup(state.rootGroup, parentId)
      if (result) {
        const { parent, childIndex } = result
        const newParent = {
          ...parent,
          children: [
            ...parent.children.slice(0, childIndex),
            newGroup,
            ...parent.children.slice(childIndex)
          ]
        }

        return {
          ...state,
          rootGroup: replaceGroup(state.rootGroup, parentId, newParent),
          isDirty: true
        }
      }

      return state
    }

    case 'REMOVE_GROUP': {
      const result = findParentGroup(state.rootGroup, action.groupId)
      if (result) {
        const { parent, childIndex } = result
        return {
          ...state,
          rootGroup: {
            ...state.rootGroup,
            children: [
              ...parent.children.slice(0, childIndex),
              ...parent.children.slice(childIndex + 1)
            ]
          },
          isDirty: true
        }
      }
      return state
    }

    case 'UPDATE_GROUP_OPERATOR': {
      const newRoot = updateGroupOperator(state.rootGroup, action.groupId, action.operator)
      return {
        ...state,
        rootGroup: newRoot,
        isDirty: true
      }
    }

    case 'CLEAR_ALL':
      return createInitialState()

    case 'LOAD_SEGMENT':
      return {
        rootGroup: action.filterGroup,
        isValid: true,
        isDirty: false
      }

    default:
      return state
  }
}

function replaceGroup(rootGroup: FilterGroup, groupId: string, newGroup: FilterGroup): FilterGroup {
  if (rootGroup.id === groupId) {
    return newGroup
  }

  return {
    ...rootGroup,
    children: rootGroup.children.map((child) => {
      if (isFilterGroup(child) && child.id === groupId) {
        return newGroup
      }
      if (isFilterGroup(child)) {
        return replaceGroup(child, groupId, newGroup)
      }
      return child
    })
  }
}

function updateConditionInGroup(
  group: FilterGroup,
  conditionId: string,
  updates: Partial<FilterCondition>
): FilterGroup {
  return {
    ...group,
    children: group.children.map((child) => {
      if (!isFilterGroup(child) && child.id === conditionId) {
        return { ...child, ...updates }
      }
      if (isFilterGroup(child)) {
        return updateConditionInGroup(child, conditionId, updates)
      }
      return child
    })
  }
}

function updateGroupOperator(
  group: FilterGroup,
  groupId: string,
  operator: LogicalOperator
): FilterGroup {
  return {
    ...group,
    children: group.children.map((child) => {
      if (isFilterGroup(child) && child.id === groupId) {
        return { ...child, operator }
      }
      if (isFilterGroup(child)) {
        return updateGroupOperator(child, groupId, operator)
      }
      return child
    })
  }
}

const FilterBuilderContext = createContext<FilterBuilderContextValue | null>(null)

export const useFilterBuilderContext = () => {
  const context = useContext(FilterBuilderContext)
  if (!context) {
    throw new Error('useFilterBuilderContext must be used within a FilterBuilderProvider')
  }
  return context
}

interface FilterBuilderProviderProps {
  children: ReactNode
  onApplyFilter?: (filterGroup: FilterGroup) => void
  initialGroup?: FilterGroup
}

export function FilterBuilderProvider({
  children,
  onApplyFilter,
  initialGroup
}: FilterBuilderProviderProps) {
  const initialState = useMemo(() => {
    if (initialGroup) {
      return {
        rootGroup: initialGroup,
        isValid: true,
        isDirty: false
      }
    }
    return createInitialState()
  }, [initialGroup])

  const [state, dispatch] = useReducer(reducer, initialState)
  const [isLoading, setIsLoading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)

  const addCondition = useCallback((parentId: string | null) => {
    dispatch({ type: 'ADD_CONDITION', parentId })
  }, [])

  const removeCondition = useCallback((conditionId: string) => {
    dispatch({ type: 'REMOVE_CONDITION', conditionId })
  }, [])

  const updateCondition = useCallback((conditionId: string, updates: Partial<FilterCondition>) => {
    dispatch({ type: 'UPDATE_CONDITION', conditionId, updates })
  }, [])

  const addGroup = useCallback((parentId: string | null) => {
    dispatch({ type: 'ADD_GROUP', parentId })
  }, [])

  const removeGroup = useCallback((groupId: string) => {
    dispatch({ type: 'REMOVE_GROUP', groupId })
  }, [])

  const updateGroupOperator = useCallback((groupId: string, operator: LogicalOperator) => {
    dispatch({ type: 'UPDATE_GROUP_OPERATOR', groupId, operator })
  }, [])

  const clearAll = useCallback(() => {
    dispatch({ type: 'CLEAR_ALL' })
  }, [])

  const applyFilter = useCallback(() => {
    const validation = validateFilterStructure(state.rootGroup)
    if (validation.isValid && onApplyFilter) {
      setIsLoading(true)
      try {
        onApplyFilter(state.rootGroup)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to apply filter')
      } finally {
        setIsLoading(false)
      }
    } else {
      setError(validation.errors.join(', '))
    }
  }, [state.rootGroup, onApplyFilter])

  const loadSegment = useCallback((filterGroup: FilterGroup) => {
    dispatch({ type: 'LOAD_SEGMENT', filterGroup })
  }, [])

  const setLoading = useCallback((loading: boolean) => {
    setIsLoading(loading)
  }, [])

  const setErrorHandler = useCallback((error: string | null) => {
    setError(error)
  }, [])

  const value = useMemo<FilterBuilderContextValue>(
    () => ({
      state,
      addCondition,
      removeCondition,
      updateCondition,
      addGroup,
      removeGroup,
      updateGroupOperator,
      clearAll,
      applyFilter,
      loadSegment,
      setLoading,
      setError: setErrorHandler,
      isLoading,
      error
    }),
    [
      state,
      addCondition,
      removeCondition,
      updateCondition,
      addGroup,
      removeGroup,
      updateGroupOperator,
      clearAll,
      applyFilter,
      loadSegment,
      setLoading,
      setErrorHandler,
      isLoading,
      error
    ]
  )

  return (
    <FilterBuilderContext.Provider value={value}>
      {children}
    </FilterBuilderContext.Provider>
  )
}
