/**
 * Filter Tree Types for Advanced Filter Builder
 * Supports nested AND/OR groups for custom visitor segments
 */

export type FilterOperator =
  | 'is'
  | 'is_not'
  | 'contains'
  | 'contains_not'
  | 'matches'
  | 'matches_not'
  | 'matches_wildcard'
  | 'matches_wildcard_not'
  | 'has_done'
  | 'has_not_done'

export type GroupOperator = 'and' | 'or'

export interface FilterConditionNode {
  id: string
  type: 'condition'
  attribute: string
  operator: FilterOperator
  value: string
  negated: boolean
}

export interface FilterGroupNode {
  id: string
  type: 'group'
  operator: GroupOperator
  children: FilterNode[]
}

export type FilterNode = FilterGroupNode | FilterConditionNode

export interface FilterTree {
  version: 1
  root: FilterGroupNode
}

// UI State Types
export interface FilterBuilderState {
  tree: FilterTree
  isDirty: boolean
  lastSaved: Date | null
  previewStatus: 'idle' | 'loading' | 'success' | 'error'
  validationErrors: ValidationError[]
}

export interface ValidationError {
  nodeId: string
  field: 'attribute' | 'operator' | 'value'
  message: string
}

// Available visitor attributes
export interface FilterAttribute {
  key: string
  label: string
  type: 'visit' | 'event' | 'custom'
  operators: FilterOperator[]
}

// Segment types
export interface SavedSegment {
  id: number
  name: string
  type: 'personal' | 'site'
  filter_tree?: FilterTree
  segment_data?: {
    filters: unknown[]
    labels: Record<string, string>
  }
  inserted_at: string
  updated_at: string
}

// Preview result types
export interface PreviewResult {
  results: Array<{
    date: string
    visitors: number
    pageviews?: number
  }>
  totals: {
    visitors: number
    pageviews?: number
  }
  sample_percent: number
  warnings: string[]
}

// API Request/Response types
export interface CreateSegmentRequest {
  name: string
  filter_tree?: FilterTree
  type?: 'personal' | 'site'
}

export interface UpdateSegmentRequest {
  name?: string
  filter_tree?: FilterTree
}

export interface PreviewRequest {
  filter_tree: FilterTree
  metrics?: string[]
  date_range?: {
    period: string
    compare_to?: string
  }
}
