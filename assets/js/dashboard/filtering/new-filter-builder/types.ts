/**
 * TypeScript types for the Advanced Filter Builder
 */

// Supported filter operators
export type FilterOperator =
  | 'equals'        // "is"
  | 'does_not_equal' // "is_not"
  | 'contains'      // "contains"
  | 'does_not_contain' // "does_not_contain"
  | 'is_set'       // "is_set"
  | 'is_not_set'   // "is_not_set"

// Map operator to human-readable label
export const OPERATOR_LABELS: Record<FilterOperator, string> = {
  equals: 'is',
  does_not_equal: 'is not',
  contains: 'contains',
  does_not_contain: 'does not contain',
  is_set: 'is set',
  is_not_set: 'is not set'
}

// Supported visitor attributes for filtering
export type FilterAttribute =
  | 'country'
  | 'region'
  | 'city'
  | 'browser'
  | 'os'
  | 'device'
  | 'screen_size'
  | 'source'
  | 'goal'
  | 'visit_duration'
  | 'pages'

export interface AttributeDefinition {
  key: FilterAttribute
  label: string
  type: 'string' | 'number' | 'boolean'
  operators: FilterOperator[]
  placeholder?: string
}

// Available filter attributes with their configurations
export const FILTER_ATTRIBUTES: AttributeDefinition[] = [
  { key: 'country', label: 'Country', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. United States' },
  { key: 'region', label: 'Region', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. California' },
  { key: 'city', label: 'City', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. San Francisco' },
  { key: 'browser', label: 'Browser', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. Chrome' },
  { key: 'os', label: 'Operating System', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. macOS' },
  { key: 'device', label: 'Device Type', type: 'string', operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set'], placeholder: 'e.g. mobile' },
  { key: 'screen_size', label: 'Screen Size', type: 'string', operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set'], placeholder: 'e.g. large' },
  { key: 'source', label: 'Traffic Source', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set'], placeholder: 'e.g. Google' },
  { key: 'goal', label: 'Goal', type: 'string', operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set'], placeholder: 'e.g. Signup' },
  { key: 'visit_duration', label: 'Visit Duration (seconds)', type: 'number', operators: ['equals', 'does_not_equal', 'contains'], placeholder: 'e.g. 60' },
  { key: 'pages', label: 'Pages Visited', type: 'number', operators: ['equals', 'does_not_equal', 'contains'], placeholder: 'e.g. 5' }
]

// A single filter condition
export interface FilterCondition {
  id: string
  attribute: FilterAttribute | ''
  operator: FilterOperator
  value: string
  isNegated: boolean
}

// A group of conditions connected by AND/OR
export interface FilterGroup {
  id: string
  connector: 'AND' | 'OR'
  conditions: FilterCondition[]
  nestedGroups: FilterGroup[]
}

// The root filter tree structure
export interface FilterTree {
  rootGroup: FilterGroup
}

// Legacy filter format for API compatibility
export type LegacyFilter = [string, string, (string | number)[]]

// Saved segment from API
export interface SavedSegment {
  id: number
  name: string
  type: 'personal' | 'site'
  segment_data: {
    filters: LegacyFilter[]
    labels: Record<string, string>
  }
  inserted_at: string
  updated_at: string
  owner_id: number | null
  owner_name: string | null
}

// Segment preview result
export interface SegmentPreview {
  visitor_count: number | null
  isLoading: boolean
  hasError: boolean
  errorMessage?: string
}

// Filter builder state
export interface FilterBuilderState {
  filterTree: FilterTree
  isDirty: boolean
  isValid: boolean
  preview: SegmentPreview
  savedSegments: SavedSegment[]
  isLoadingSegments: boolean
}

// Filter builder actions
export type FilterBuilderAction =
  | { type: 'ADD_CONDITION'; groupId: string; condition: FilterCondition }
  | { type: 'UPDATE_CONDITION'; conditionId: string; updates: Partial<FilterCondition> }
  | { type: 'DELETE_CONDITION'; conditionId: string }
  | { type: 'ADD_NESTED_GROUP'; parentGroupId: string; group: FilterGroup }
  | { type: 'DELETE_NESTED_GROUP'; groupId: string }
  | { type: 'UPDATE_CONNECTOR'; groupId: string; connector: 'AND' | 'OR' }
  | { type: 'LOAD_SEGMENT'; segment: SavedSegment }
  | { type: 'CLEAR_ALL' }
  | { type: 'SET_PREVIEW'; preview: SegmentPreview }
  | { type: 'SET_SEGMENTS'; segments: SavedSegment[] }
  | { type: 'SET_LOADING_SEGMENTS'; isLoading: boolean }
  | { type: 'SET_DIRTY'; isDirty: boolean }
