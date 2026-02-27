import React, { createContext, useContext, useReducer, useCallback, ReactNode } from 'react'
import type { FilterTree, FilterCondition, GroupOperator } from './types'
import {
  createFilterTree,
  addCondition,
  addGroup,
  removeItem,
  deleteGroup,
  updateCondition,
  changeGroupOperator,
  moveItem,
  validateFilterTree,
  clearAllFilters,
  serializeFilterTree,
  deserializeFilterTree
} from './filterTreeUtils'
import type { Filter } from '../dashboard-state'

// State
interface FilterBuilderState {
  filterTree: FilterTree
  isValid: boolean
  validationErrors: string[]
  isDirty: boolean
  past: FilterTree[]
  future: FilterTree[]
}

// Actions
type FilterBuilderAction =
  | { type: 'ADD_CONDITION'; payload: Partial<FilterCondition>; targetGroupId?: string }
  | { type: 'ADD_GROUP'; payload: GroupOperator; parentGroupId?: string }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'DELETE_GROUP'; payload: string }
  | { type: 'UPDATE_CONDITION'; payload: { id: string; updates: Partial<FilterCondition> } }
  | { type: 'CHANGE_GROUP_OPERATOR'; payload: { groupId: string; operator: GroupOperator } }
  | { type: 'MOVE_ITEM'; payload: { itemId: string; newIndex: number; targetGroupId?: string } }
  | { type: 'CLEAR_ALL' }
  | { type: 'LOAD_FILTERS'; payload: Filter[] }
  | { type: 'SET_FILTER_TREE'; payload: FilterTree }
  | { type: 'UNDO' }
  | { type: 'REDO' }

const initialState: FilterBuilderState = {
  filterTree: createFilterTree(),
  isValid: false,
  validationErrors: [],
  isDirty: false,
  past: [],
  future: []
}

function validate(state: FilterBuilderState): FilterBuilderState {
  const validation = validateFilterTree(state.filterTree)
  return {
    ...state,
    isValid: validation.valid,
    validationErrors: validation.errors
  }
}

function filterBuilderReducer(state: FilterBuilderState, action: FilterBuilderAction): FilterBuilderState {
  switch (action.type) {
    case 'ADD_CONDITION': {
      const newTree = addCondition(state.filterTree, action.payload, action.targetGroupId)
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'ADD_GROUP': {
      try {
        const newTree = addGroup(state.filterTree, action.payload, action.parentGroupId)
        return validate({ ...state, filterTree: newTree, isDirty: true })
      } catch (e) {
        return state
      }
    }

    case 'REMOVE_ITEM': {
      const newTree = removeItem(state.filterTree, action.payload)
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'DELETE_GROUP': {
      const newTree = deleteGroup(state.filterTree, action.payload)
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'UPDATE_CONDITION': {
      const newTree = updateCondition(
        state.filterTree,
        action.payload.id,
        action.payload.updates
      )
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'CHANGE_GROUP_OPERATOR': {
      const newTree = changeGroupOperator(
        state.filterTree,
        action.payload.groupId,
        action.payload.operator
      )
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'MOVE_ITEM': {
      const newTree = moveItem(
        state.filterTree,
        action.payload.itemId,
        action.payload.newIndex,
        action.payload.targetGroupId
      )
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'CLEAR_ALL': {
      const newTree = clearAllFilters()
      return validate({ ...state, filterTree: newTree, isDirty: true })
    }

    case 'LOAD_FILTERS': {
      const newTree = deserializeFilterTree(action.payload)
      return validate({ ...state, filterTree: newTree, isDirty: false })
    }

    case 'SET_FILTER_TREE': {
      return validate({ ...state, filterTree: action.payload, isDirty: true })
    }

    case 'UNDO': {
      if (state.past.length === 0) return state
      const previous = state.past[state.past.length - 1]
      const newPast = state.past.slice(0, -1)
      return validate({
        ...state,
        filterTree: previous,
        past: newPast,
        future: [state.filterTree, ...state.future],
        isDirty: true
      })
    }

    case 'REDO': {
      if (state.future.length === 0) return state
      const next = state.future[0]
      const newFuture = state.future.slice(1)
      return validate({
        ...state,
        filterTree: next,
        past: [...state.past, state.filterTree],
        future: newFuture,
        isDirty: true
      })
    }

    default:
      return state
  }
}

// Context
interface FilterBuilderContextValue {
  state: FilterBuilderState
  addCondition: (condition: Partial<FilterCondition>, targetGroupId?: string) => void
  addGroup: (operator?: GroupOperator, parentGroupId?: string) => void
  removeItem: (itemId: string) => void
  deleteGroup: (groupId: string) => void
  updateCondition: (id: string, updates: Partial<FilterCondition>) => void
  changeGroupOperator: (groupId: string, operator: GroupOperator) => void
  moveItem: (itemId: string, newIndex: number, targetGroupId?: string) => void
  clearAll: () => void
  loadFilters: (filters: Filter[]) => void
  setFilterTree: (tree: FilterTree) => void
  getSerializedFilters: () => Filter[]
  getFilterTree: () => FilterTree
  undo: () => void
  redo: () => void
  canUndo: boolean
  canRedo: boolean
}

const FilterBuilderContext = createContext<FilterBuilderContextValue | null>(null)

interface FilterBuilderProviderProps {
  children: ReactNode
  initialFilters?: Filter[]
}

export function FilterBuilderProvider({ children, initialFilters = [] }: FilterBuilderProviderProps) {
  const [state, dispatch] = useReducer(filterBuilderReducer, {
    ...initialState,
    ...(initialFilters.length > 0
      ? { filterTree: deserializeFilterTree(initialFilters) }
      : {})
  })

  // Validate after initial load
  React.useEffect(() => {
    if (initialFilters.length > 0) {
      dispatch({ type: 'LOAD_FILTERS', payload: initialFilters })
    }
  }, [])

  const addCondition = useCallback((condition: Partial<FilterCondition>, targetGroupId?: string) => {
    dispatch({ type: 'ADD_CONDITION', payload: condition, targetGroupId })
  }, [])

  const addGroup = useCallback((operator: GroupOperator = 'or', parentGroupId?: string) => {
    dispatch({ type: 'ADD_GROUP', payload: operator, parentGroupId })
  }, [])

  const removeItem = useCallback((itemId: string) => {
    dispatch({ type: 'REMOVE_ITEM', payload: itemId })
  }, [])

  const deleteGroup = useCallback((groupId: string) => {
    dispatch({ type: 'DELETE_GROUP', payload: groupId })
  }, [])

  const updateCondition = useCallback((id: string, updates: Partial<FilterCondition>) => {
    dispatch({ type: 'UPDATE_CONDITION', payload: { id, updates } })
  }, [])

  const changeGroupOperator = useCallback((groupId: string, operator: GroupOperator) => {
    dispatch({ type: 'CHANGE_GROUP_OPERATOR', payload: { groupId, operator } })
  }, [])

  const moveItem = useCallback((itemId: string, newIndex: number, targetGroupId?: string) => {
    dispatch({ type: 'MOVE_ITEM', payload: { itemId, newIndex, targetGroupId } })
  }, [])

  const clearAll = useCallback(() => {
    dispatch({ type: 'CLEAR_ALL' })
  }, [])

  const loadFilters = useCallback((filters: Filter[]) => {
    dispatch({ type: 'LOAD_FILTERS', payload: filters })
  }, [])

  const setFilterTree = useCallback((tree: FilterTree) => {
    dispatch({ type: 'SET_FILTER_TREE', payload: tree })
  }, [])

  const getSerializedFilters = useCallback(() => {
    return serializeFilterTree(state.filterTree)
  }, [state.filterTree])

  const getFilterTree = useCallback(() => {
    return state.filterTree
  }, [state.filterTree])

  const undo = useCallback(() => {
    dispatch({ type: 'UNDO' })
  }, [])

  const redo = useCallback(() => {
    dispatch({ type: 'REDO' })
  }, [])

  const canUndo = state.past.length > 0
  const canRedo = state.future.length > 0

  const value: FilterBuilderContextValue = {
    state,
    addCondition,
    addGroup,
    removeItem,
    deleteGroup,
    updateCondition,
    changeGroupOperator,
    moveItem,
    clearAll,
    loadFilters,
    setFilterTree,
    getSerializedFilters,
    getFilterTree,
    undo,
    redo,
    canUndo,
    canRedo
  }

  return (
    <FilterBuilderContext.Provider value={value}>
      {children}
    </FilterBuilderContext.Provider>
  )
}

export function useFilterBuilder(): FilterBuilderContextValue {
  const context = useContext(FilterBuilderContext)
  if (!context) {
    throw new Error('useFilterBuilder must be used within a FilterBuilderProvider')
  }
  return context
}

export { type FilterBuilderContextValue, type FilterBuilderState, type FilterBuilderAction }
