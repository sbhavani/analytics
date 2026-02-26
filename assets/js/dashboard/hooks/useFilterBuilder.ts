import { useState, useCallback, useEffect, useRef } from 'react'
import React from 'react'
import type {
  FilterData,
  FilterGroup,
  FilterCondition,
  Segment,
  FilterLogic
} from '../../types/filter-builder'
import {
  listSegments,
  createSegment,
  updateSegment,
  deleteSegment,
  queryVisitorCount
} from '../api/segments'
import {
  validateFilterData,
  countConditions,
  getNestingDepth
} from '../util/filter-query-parser'

const MAX_CONDITIONS = 20
const MAX_NESTING_DEPTH = 3
const DEBOUNCE_MS = 500

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

function createEmptyGroup(): FilterGroup {
  return {
    id: generateId(),
    logic: 'AND',
    conditions: []
  }
}

function createEmptyFilterData(): FilterData {
  return {
    filters: [createEmptyGroup()],
    labels: {}
  }
}

function createEmptyCondition(): FilterCondition {
  return {
    id: generateId(),
    attribute: '',
    operator: 'equals',
    value: ''
  }
}

export interface UseFilterBuilderOptions {
  siteId: string | number
  initialFilterData?: FilterData
  period?: string
  date?: string
  onSegmentCreated?: (segment: Segment) => void
  onSegmentUpdated?: (segment: Segment) => void
  onSegmentDeleted?: (segmentId: number) => void
}

export interface UseFilterBuilderReturn {
  // State
  filterData: FilterData
  savedSegments: Segment[]
  selectedSegmentId: number | null
  isLoading: boolean
  isSaving: boolean
  error: string | null
  visitorCount: number
  visitorCountLoading: boolean
  visitorCountError: string | null
  validationErrors: string[]

  // Filter operations
  addCondition: (groupId: string) => void
  updateCondition: (groupId: string, conditionId: string, updates: Partial<FilterCondition>) => void
  removeCondition: (groupId: string, conditionId: string) => void
  addNestedGroup: (parentGroupId: string) => void
  removeNestedGroup: (parentGroupId: string, nestedGroupId: string) => void
  toggleLogic: (groupId: string) => void
  setLogic: (groupId: string, logic: FilterLogic) => void
  clearFilters: () => void

  // Segment operations
  loadSegments: () => Promise<void>
  saveSegment: (name: string, type?: 'personal' | 'site') => Promise<void>
  updateCurrentSegment: (name: string) => Promise<void>
  deleteCurrentSegment: () => Promise<void>
  selectSegment: (segmentId: number | null) => void
  loadSegmentToBuilder: (segment: Segment) => void
}

export function useFilterBuilder(options: UseFilterBuilderOptions): UseFilterBuilderReturn {
  const {
    siteId,
    initialFilterData,
    period = '30d',
    date,
    onSegmentCreated,
    onSegmentUpdated,
    onSegmentDeleted
  } = options

  const [filterData, setFilterData] = useState<FilterData>(
    initialFilterData || createEmptyFilterData()
  )
  const [savedSegments, setSavedSegments] = useState<Segment[]>([])
  const [selectedSegmentId, setSelectedSegmentId] = useState<number | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [visitorCount, setVisitorCount] = useState(0)
  const [visitorCountLoading, setVisitorCountLoading] = useState(false)
  const [visitorCountError, setVisitorCountError] = useState<string | null>(null)
  const [validationErrors, setValidationErrors] = useState<string[]>([])

  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null)

  // Validate filter data when it changes
  useEffect(() => {
    const validation = validateFilterData(filterData)
    setValidationErrors(validation.errors)
  }, [filterData])

  // Debounced query for visitor count
  useEffect(() => {
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current)
    }

    debounceTimerRef.current = setTimeout(async () => {
      // Only query if filter is valid
      const validation = validateFilterData(filterData)
      if (!validation.valid || countConditions(filterData) === 0) {
        setVisitorCount(0)
        setVisitorCountLoading(false)
        return
      }

      setVisitorCountLoading(true)
      setVisitorCountError(null)

      try {
        const count = await queryVisitorCount(siteId, filterData, period, date)
        setVisitorCount(count)
      } catch (err) {
        setVisitorCountError(err instanceof Error ? err.message : 'Failed to fetch visitor count')
        setVisitorCount(0)
      } finally {
        setVisitorCountLoading(false)
      }
    }, DEBOUNCE_MS)

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current)
      }
    }
  }, [filterData, siteId, period, date])

  // Find group by ID recursively
  const findGroup = useCallback(
    (groups: (FilterGroup | FilterCondition)[], id: string): FilterGroup | null => {
      for (const item of groups) {
        if ('logic' in item && item.id === id) {
          return item
        }
        if ('logic' in item) {
          const found = findGroup(item.conditions, id)
          if (found) return found
        }
      }
      return null
    },
    []
  )

  // Update group recursively
  const updateGroupInData = useCallback(
    (data: FilterData, groupId: string, updater: (group: FilterGroup) => FilterGroup): FilterData => {
      return {
        ...data,
        filters: data.filters.map(group => {
          if (group.id === groupId) {
            return updater(group)
          }
          // Recursively update nested groups
          return {
            ...group,
            conditions: group.conditions.map(item => {
              if ('logic' in item) {
                return updateGroupInData({ filters: [item] }, groupId, updater).filters[0]
              }
              return item
            })
          }
        })
      }
    },
    []
  )

  // Add condition to a group
  const addCondition = useCallback(
    (groupId: string) => {
      const currentCount = countConditions(filterData)
      if (currentCount >= MAX_CONDITIONS) {
        setError(`Maximum of ${MAX_CONDITIONS} conditions allowed`)
        return
      }

      setFilterData(prev => {
        return updateGroupInData(prev, groupId, group => ({
          ...group,
          conditions: [...group.conditions, createEmptyCondition()]
        }))
      })
    },
    [filterData, updateGroupInData]
  )

  // Update a condition
  const updateCondition = useCallback(
    (groupId: string, conditionId: string, updates: Partial<FilterCondition>) => {
      setFilterData(prev => {
        return updateGroupInData(prev, groupId, group => ({
          ...group,
          conditions: group.conditions.map(item => {
            if ('id' in item && item.id === conditionId) {
              return { ...item, ...updates }
            }
            return item
          })
        }))
      })
    },
    [updateGroupInData]
  )

  // Remove a condition
  const removeCondition = useCallback(
    (groupId: string, conditionId: string) => {
      setFilterData(prev => {
        return updateGroupInData(prev, groupId, group => ({
          ...group,
          conditions: group.conditions.filter(item => {
            if ('id' in item && item.id === conditionId) return false
            return true
          })
        }))
      })
    },
    [updateGroupInData]
  )

  // Add nested group
  const addNestedGroup = useCallback(
    (parentGroupId: string) => {
      const currentDepth = getNestingDepth(filterData)
      if (currentDepth >= MAX_NESTING_DEPTH) {
        setError(`Maximum nesting depth of ${MAX_NESTING_DEPTH} levels allowed`)
        return
      }

      setFilterData(prev => {
        return updateGroupInData(prev, parentGroupId, group => ({
          ...group,
          conditions: [...group.conditions, createEmptyGroup()]
        }))
      })
    },
    [filterData, updateGroupInData]
  )

  // Remove nested group
  const removeNestedGroup = useCallback(
    (parentGroupId: string, nestedGroupId: string) => {
      setFilterData(prev => {
        return updateGroupInData(prev, parentGroupId, group => ({
          ...group,
          conditions: group.conditions.filter(item => {
            if ('logic' in item && item.id === nestedGroupId) return false
            return true
          })
        }))
      })
    },
    [updateGroupInData]
  )

  // Toggle logic (AND/OR)
  const toggleLogic = useCallback(
    (groupId: string) => {
      setFilterData(prev => {
        return updateGroupInData(prev, groupId, group => ({
          ...group,
          logic: group.logic === 'AND' ? 'OR' : 'AND'
        }))
      })
    },
    [updateGroupInData]
  )

  // Set specific logic
  const setLogic = useCallback(
    (groupId: string, logic: FilterLogic) => {
      setFilterData(prev => {
        return updateGroupInData(prev, groupId, group => ({
          ...group,
          logic
        }))
      })
    },
    [updateGroupInData]
  )

  // Clear all filters
  const clearFilters = useCallback(() => {
    setFilterData(createEmptyFilterData())
    setSelectedSegmentId(null)
    setError(null)
  }, [])

  // Load segments from API
  const loadSegments = useCallback(async () => {
    setIsLoading(true)
    setError(null)

    try {
      const segments = await listSegments(siteId)
      setSavedSegments(segments)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load segments')
    } finally {
      setIsLoading(false)
    }
  }, [siteId])

  // Save current filter as new segment
  const saveSegment = useCallback(
    async (name: string, type: 'personal' | 'site' = 'personal') => {
      const validation = validateFilterData(filterData)
      if (!validation.valid) {
        setError(validation.errors.join(', '))
        return
      }

      setIsSaving(true)
      setError(null)

      try {
        const segment = await createSegment(siteId, name, filterData, type)
        setSavedSegments(prev => [...prev, segment])
        setSelectedSegmentId(segment.id)
        onSegmentCreated?.(segment)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to save segment')
      } finally {
        setIsSaving(false)
      }
    },
    [filterData, siteId, onSegmentCreated]
  )

  // Update current segment
  const updateCurrentSegment = useCallback(
    async (name: string) => {
      if (!selectedSegmentId) return

      const validation = validateFilterData(filterData)
      if (!validation.valid) {
        setError(validation.errors.join(', '))
        return
      }

      setIsSaving(true)
      setError(null)

      try {
        const segment = await updateSegment(siteId, selectedSegmentId, name, filterData)
        setSavedSegments(prev =>
          prev.map(s => (s.id === segment.id ? segment : s))
        )
        onSegmentUpdated?.(segment)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to update segment')
      } finally {
        setIsSaving(false)
      }
    },
    [filterData, selectedSegmentId, siteId, onSegmentUpdated]
  )

  // Delete current segment
  const deleteCurrentSegment = useCallback(async () => {
    if (!selectedSegmentId) return

    setIsSaving(true)
    setError(null)

    try {
      await deleteSegment(siteId, selectedSegmentId)
      setSavedSegments(prev => prev.filter(s => s.id !== selectedSegmentId))
      setSelectedSegmentId(null)
      setFilterData(createEmptyFilterData())
      onSegmentDeleted?.(selectedSegmentId)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete segment')
    } finally {
      setIsSaving(false)
    }
  }, [selectedSegmentId, siteId, onSegmentDeleted])

  // Select a segment
  const selectSegment = useCallback((segmentId: number | null) => {
    setSelectedSegmentId(segmentId)
  }, [])

  // Load segment data into builder
  const loadSegmentToBuilder = useCallback(
    (segment: Segment) => {
      setFilterData(segment.segment_data)
      setSelectedSegmentId(segment.id)
    },
    []
  )

  return {
    // State
    filterData,
    savedSegments,
    selectedSegmentId,
    isLoading,
    isSaving,
    error,
    visitorCount,
    visitorCountLoading,
    visitorCountError,
    validationErrors,

    // Filter operations
    addCondition,
    updateCondition,
    removeCondition,
    addNestedGroup,
    removeNestedGroup,
    toggleLogic,
    setLogic,
    clearFilters,

    // Segment operations
    loadSegments,
    saveSegment,
    updateCurrentSegment,
    deleteCurrentSegment,
    selectSegment,
    loadSegmentToBuilder
  }
}
