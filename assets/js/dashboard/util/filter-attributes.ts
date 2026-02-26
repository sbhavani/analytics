import type { FilterOperator } from '../../types/filter-builder'

export interface FilterAttribute {
  id: string
  name: string
  type: 'country' | 'region' | 'city' | 'device' | 'browser' | 'os' | 'string' | 'url' | 'channel' | 'custom'
  operators: FilterOperator[]
}

export const VISITOR_ATTRIBUTES: FilterAttribute[] = [
  {
    id: 'visit:country',
    name: 'Country',
    type: 'country',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:country_name',
    name: 'Country (by name)',
    type: 'country',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:region',
    name: 'Region',
    type: 'region',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:region_name',
    name: 'Region (by name)',
    type: 'region',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:city',
    name: 'City',
    type: 'city',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:city_name',
    name: 'City (by name)',
    type: 'city',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:device',
    name: 'Device',
    type: 'device',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:browser',
    name: 'Browser',
    type: 'browser',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:browser_version',
    name: 'Browser Version',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:os',
    name: 'Operating System',
    type: 'os',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:os_version',
    name: 'OS Version',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:source',
    name: 'Traffic Source',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:channel',
    name: 'Channel',
    type: 'channel',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:referrer',
    name: 'Referrer',
    type: 'url',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'matches_regexp', 'does_not_match_regexp', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:utm_medium',
    name: 'UTM Medium',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:utm_source',
    name: 'UTM Source',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:utm_campaign',
    name: 'UTM Campaign',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:utm_content',
    name: 'UTM Content',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:utm_term',
    name: 'UTM Term',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:screen',
    name: 'Screen Size',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:entry_page',
    name: 'Entry Page',
    type: 'url',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'matches_regexp', 'does_not_match_regexp', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:exit_page',
    name: 'Exit Page',
    type: 'url',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'matches_regexp', 'does_not_match_regexp', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:entry_page_hostname',
    name: 'Entry Hostname',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  },
  {
    id: 'visit:exit_page_hostname',
    name: 'Exit Hostname',
    type: 'string',
    operators: ['equals', 'does_not_equal', 'contains', 'does_not_contain', 'is_set', 'is_not_set']
  }
]

export const OPERATOR_DISPLAY_NAMES: Record<FilterOperator, string> = {
  equals: 'is',
  does_not_equal: 'is not',
  contains: 'contains',
  does_not_contain: 'does not contain',
  matches_regexp: 'matches regex',
  does_not_match_regexp: 'does not match regex',
  is_set: 'is set',
  is_not_set: 'is not set'
}

export const OPERATORS_REQUIRING_VALUE: FilterOperator[] = [
  'equals',
  'does_not_equal',
  'contains',
  'does_not_contain',
  'matches_regexp',
  'does_not_match_regexp'
]

export function getAttributeById(id: string): FilterAttribute | undefined {
  return VISITOR_ATTRIBUTES.find(attr => attr.id === id)
}

export function getOperatorsForAttribute(attributeId: string): FilterOperator[] {
  const attribute = getAttributeById(attributeId)
  return attribute?.operators ?? []
}

export function getAttributeType(attributeId: string): string {
  const attribute = getAttributeById(attributeId)
  return attribute?.type ?? 'string'
}
