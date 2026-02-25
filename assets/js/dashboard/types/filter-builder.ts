// Filter builder type definitions for the Advanced Filter Builder feature

export type FilterOperator =
  | 'is'
  | 'is_not'
  | 'contains'
  | 'contains_not'
  | 'greater_than'
  | 'less_than'
  | 'is_set'
  | 'is_not_set'

export type LogicalOperator = 'AND' | 'OR'

export interface FilterCondition {
  id: string
  field: string
  operator: FilterOperator
  value: string | number | boolean
}

export interface FilterGroup {
  id: string
  type: 'group'
  operator: LogicalOperator
  children: FilterGroupItem[]
}

export type FilterGroupItem = FilterCondition | FilterGroup
