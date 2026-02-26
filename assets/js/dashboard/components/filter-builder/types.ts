/**
 * Filter Builder Types
 *
 * Types for the Advanced Filter Builder feature that allows users
 * to combine multiple filter conditions with AND/OR logic for custom visitor segments.
 */

import { Filter } from '../../dashboard-state'

/**
 * Supported comparison operators for filter conditions
 */
export type FilterOperator =
  | 'equals'
  | 'not_equals'
  | 'contains'
  | 'not_contains'
  | 'greater_than'
  | 'less_than'
  | 'matches_regex'
  | 'is_set'
  | 'is_not_set'

/**
 * Logical operators for combining conditions/groups
 */
export type LogicalOperator = 'AND' | 'OR'

/**
 * A single filter condition (leaf node in the expression tree)
 */
export interface FilterCondition {
  /** Unique identifier for this condition */
  id: string
  /** The visitor attribute to filter on (e.g., "country", "pageviews") */
  field: string
  /** The comparison operator */
  operator: FilterOperator
  /** The value to compare against (null for is_set/is_not_set) */
  value: string | number | boolean | null
}

/**
 * A group of conditions combined with a logical operator
 * Can contain both leaf conditions and nested groups
 */
export interface ConditionGroup {
  /** Unique identifier for this group */
  id: string
  /** Logical operator for combining children */
  operator: LogicalOperator
  /** Child conditions and/or nested groups */
  conditions: FilterExpressionNode[]
}

/**
 * Union type for any node in the filter expression tree
 */
export type FilterExpressionNode = FilterCondition | ConditionGroup

/**
 * The complete filter expression tree
 */
export interface FilterExpression {
  /** Schema version for future compatibility */
  version: 1
  /** The root group containing all conditions */
  rootGroup: ConditionGroup
}

/**
 * Filter builder state for managing the current editing session
 */
export interface FilterBuilderState {
  /** The current filter expression being built */
  expression: FilterExpression | null
  /** Whether the builder is in edit mode for an existing segment */
  editingSegmentId: number | null
  /** Whether there are unsaved changes */
  isDirty: boolean
  /** Validation errors */
  errors: FilterBuilderError[]
}

/**
 * Validation error for the filter builder
 */
export interface FilterBuilderError {
  /** Error type */
  type: FilterBuilderErrorType
  /** Path to the problematic element */
  path: string
  /** Human-readable message */
  message: string
}

export type FilterBuilderErrorType =
  | 'field_required'
  | 'operator_required'
  | 'value_required'
  | 'max_depth_exceeded'
  | 'max_conditions_exceeded'
  | 'invalid_field'

/**
 * Available visitor fields for filtering
 * These should match the backend filter dimensions
 */
export interface FilterField {
  /** Unique identifier */
  key: string
  /** Display name */
  name: string
  /** Type of value expected */
  type: 'string' | 'number' | 'boolean' | 'enum'
  /** Whether this field supports specific operators */
  supportedOperators?: FilterOperator[]
}

/**
 * Default available filter fields
 */
export const DEFAULT_FILTER_FIELDS: FilterField[] = [
  { key: 'country', name: 'Country', type: 'enum' },
  { key: 'region', name: 'Region', type: 'string' },
  { key: 'city', name: 'City', type: 'string' },
  { key: 'source', name: 'Source', type: 'string' },
  { key: 'referrer', name: 'Referrer', type: 'string' },
  { key: 'utm_medium', name: 'UTM Medium', type: 'string' },
  { key: 'utm_source', name: 'UTM Source', type: 'string' },
  { key: 'utm_campaign', name: 'UTM Campaign', type: 'string' },
  { key: 'utm_term', name: 'UTM Term', type: 'string' },
  { key: 'utm_content', name: 'UTM Content', type: 'string' },
  { key: 'page', name: 'Page', type: 'string' },
  { key: 'entry_page', name: 'Entry Page', type: 'string' },
  { key: 'exit_page', name: 'Exit Page', type: 'string' },
  { key: 'hostname', name: 'Hostname', type: 'string' },
  { key: 'browser', name: 'Browser', type: 'enum' },
  { key: 'browser_version', name: 'Browser Version', type: 'string' },
  { key: 'os', name: 'Operating System', type: 'enum' },
  { key: 'os_version', name: 'OS Version', type: 'string' },
  { key: 'device', name: 'Device', type: 'enum' },
  { key: 'screen_size', name: 'Screen Size', type: 'enum' }
]

/**
 * Operators available for each field type
 */
export const OPERATORS_BY_FIELD_TYPE: Record<FilterField['type'], FilterOperator[]> = {
  string: ['equals', 'not_equals', 'contains', 'not_contains', 'matches_regex', 'is_set', 'is_not_set'],
  number: ['equals', 'not_equals', 'greater_than', 'less_than', 'is_set', 'is_not_set'],
  boolean: ['equals', 'is_set', 'is_not_set'],
  enum: ['equals', 'not_equals', 'is_set', 'is_not_set']
}

/**
 * Human-readable names for operators
 */
export const OPERATOR_DISPLAY_NAMES: Record<FilterOperator, string> = {
  equals: 'is',
  not_equals: 'is not',
  contains: 'contains',
  not_contains: 'does not contain',
  greater_than: 'is greater than',
  less_than: 'is less than',
  matches_regex: 'matches regex',
  is_set: 'is set',
  is_not_set: 'is not set'
}

/**
 * Segment data structure for API communication
 * Extends existing segment_data format
 */
export interface SegmentDataWithExpression {
  filters?: unknown[]
  expression?: FilterExpression
  labels?: Record<string, string>
}

/**
 * Convert FilterExpression to legacy flat Filter array for backward compatibility
 */
export function expressionToFilters(expression: FilterExpression): Filter[] {
  return flattenExpression(expression.rootGroup)
}

/**
 * Flatten the expression tree to legacy filter format
 */
function flattenExpression(group: ConditionGroup): Filter[] {
  const filters: Filter[] = []

  for (const condition of group.conditions) {
    if ('field' in condition) {
      // Leaf condition
      filters.push(conditionToFilter(condition as FilterCondition))
    } else {
      // Nested group - flatten recursively (for backward compat, just take all conditions)
      filters.push(...flattenExpression(condition as ConditionGroup))
    }
  }

  return filters
}

/**
 * Convert a single FilterCondition to legacy Filter format
 */
function conditionToFilter(condition: FilterCondition): Filter {
  const { field, operator, value } = condition

  // Map our operator to legacy format
  let legacyOperator: string
  let legacyValue: string[]

  switch (operator) {
    case 'equals':
      legacyOperator = 'is'
      legacyValue = Array.isArray(value) ? value as string[] : [String(value)]
      break
    case 'not_equals':
      legacyOperator = 'is_not'
      legacyValue = Array.isArray(value) ? value as string[] : [String(value)]
      break
    case 'contains':
      legacyOperator = 'contains'
      legacyValue = [String(value)]
      break
    case 'not_contains':
      legacyOperator = 'contains_not'
      legacyValue = [String(value)]
      break
    case 'greater_than':
      legacyOperator = 'is'
      legacyValue = [String(value)]
      break
    case 'less_than':
      legacyOperator = 'is'
      legacyValue = [String(value)]
      break
    case 'matches_regex':
      legacyOperator = 'matches'
      legacyValue = [String(value)]
      break
    case 'is_set':
      legacyOperator = 'is_not_null'
      legacyValue = [field]
      break
    case 'is_not_set':
      legacyOperator = 'is_null'
      legacyValue = [field]
      break
    default:
      legacyOperator = 'is'
      legacyValue = [String(value)]
  }

  return [legacyOperator, field, legacyValue]
}

/**
 * Generate a unique ID for conditions and groups
 */
export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`
}

/**
 * Create a new empty filter expression
 */
export function createEmptyExpression(): FilterExpression {
  return {
    version: 1,
    rootGroup: {
      id: generateId(),
      operator: 'AND',
      conditions: []
    }
  }
}

/**
 * Create a new filter condition with defaults
 */
export function createCondition(field: string = '', operator: FilterOperator = 'equals', value: string | number | boolean | null = null): FilterCondition {
  return {
    id: generateId(),
    field,
    operator,
    value
  }
}

/**
 * Create a new condition group with defaults
 */
export function createConditionGroup(operator: LogicalOperator = 'AND'): ConditionGroup {
  return {
    id: generateId(),
    operator,
    conditions: []
  }
}
