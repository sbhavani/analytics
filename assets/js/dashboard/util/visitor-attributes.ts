// Visitor attributes configuration for the Advanced Filter Builder
// Defines all available fields that can be used in filter conditions

import { FilterOperator, VisitorAttribute } from '../components/filter-builder/types'

// Base operators available for most fields
const STRING_OPERATORS: FilterOperator[] = [
  'is',
  'is_not',
  'contains',
  'contains_not',
  'is_set',
  'is_not_set'
]

const ENUM_OPERATORS: FilterOperator[] = [
  'is',
  'is_not',
  'is_set',
  'is_not_set'
]

const NUMERIC_OPERATORS: FilterOperator[] = [
  'is',
  'is_not',
  'greater_than',
  'less_than',
  'is_set',
  'is_not_set'
]

// Visitor attributes available for filtering
export const VISITOR_ATTRIBUTES: VisitorAttribute[] = [
  // Location attributes
  {
    key: 'country',
    label: 'Country',
    type: 'enum',
    operators: ENUM_OPERATORS
  },
  {
    key: 'region',
    label: 'Region',
    type: 'enum',
    operators: ENUM_OPERATORS
  },
  {
    key: 'city',
    label: 'City',
    type: 'enum',
    operators: ENUM_OPERATORS
  },

  // Page attributes
  {
    key: 'page',
    label: 'Page',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'entry_page',
    label: 'Entry Page',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'exit_page',
    label: 'Exit Page',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'hostname',
    label: 'Hostname',
    type: 'string',
    operators: STRING_OPERATORS
  },

  // Source/Referrer attributes
  {
    key: 'source',
    label: 'Source',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'channel',
    label: 'Channel',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'referrer',
    label: 'Referrer URL',
    type: 'string',
    operators: STRING_OPERATORS
  },

  // Device attributes
  {
    key: 'browser',
    label: 'Browser',
    type: 'enum',
    operators: ENUM_OPERATORS
  },
  {
    key: 'browser_version',
    label: 'Browser Version',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'os',
    label: 'Operating System',
    type: 'enum',
    operators: ENUM_OPERATORS
  },
  {
    key: 'os_version',
    label: 'OS Version',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'screen',
    label: 'Screen Size',
    type: 'enum',
    operators: ENUM_OPERATORS
  },

  // UTM attributes
  {
    key: 'utm_medium',
    label: 'UTM Medium',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'utm_source',
    label: 'UTM Source',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'utm_campaign',
    label: 'UTM Campaign',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'utm_term',
    label: 'UTM Term',
    type: 'string',
    operators: STRING_OPERATORS
  },
  {
    key: 'utm_content',
    label: 'UTM Content',
    type: 'string',
    operators: STRING_OPERATORS
  },

  // Goal and Custom Properties
  {
    key: 'goal',
    label: 'Goal',
    type: 'enum',
    operators: ['is', 'is_not', 'is_set', 'is_not_set']
  },
  {
    key: 'props',
    label: 'Property',
    type: 'string',
    operators: STRING_OPERATORS
  },

  // Segment
  {
    key: 'segment',
    label: 'Segment',
    type: 'enum',
    operators: ENUM_OPERATORS
  }
]

// Group visitor attributes by category for UI organization
export const VISITOR_ATTRIBUTE_GROUPS = {
  location: {
    label: 'Location',
    attributes: ['country', 'region', 'city']
  },
  page: {
    label: 'Page',
    attributes: ['page', 'entry_page', 'exit_page', 'hostname']
  },
  source: {
    label: 'Source',
    attributes: ['source', 'channel', 'referrer']
  },
  device: {
    label: 'Device',
    attributes: ['browser', 'browser_version', 'os', 'os_version', 'screen']
  },
  utm: {
    label: 'UTM Tags',
    attributes: ['utm_medium', 'utm_source', 'utm_campaign', 'utm_term', 'utm_content']
  },
  conversion: {
    label: 'Conversion',
    attributes: ['goal', 'props']
  },
  segment: {
    label: 'Segment',
    attributes: ['segment']
  }
}

// Get all attribute keys
export const VISITOR_ATTRIBUTE_KEYS = VISITOR_ATTRIBUTES.map((attr) => attr.key)

// Get attribute by key
export function getAttributeByKey(key: string): VisitorAttribute | undefined {
  return VISITOR_ATTRIBUTES.find((attr) => attr.key === key)
}

// Get attributes for a specific group
export function getAttributesByGroup(groupKey: keyof typeof VISITOR_ATTRIBUTE_GROUPS): VisitorAttribute[] {
  const group = VISITOR_ATTRIBUTE_GROUPS[groupKey]
  if (!group) return []

  return VISITOR_ATTRIBUTES.filter((attr) => group.attributes.includes(attr.key))
}

// Get all grouped attributes
export function getGroupedAttributes(): Array<{ group: string; label: string; attributes: VisitorAttribute[] }> {
  return Object.entries(VISITOR_ATTRIBUTE_GROUPS).map(([key, { label, attributes }]) => ({
    group: key,
    label,
    attributes: VISITOR_ATTRIBUTES.filter((attr) => attributes.includes(attr.key))
  }))
}

// Check if an attribute supports a specific operator
export function attributeSupportsOperator(key: string, operator: FilterOperator): boolean {
  const attribute = getAttributeByKey(key)
  return attribute?.operators.includes(operator) ?? false
}

// Get operators available for a specific attribute
export function getOperatorsForAttribute(key: string): FilterOperator[] {
  const attribute = getAttributeByKey(key)
  return attribute?.operators ?? []
}
