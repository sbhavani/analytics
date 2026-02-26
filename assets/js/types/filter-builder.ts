// TypeScript types for Advanced Filter Builder

export type FilterOperator =
  | 'equals'
  | 'does_not_equal'
  | 'contains'
  | 'does_not_contain'
  | 'matches_regexp'
  | 'does_not_match_regexp'
  | 'is_set'
  | 'is_not_set'

export interface FilterCondition {
  id: string
  attribute: string
  operator: FilterOperator
  value: string | string[]
}

export type FilterLogic = 'AND' | 'OR'

export interface FilterGroup {
  id: string
  logic: FilterLogic
  conditions: (FilterCondition | FilterGroup)[]
}

export interface FilterData {
  filters: FilterGroup[]
  labels?: Record<string, string>
}

export interface Segment {
  id: number
  name: string
  type: 'personal' | 'site'
  segment_data: FilterData
  owner_id: number
  owner_name: string | null
  site_id: number
  inserted_at: string
  updated_at: string
}

export interface VisitorCountResult {
  visitors: number
  loading: boolean
  error: string | null
}

export interface FilterBuilderState {
  filterData: FilterData
  savedSegments: Segment[]
  selectedSegmentId: number | null
  isLoading: boolean
  isSaving: boolean
  error: string | null
  visitorCount: number
  visitorCountLoading: boolean
  visitorCountError: string | null
}

export type FilterBuilderAction =
  | { type: 'SET_FILTER_DATA'; payload: FilterData }
  | { type: 'SET_SAVED_SEGMENTS'; payload: Segment[] }
  | { type: 'SELECT_SEGMENT'; payload: number | null }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_SAVING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_VISITOR_COUNT'; payload: number }
  | { type: 'SET_VISITOR_COUNT_LOADING'; payload: boolean }
  | { type: 'SET_VISITOR_COUNT_ERROR'; payload: string | null }
  | { type: 'ADD_CONDITION'; payload: { groupId: string; condition: FilterCondition } }
  | { type: 'UPDATE_CONDITION'; payload: { groupId: string; conditionId: string; updates: Partial<FilterCondition> } }
  | { type: 'REMOVE_CONDITION'; payload: { groupId: string; conditionId: string } }
  | { type: 'ADD_NESTED_GROUP'; payload: { parentGroupId: string; group: FilterGroup } }
  | { type: 'TOGGLE_LOGIC'; payload: { groupId: string } }
  | { type: 'SET_LOGIC'; payload: { groupId: string; logic: FilterLogic } }
