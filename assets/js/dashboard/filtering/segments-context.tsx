import React, {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useState
} from 'react'
import {
  handleSegmentResponse,
  SavedSegment,
  SavedSegmentPublic,
  SavedSegments,
  SegmentData
} from './segments'
import {
  FilterExpression,
  FilterCondition,
  ConditionGroup,
  createEmptyExpression,
  createCondition,
  createConditionGroup,
  LogicalOperator,
  generateId
} from '../components/filter-builder/types'

export function parsePreloadedSegments(dataset: DOMStringMap): SavedSegments {
  return JSON.parse(dataset.segments!).map(handleSegmentResponse)
}

export function parseLimitedToSegmentId(dataset: DOMStringMap): number | null {
  return JSON.parse(dataset.limitedToSegmentId!)
}

export function getLimitedToSegment(
  limitedToSegmentId: number | null,
  preloadedSegments: SavedSegments
): Pick<SavedSegment, 'id' | 'name'> | null {
  if (limitedToSegmentId !== null) {
    return preloadedSegments.find((s) => s.id === limitedToSegmentId) ?? null
  }
  return null
}

type ChangeSegmentState = (
  segment: (SavedSegment | SavedSegmentPublic) & { segment_data: SegmentData }
) => void

type ChangeFilterBuilderState = {
  expression: FilterExpression | null
  editingSegmentId: number | null
  isDirty: boolean
}

type UpdateFilterBuilder = (updates: Partial<ChangeFilterBuilderState>) => void
type AddCondition = (groupId: string, condition: FilterCondition) => void
type UpdateCondition = (groupId: string, conditionId: string, updates: Partial<FilterCondition>) => void
type RemoveCondition = (groupId: string, conditionId: string) => void
type AddGroup = (parentGroupId: string, group: ConditionGroup) => void
type UpdateGroupOperator = (groupId: string, operator: LogicalOperator) => void
type RemoveGroup = (groupId: string) => void

const initialValue: {
  segments: SavedSegments
  limitedToSegment: Pick<SavedSegment, 'id' | 'name'> | null
  updateOne: ChangeSegmentState
  addOne: ChangeSegmentState
  removeOne: ChangeSegmentState
  // Filter builder state
  filterBuilder: ChangeFilterBuilderState
  updateFilterBuilder: UpdateFilterBuilder
  addCondition: AddCondition
  updateCondition: UpdateCondition
  removeCondition: RemoveCondition
  addGroup: AddGroup
  updateGroupOperator: UpdateGroupOperator
  removeGroup: RemoveGroup
} = {
  segments: [],
  limitedToSegment: null,
  updateOne: () => {},
  addOne: () => {},
  removeOne: () => {},
  // Filter builder state
  filterBuilder: {
    expression: null,
    editingSegmentId: null,
    isDirty: false
  },
  updateFilterBuilder: () => {},
  addCondition: () => {},
  updateCondition: () => {},
  removeCondition: () => {},
  addGroup: () => {},
  updateGroupOperator: () => {},
  removeGroup: () => {}
}

const SegmentsContext = createContext(initialValue)

export const useSegmentsContext = () => {
  return useContext(SegmentsContext)
}

export const SegmentsContextProvider = ({
  preloadedSegments,
  limitedToSegment,
  children
}: {
  preloadedSegments: SavedSegments
  limitedToSegment: Pick<SavedSegment, 'id' | 'name'> | null
  children: ReactNode
}) => {
  const [segments, setSegments] = useState(preloadedSegments)
  const [filterBuilder, setFilterBuilder] = useState<ChangeFilterBuilderState>({
    expression: null,
    editingSegmentId: null,
    isDirty: false
  })

  const removeOne: ChangeSegmentState = useCallback(
    ({ id }) =>
      setSegments((currentSegments) =>
        currentSegments.filter((s) => s.id !== id)
      ),
    []
  )

  const updateOne: ChangeSegmentState = useCallback(
    (segment) =>
      setSegments((currentSegments) => [
        segment,
        ...currentSegments.filter((s) => s.id !== segment.id)
      ]),
    []
  )

  const addOne: ChangeSegmentState = useCallback(
    (segment) =>
      setSegments((currentSegments) => [segment, ...currentSegments]),
    []
  )

  // Filter builder functions
  const updateFilterBuilder: UpdateFilterBuilder = useCallback((updates) => {
    setFilterBuilder((prev) => ({
      ...prev,
      ...updates,
      isDirty: true
    }))
  }, [])

  const addCondition: AddCondition = useCallback((groupId, condition) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      const newExpression = addConditionToGroup(prev.expression.rootGroup, groupId, condition)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  const updateCondition: UpdateCondition = useCallback((groupId, conditionId, updates) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      const newExpression = updateConditionInGroup(prev.expression.rootGroup, groupId, conditionId, updates)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  const removeCondition: RemoveCondition = useCallback((groupId, conditionId) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      const newExpression = removeConditionFromGroup(prev.expression.rootGroup, groupId, conditionId)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  const addGroup: AddGroup = useCallback((parentGroupId, group) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      const newExpression = addNestedGroupToGroup(prev.expression.rootGroup, parentGroupId, group)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  const updateGroupOperator: UpdateGroupOperator = useCallback((groupId, operator) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      const newExpression = updateOperatorInGroup(prev.expression.rootGroup, groupId, operator)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  const removeGroup: RemoveGroup = useCallback((groupId) => {
    setFilterBuilder((prev) => {
      if (!prev.expression) return prev

      // Can't remove root group
      if (groupId === prev.expression.rootGroup.id) return prev

      const newExpression = removeNestedGroup(prev.expression.rootGroup, groupId)
      return {
        ...prev,
        expression: { ...prev.expression, rootGroup: newExpression },
        isDirty: true
      }
    })
  }, [])

  return (
    <SegmentsContext.Provider
      value={{
        segments,
        limitedToSegment,
        removeOne,
        updateOne,
        addOne,
        filterBuilder,
        updateFilterBuilder,
        addCondition,
        updateCondition,
        removeCondition,
        addGroup,
        updateGroupOperator,
        removeGroup
      }}
    >
      {children}
    </SegmentsContext.Provider>
  )
}

// Helper functions for filter builder state management
function addConditionToGroup(rootGroup: ConditionGroup, groupId: string, condition: FilterCondition): ConditionGroup {
  if (rootGroup.id === groupId) {
    return { ...rootGroup, conditions: [...rootGroup.conditions, condition] }
  }

  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return addConditionToGroup(c as ConditionGroup, groupId, condition)
    })
  }
}

function updateConditionInGroup(rootGroup: ConditionGroup, groupId: string, conditionId: string, updates: Partial<FilterCondition>): ConditionGroup {
  if (rootGroup.id === groupId) {
    return {
      ...rootGroup,
      conditions: rootGroup.conditions.map((c) => {
        if ('field' in c && (c as FilterCondition).id === conditionId) {
          return { ...c, ...updates }
        }
        return c
      })
    }
  }

  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return updateConditionInGroup(c as ConditionGroup, groupId, conditionId, updates)
    })
  }
}

function removeConditionFromGroup(rootGroup: ConditionGroup, groupId: string, conditionId: string): ConditionGroup {
  if (rootGroup.id === groupId) {
    return {
      ...rootGroup,
      conditions: rootGroup.conditions.filter((c) => {
        if ('field' in c) return (c as FilterCondition).id !== conditionId
        return (c as ConditionGroup).id !== conditionId
      })
    }
  }

  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return removeConditionFromGroup(c as ConditionGroup, groupId, conditionId)
    })
  }
}

function addNestedGroupToGroup(rootGroup: ConditionGroup, parentGroupId: string, nestedGroup: ConditionGroup): ConditionGroup {
  if (rootGroup.id === parentGroupId) {
    return { ...rootGroup, conditions: [...rootGroup.conditions, nestedGroup] }
  }

  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return addNestedGroupToGroup(c as ConditionGroup, parentGroupId, nestedGroup)
    })
  }
}

function updateOperatorInGroup(rootGroup: ConditionGroup, groupId: string, operator: LogicalOperator): ConditionGroup {
  if (rootGroup.id === groupId) {
    return { ...rootGroup, operator }
  }

  return {
    ...rootGroup,
    conditions: rootGroup.conditions.map((c) => {
      if ('field' in c) return c
      return updateOperatorInGroup(c as ConditionGroup, groupId, operator)
    })
  }
}

function removeNestedGroup(rootGroup: ConditionGroup, groupId: string): ConditionGroup {
  return {
    ...rootGroup,
    conditions: rootGroup.conditions.filter((c) => {
      if ('field' in c) return true
      return (c as ConditionGroup).id !== groupId
    }).map((c) => {
      if ('field' in c) return c
      return removeNestedGroup(c as ConditionGroup, groupId)
    })
  }
}
