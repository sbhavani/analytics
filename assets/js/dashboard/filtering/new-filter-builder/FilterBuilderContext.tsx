import React, {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useEffect,
  useReducer,
  useRef
} from 'react'

// Filter types
export interface FilterCondition {
  id: string
  dimension: string
  operator: string
  value: string
}

export interface FilterGroup {
  id: string
  operator: 'AND' | 'OR'
  children: (FilterCondition | FilterGroup)[]
}

export interface FilterTemplate {
  id: number
  name: string
  segment_data: FilterGroup
}

export type FilterNode = FilterCondition | FilterGroup

// Undo/Redo history state
interface HistoryState {
  past: FilterNode[]
  present: FilterNode[]
  future: FilterNode[]
}

// Action types
type FilterAction =
  | { type: 'ADD_CONDITION'; payload: FilterCondition }
  | { type: 'REMOVE_CONDITION'; payload: string }
  | { type: 'UPDATE_CONDITION'; payload: FilterCondition }
  | { type: 'ADD_GROUP'; payload: FilterGroup }
  | { type: 'REMOVE_GROUP'; payload: string }
  | { type: 'UPDATE_GROUP_OPERATOR'; payload: { id: string; operator: 'AND' | 'OR' } }
  | { type: 'SET_FILTER'; payload: FilterNode[] }
  | { type: 'UNDO' }
  | { type: 'REDO' }
  | { type: 'CLEAR' }

const initialHistoryState: HistoryState = {
  past: [],
  present: [],
  future: []
}

function filterReducer(state: HistoryState, action: FilterAction): HistoryState {
  switch (action.type) {
    case 'ADD_CONDITION': {
      const newPresent = [...state.present, action.payload]
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'REMOVE_CONDITION': {
      const newPresent = state.present.filter(
        (node) => 'id' in node && node.id !== action.payload
      )
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'UPDATE_CONDITION': {
      const newPresent = state.present.map((node) => {
        if ('id' in node && node.id === action.payload.id) {
          return action.payload
        }
        return node
      })
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'ADD_GROUP': {
      const newPresent = [...state.present, action.payload]
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'REMOVE_GROUP': {
      const newPresent = state.present.filter(
        (node) => 'id' in node && node.id !== action.payload
      )
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'UPDATE_GROUP_OPERATOR': {
      const newPresent = state.present.map((node) => {
        if ('id' in node && node.id === action.payload.id && 'operator' in node) {
          return { ...node, operator: action.payload.operator }
        }
        return node
      })
      return {
        past: [...state.past, state.present],
        present: newPresent,
        future: []
      }
    }
    case 'SET_FILTER': {
      return {
        past: [...state.past, state.present],
        present: action.payload,
        future: []
      }
    }
    case 'UNDO': {
      if (state.past.length === 0) return state
      const previous = state.past[state.past.length - 1]
      const newPast = state.past.slice(0, -1)
      return {
        past: newPast,
        present: previous,
        future: [state.present, ...state.future]
      }
    }
    case 'REDO': {
      if (state.future.length === 0) return state
      const next = state.future[0]
      const newFuture = state.future.slice(1)
      return {
        past: [...state.past, state.present],
        present: next,
        future: newFuture
      }
    }
    case 'CLEAR': {
      return {
        past: [...state.past, state.present],
        present: [],
        future: []
      }
    }
    default:
      return state
  }
}

interface FilterBuilderContextType {
  filters: FilterNode[]
  addCondition: (condition: FilterCondition) => void
  removeCondition: (id: string) => void
  updateCondition: (condition: FilterCondition) => void
  addGroup: (group: FilterGroup) => void
  removeGroup: (id: string) => void
  updateGroupOperator: (id: string, operator: 'AND' | 'OR') => void
  setFilter: (filters: FilterNode[]) => void
  undo: () => void
  redo: () => void
  clear: () => void
  canUndo: boolean
  canRedo: boolean
}

const FilterBuilderContext = createContext<FilterBuilderContextType | undefined>(
  undefined
)

export const useFilterBuilder = () => {
  const context = useContext(FilterBuilderContext)
  if (!context) {
    throw new Error(
      'useFilterBuilder must be used within a FilterBuilderContextProvider'
    )
  }
  return context
}

interface FilterBuilderProviderProps {
  children: ReactNode
  initialFilters?: FilterNode[]
}

export const FilterBuilderProvider: React.FC<FilterBuilderProviderProps> = ({
  children,
  initialFilters = []
}) => {
  const [state, dispatch] = useReducer(filterReducer, {
    past: [],
    present: initialFilters,
    future: []
  })

  const historyRef = useRef<{ undo: () => void; redo: () => void } | null>(null)

  const addCondition = useCallback((condition: FilterCondition) => {
    dispatch({ type: 'ADD_CONDITION', payload: condition })
  }, [])

  const removeCondition = useCallback((id: string) => {
    dispatch({ type: 'REMOVE_CONDITION', payload: id })
  }, [])

  const updateCondition = useCallback((condition: FilterCondition) => {
    dispatch({ type: 'UPDATE_CONDITION', payload: condition })
  }, [])

  const addGroup = useCallback((group: FilterGroup) => {
    dispatch({ type: 'ADD_GROUP', payload: group })
  }, [])

  const removeGroup = useCallback((id: string) => {
    dispatch({ type: 'REMOVE_GROUP', payload: id })
  }, [])

  const updateGroupOperator = useCallback(
    (id: string, operator: 'AND' | 'OR') => {
      dispatch({ type: 'UPDATE_GROUP_OPERATOR', payload: { id, operator } })
    },
    []
  )

  const setFilter = useCallback((filters: FilterNode[]) => {
    dispatch({ type: 'SET_FILTER', payload: filters })
  }, [])

  const undo = useCallback(() => {
    dispatch({ type: 'UNDO' })
  }, [])

  const redo = useCallback(() => {
    dispatch({ type: 'REDO' })
  }, [])

  const clear = useCallback(() => {
    dispatch({ type: 'CLEAR' })
  }, [])

  // Expose undo/redo functions via ref for keyboard handler
  useEffect(() => {
    historyRef.current = { undo, redo }
  }, [undo, redo])

  // Keyboard event handler for Ctrl+Z/Cmd+Z (undo) and Ctrl+Shift+Z/Cmd+Shift+Z (redo)
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0
      const isUndoKey = isMac
        ? event.metaKey && event.key === 'z' && !event.shiftKey
        : event.ctrlKey && event.key === 'z' && !event.shiftKey
      const isRedoKey = isMac
        ? event.metaKey && event.key === 'z' && event.shiftKey
        : event.ctrlKey && event.key === 'Z'

      if (isUndoKey) {
        event.preventDefault()
        historyRef.current?.undo()
      } else if (isRedoKey) {
        event.preventDefault()
        historyRef.current?.redo()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const value: FilterBuilderContextType = {
    filters: state.present,
    addCondition,
    removeCondition,
    updateCondition,
    addGroup,
    removeGroup,
    updateGroupOperator,
    setFilter,
    undo,
    redo,
    clear,
    canUndo: state.past.length > 0,
    canRedo: state.future.length > 0
  }

  return (
    <FilterBuilderContext.Provider value={value}>
      {children}
    </FilterBuilderContext.Provider>
  )
}

export default FilterBuilderContext
