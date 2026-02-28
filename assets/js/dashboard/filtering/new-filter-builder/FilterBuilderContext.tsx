import React, { createContext, useContext, useReducer, useCallback, useMemo } from 'react'
import {
  FilterBuilderState,
  FilterBuilderAction,
  FilterCondition,
  FilterGroup,
  SavedSegment,
  SegmentPreview,
  FilterTree
} from './types'
import {
  createFilterTree,
  createCondition,
  createGroup,
  addCondition as addConditionToTree,
  updateCondition as updateConditionInTree,
  deleteCondition as deleteConditionFromTree,
  addNestedGroup as addNestedGroupToTree,
  deleteNestedGroup as deleteNestedGroupFromTree,
  updateConnector as updateConnectorInTree,
  isFilterValid,
  filterTreeToLegacyFilters,
  generateFilterSummary
} from './filterTreeUtils'

const initialState: FilterBuilderState = {
  filterTree: createFilterTree(),
  isDirty: false,
  isValid: false,
  preview: {
    visitor_count: null,
    isLoading: false,
    hasError: false
  },
  savedSegments: [],
  isLoadingSegments: false
}

function filterBuilderReducer(
  state: FilterBuilderState,
  action: FilterBuilderAction
): FilterBuilderState {
  switch (action.type) {
    case 'ADD_CONDITION': {
      const newTree = addConditionToTree(
        state.filterTree,
        action.groupId,
        action.condition
      )
      return {
        ...state,
        filterTree: newTree,
        isDirty: true,
        isValid: isFilterValid(newTree)
      }
    }

    case 'UPDATE_CONDITION': {
      const newTree = updateConditionInTree(
        state.filterTree,
        action.conditionId,
        action.updates
      )
      return {
        ...state,
        filterTree: newTree,
        isDirty: true,
        isValid: isFilterValid(newTree)
      }
    }

    case 'DELETE_CONDITION': {
      const newTree = deleteConditionFromTree(
        state.filterTree,
        action.conditionId
      )
      return {
        ...state,
        filterTree: newTree,
        isDirty: true,
        isValid: isFilterValid(newTree)
      }
    }

    case 'ADD_NESTED_GROUP': {
      const result = addNestedGroupToTree(
        state.filterTree,
        action.parentGroupId,
        action.group
      )
      return {
        ...state,
        filterTree: result.tree,
        isDirty: true,
        isValid: isFilterValid(result.tree)
      }
    }

    case 'DELETE_NESTED_GROUP': {
      const newTree = deleteNestedGroupFromTree(
        state.filterTree,
        action.groupId
      )
      return {
        ...state,
        filterTree: newTree,
        isDirty: true,
        isValid: isFilterValid(newTree)
      }
    }

    case 'UPDATE_CONNECTOR': {
      const newTree = updateConnectorInTree(
        state.filterTree,
        action.groupId,
        action.connector
      )
      return {
        ...state,
        filterTree: newTree,
        isDirty: true,
        isValid: isFilterValid(newTree)
      }
    }

    case 'LOAD_SEGMENT': {
      // Convert segment data to filter tree
      // For now, create a simple tree from the filters
      const segmentFilters = action.segment.segment_data.filters
      // This would need proper conversion in production
      return {
        ...state,
        filterTree: createFilterTree(), // Simplified for now
        isDirty: false,
        isValid: true
      }
    }

    case 'CLEAR_ALL': {
      return {
        ...state,
        filterTree: createFilterTree(),
        isDirty: false,
        isValid: false
      }
    }

    case 'SET_PREVIEW': {
      return {
        ...state,
        preview: action.preview
      }
    }

    case 'SET_SEGMENTS': {
      return {
        ...state,
        savedSegments: action.segments,
        isLoadingSegments: false
      }
    }

    case 'SET_LOADING_SEGMENTS': {
      return {
        ...state,
        isLoadingSegments: action.isLoading
      }
    }

    case 'SET_DIRTY': {
      return {
        ...state,
        isDirty: action.isDirty
      }
    }

    default:
      return state
  }
}

interface FilterBuilderContextValue {
  state: FilterBuilderState
  // Actions
  addCondition: (groupId: string, condition?: Partial<FilterCondition>) => void
  updateCondition: (conditionId: string, updates: Partial<FilterCondition>) => void
  deleteCondition: (conditionId: string) => void
  addNestedGroup: (parentGroupId: string) => void
  deleteNestedGroup: (groupId: string) => void
  updateConnector: (groupId: string, connector: 'AND' | 'OR') => void
  loadSegment: (segment: SavedSegment) => void
  clearAll: () => void
  setPreview: (preview: SegmentPreview) => void
  setSegments: (segments: SavedSegment[]) => void
  setLoadingSegments: (isLoading: boolean) => void
  // Computed
  isValid: boolean
  filterSummary: string
  legacyFilters: [string, string, string[]][]
}

const FilterBuilderContext = createContext<FilterBuilderContextValue | null>(null)

interface FilterBuilderProviderProps {
  children: React.ReactNode
  siteId?: string
  dateRange?: { period: string; from?: string; to?: string }
  onApply?: (filters: [string, string, string[]][]) => void
}

export function FilterBuilderProvider({
  children,
  siteId,
  dateRange,
  onApply
}: FilterBuilderProviderProps) {
  const [state, dispatch] = useReducer(filterBuilderReducer, initialState)

  const addCondition = useCallback((groupId: string, condition?: Partial<FilterCondition>) => {
    dispatch({
      type: 'ADD_CONDITION',
      groupId,
      condition: createCondition(condition)
    })
  }, [])

  const updateCondition = useCallback((conditionId: string, updates: Partial<FilterCondition>) => {
    dispatch({
      type: 'UPDATE_CONDITION',
      conditionId,
      updates
    })
  }, [])

  const deleteCondition = useCallback((conditionId: string) => {
    dispatch({
      type: 'DELETE_CONDITION',
      conditionId
    })
  }, [])

  const addNestedGroup = useCallback((parentGroupId: string) => {
    dispatch({
      type: 'ADD_NESTED_GROUP',
      parentGroupId,
      group: createGroup()
    })
  }, [])

  const deleteNestedGroup = useCallback((groupId: string) => {
    dispatch({
      type: 'DELETE_NESTED_GROUP',
      groupId
    })
  }, [])

  const updateConnector = useCallback((groupId: string, connector: 'AND' | 'OR') => {
    dispatch({
      type: 'UPDATE_CONNECTOR',
      groupId,
      connector
    })
  }, [])

  const loadSegment = useCallback((segment: SavedSegment) => {
    dispatch({
      type: 'LOAD_SEGMENT',
      segment
    })
  }, [])

  const clearAll = useCallback(() => {
    dispatch({ type: 'CLEAR_ALL' })
  }, [])

  const setPreview = useCallback((preview: SegmentPreview) => {
    dispatch({
      type: 'SET_PREVIEW',
      preview
    })
  }, [])

  const setSegments = useCallback((segments: SavedSegment[]) => {
    dispatch({
      type: 'SET_SEGMENTS',
      segments
    })
  }, [])

  const setLoadingSegments = useCallback((isLoading: boolean) => {
    dispatch({
      type: 'SET_LOADING_SEGMENTS',
      isLoading
    })
  }, [])

  const isValid = useMemo(() => isFilterValid(state.filterTree), [state.filterTree])
  const filterSummary = useMemo(() => generateFilterSummary(state.filterTree), [state.filterTree])
  const legacyFilters = useMemo(() => filterTreeToLegacyFilters(state.filterTree), [state.filterTree])

  const value: FilterBuilderContextValue = {
    state,
    addCondition,
    updateCondition,
    deleteCondition,
    addNestedGroup,
    deleteNestedGroup,
    updateConnector,
    loadSegment,
    clearAll,
    setPreview,
    setSegments,
    setLoadingSegments,
    isValid,
    filterSummary,
    legacyFilters
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

export { FilterBuilderContext }
