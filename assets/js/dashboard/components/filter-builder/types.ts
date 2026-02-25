/**
 * TypeScript interfaces for the Advanced Filter Builder
 * These types define the data structures for filter conditions and groups
 */

/** Available comparison operators */
export type FilterOperator =
  | 'equals'
  | 'not_equals'
  | 'contains'
  | 'does_not_contain'
  | 'greater_than'
  | 'less_than'
  | 'greater_than_or_equals'
  | 'less_than_or_equals'
  | 'is_one_of'

/** Property data types */
export type PropertyType = 'string' | 'numeric' | 'list'

/** Visitor property definition */
export interface VisitorProperty {
  key: string
  name: string
  type: PropertyType
  operators: FilterOperator[]
}

/** Single filter condition */
export interface FilterCondition {
  id: string
  property: string
  operator: FilterOperator
  value: string | string[]
}

/** Filter group with AND/OR logic */
export interface FilterGroup {
  id: string
  logic: 'AND' | 'OR'
  conditions: FilterCondition[]
  groups: FilterGroup[]
}

/** Root filter structure */
export interface FilterRoot {
  id: string
  logic: 'AND' | 'OR'
  conditions: FilterCondition[]
  groups: FilterGroup[]
}

/** Segment data structure for storage */
export interface SegmentData {
  filters: unknown[]
  labels: Record<string, string>
}

/** Filter preview result */
export interface FilterPreview {
  visitors: number
  sample_percent: number | null
}

/** Validation error */
export interface ValidationError {
  field: string
  message: string
}

/** Filter builder state */
export interface FilterBuilderState {
  rootGroup: FilterRoot
  isValid: boolean
  errors: ValidationError[]
  isLoading: boolean
  preview: FilterPreview | null
  savedSegments: SavedSegmentInfo[]
}

/** Saved segment info for list */
export interface SavedSegmentInfo {
  id: number
  name: string
  type: 'personal' | 'site'
  segment_data: SegmentData
}

/** Undo history entry */
export interface HistoryEntry {
  rootGroup: FilterRoot
  timestamp: number
}

/** Props for FilterBuilder component */
export interface FilterBuilderProps {
  siteId: number
  onApply?: (filters: FilterRoot) => void
  initialFilters?: FilterRoot
  onClose?: () => void
}
