// Types for the Advanced Filter Builder

export type FilterOperator = 'is' | 'is_not' | 'contains' | 'contains_not' | 'has_not_done' | 'matches' | 'does_not_match' | 'is_set' | 'is_not_set' | 'greater_than' | 'less_than'

export type GroupOperator = 'and' | 'or'

export interface FilterCondition {
  id: string
  dimension: string
  operator: FilterOperator
  values: string[]
}

export interface FilterGroup {
  id: string
  operator: GroupOperator
  children: (FilterGroup | FilterCondition)[]
}

export interface FilterTree {
  rootGroup: FilterGroup
  version: number
}

export interface FilterDimension {
  key: string
  name: string
  type: 'string' | 'number' | 'boolean'
  operators: FilterOperator[]
}

export type SerializedFilter = [FilterOperator, string, string[]]

export type SerializedFilterGroup = [GroupOperator, SerializedFilter[]] | SerializedFilter

// Depth calculation type
export type DepthCounter<T> = T extends FilterGroup ? number : 0
