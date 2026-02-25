// Types for Advanced Filter Builder - Filter Expression structures
import { Filter } from '../dashboard-state'

// Valid filter operators
export type FilterOperator = 'is' | 'is-not' | 'contains' | 'does-not-contain' | 'greater' | 'less' | 'between' | 'is-set' | 'is-not-set'

// Valid dimension types
export type FilterDimension =
  | 'country'
  | 'region'
  | 'city'
  | 'browser'
  | 'browser_version'
  | 'os'
  | 'os_version'
  | 'device'
  | 'screen'
  | 'source'
  | 'referrer'
  | 'channel'
  | 'utm_medium'
  | 'utm_source'
  | 'utm_campaign'
  | 'utm_term'
  | 'utm_content'
  | 'page'
  | 'entry_page'
  | 'exit_page'
  | 'hostname'
  | 'goal'
  | 'props'

// A single filter condition
export interface FilterCondition {
  id: string
  dimension: FilterDimension
  operator: FilterOperator
  value: string | number | string[] | null
}

// A group of conditions combined with AND/OR
export interface FilterGroup {
  id: string
  operator: 'AND' | 'OR'
  children: (FilterCondition | FilterGroup)[]
  // Optional per-condition connectors - maps index to connector to next condition
  // connector between child[i] and child[i+1]
  connectors?: Record<number, 'AND' | 'OR'>
}

// The complete filter expression
export interface FilterExpression {
  version: 1
  root: FilterGroup
  metadata?: {
    created_at?: string
    updated_at?: string
  }
}

// Convert from FilterExpression to legacy Filter array format
export function filterExpressionToLegacyFilters(expression: FilterExpression): Filter[] {
  const filters: Filter[] = []

  function traverseGroup(group: FilterGroup) {
    for (const child of group.children) {
      if ('dimension' in child) {
        // It's a FilterCondition
        const legacyFilter = conditionToLegacyFilter(child)
        filters.push(legacyFilter)
      } else {
        // It's a nested FilterGroup - flatten for now (backend handles nesting)
        traverseGroup(child)
      }
    }
  }

  traverseGroup(expression.root)
  return filters
}

// Convert a FilterCondition to legacy Filter array format
function conditionToLegacyFilter(condition: FilterCondition): Filter {
  const operatorMap: Record<FilterOperator, string> = {
    'is': 'is',
    'is-not': 'is_not',
    'contains': 'contains',
    'does-not-contain': 'contains_not',
    'greater': 'greater',
    'less': 'less',
    'between': 'between',
    'is-set': 'is_set',
    'is-not-set': 'is_not_set'
  }

  const legacyOperator = operatorMap[condition.operator]
  const legacyDimension = condition.dimension
  const legacyValue = condition.value ?? []

  return [legacyOperator as any, legacyDimension, Array.isArray(legacyValue) ? legacyValue : [legacyValue]]
}

// Convert legacy Filter array format to FilterExpression
export function legacyFiltersToFilterExpression(filters: Filter[], labels: Record<string, string> = {}): FilterExpression {
  if (filters.length === 0) {
    return createEmptyFilterExpression()
  }

  // For simple cases (single or multiple flat filters), create an AND group
  const conditions: FilterCondition[] = filters.map((filter, index) => {
    const [operator, dimension, clauses] = filter
    return {
      id: generateId(),
      dimension: dimension as FilterDimension,
      operator: legacyOperatorToFilterOperator(operator as string),
      value: clauses.length === 1 ? clauses[0] : clauses
    }
  })

  return {
    version: 1,
    root: {
      id: generateId(),
      operator: 'AND',
      children: conditions
    }
  }
}

function legacyOperatorToFilterOperator(operator: string): FilterOperator {
  const operatorMap: Record<string, FilterOperator> = {
    'is': 'is',
    'is_not': 'is-not',
    'contains': 'contains',
    'contains_not': 'does-not-contain',
    'greater': 'greater',
    'less': 'less',
    'between': 'between',
    'is_set': 'is-set',
    'is_not_set': 'is-not-set'
  }
  return operatorMap[operator] || 'is'
}

export function createEmptyFilterExpression(): FilterExpression {
  return {
    version: 1,
    root: {
      id: generateId(),
      operator: 'AND',
      children: []
    }
  }
}

export function createFilterCondition(dimension: FilterDimension = 'country', operator: FilterOperator = 'is'): FilterCondition {
  return {
    id: generateId(),
    dimension,
    operator,
    value: ''
  }
}

export function createFilterGroup(operator: 'AND' | 'OR' = 'AND'): FilterGroup {
  return {
    id: generateId(),
    operator,
    children: [],
    connectors: {}
  }
}

function generateId(): string {
  return Math.random().toString(36).substring(2, 11)
}

// Get operators that are supported for a given dimension
export function getSupportedOperators(dimension: FilterDimension): FilterOperator[] {
  const locationDimensions = ['country', 'region', 'city', 'screen']
  const numericDimensions = ['browser_version', 'os_version', 'time_on_site']

  if (locationDimensions.includes(dimension)) {
    return ['is', 'is-not', 'is-set', 'is-not-set']
  }

  if (numericDimensions.includes(dimension)) {
    return ['is', 'is-not', 'greater', 'less', 'between', 'is-set', 'is-not-set']
  }

  // Default operators for most dimensions
  return ['is', 'is-not', 'contains', 'does-not-contain', 'is-set', 'is-not-set']
}

// Get display name for operator
export function getOperatorDisplayName(operator: FilterOperator): string {
  const displayNames: Record<FilterOperator, string> = {
    'is': 'is',
    'is-not': 'is not',
    'contains': 'contains',
    'does-not-contain': 'does not contain',
    'greater': 'greater than',
    'less': 'less than',
    'between': 'between',
    'is-set': 'is set',
    'is-not-set': 'is not set'
  }
  return displayNames[operator]
}

// Get display name for dimension
export function getDimensionDisplayName(dimension: FilterDimension): string {
  const displayNames: Record<FilterDimension, string> = {
    'country': 'Country',
    'region': 'Region',
    'city': 'City',
    'browser': 'Browser',
    'browser_version': 'Browser Version',
    'os': 'Operating System',
    'os_version': 'OS Version',
    'device': 'Device',
    'screen': 'Screen Size',
    'source': 'Source',
    'referrer': 'Referrer',
    'channel': 'Channel',
    'utm_medium': 'UTM Medium',
    'utm_source': 'UTM Source',
    'utm_campaign': 'UTM Campaign',
    'utm_term': 'UTM Term',
    'utm_content': 'UTM Content',
    'page': 'Page',
    'entry_page': 'Entry Page',
    'exit_page': 'Exit Page',
    'hostname': 'Hostname',
    'goal': 'Goal',
    'props': 'Custom Property'
  }
  return displayNames[dimension]
}
