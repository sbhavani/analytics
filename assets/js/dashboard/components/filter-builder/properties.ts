/**
 * Visitor properties configuration for the Filter Builder
 * Defines available properties and their supported operators
 */

import { VisitorProperty, FilterOperator } from './types'

const stringOperators: FilterOperator[] = [
  'equals',
  'not_equals',
  'contains',
  'does_not_contain',
  'is_one_of'
]

const numericOperators: FilterOperator[] = [
  'equals',
  'not_equals',
  'greater_than',
  'less_than',
  'greater_than_or_equals',
  'less_than_or_equals'
]

/**
 * List of available visitor properties for filtering
 */
export const VISITOR_PROPERTIES: VisitorProperty[] = [
  {
    key: 'visit:country',
    name: 'Country',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:region',
    name: 'Region',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:city',
    name: 'City',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:device',
    name: 'Device',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:browser',
    name: 'Browser',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:browser_version',
    name: 'Browser Version',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:os',
    name: 'Operating System',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:os_version',
    name: 'OS Version',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:source',
    name: 'Source',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:referrer',
    name: 'Referrer',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:entry_page',
    name: 'Entry Page',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:page',
    name: 'Page',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:goal',
    name: 'Goal',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'visit:pages_viewed',
    name: 'Pages Viewed',
    type: 'numeric',
    operators: numericOperators
  },
  {
    key: 'visit:duration',
    name: 'Session Duration (seconds)',
    type: 'numeric',
    operators: numericOperators
  },
  {
    key: 'event:name',
    name: 'Event Name',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'event:page',
    name: 'Event Page',
    type: 'string',
    operators: stringOperators
  },
  {
    key: 'event:props',
    name: 'Event Property',
    type: 'string',
    operators: stringOperators
  }
]

/**
 * Get property by key
 */
export function getPropertyByKey(key: string): VisitorProperty | undefined {
  return VISITOR_PROPERTIES.find(p => p.key === key)
}

/**
 * Get available operators for a property
 */
export function getOperatorsForProperty(propertyKey: string): FilterOperator[] {
  const property = getPropertyByKey(propertyKey)
  return property?.operators ?? []
}

/**
 * Get property type
 */
export function getPropertyType(propertyKey: string): 'string' | 'numeric' | 'list' | undefined {
  const property = getPropertyByKey(propertyKey)
  return property?.type
}

/**
 * Generate unique ID for filter elements
 */
export function generateId(): string {
  return `fb-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
}

/**
 * Get display name for operator
 */
export function getOperatorDisplayName(operator: string): string {
  const displayNames: Record<string, string> = {
    equals: 'equals',
    not_equals: 'does not equal',
    contains: 'contains',
    does_not_contain: 'does not contain',
    greater_than: 'greater than',
    less_than: 'less than',
    greater_than_or_equals: 'at least',
    less_than_or_equals: 'at most',
    is_one_of: 'is one of'
  }
  return displayNames[operator] ?? operator
}

/**
 * Get all available operators
 */
export function getAllOperators(): { value: FilterOperator; label: string }[] {
  return [
    { value: 'equals', label: 'equals' },
    { value: 'not_equals', label: 'does not equal' },
    { value: 'contains', label: 'contains' },
    { value: 'does_not_contain', label: 'does not contain' },
    { value: 'greater_than', label: 'greater than' },
    { value: 'less_than', label: 'less than' },
    { value: 'greater_than_or_equals', label: 'at least' },
    { value: 'less_than_or_equals', label: 'at most' },
    { value: 'is_one_of', label: 'is one of' }
  ]
}
