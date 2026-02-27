export type Connector = 'AND' | 'OR'

export interface FilterCondition {
  id: string
  field: string
  operator: string
  value: string
  negated?: boolean
}

export interface FilterGroup {
  id: string
  connector: Connector
  conditions: FilterCondition[]
  subgroups: FilterGroup[]
}

export interface FilterTree {
  rootGroup: FilterGroup
}

export interface FilterTemplate {
  id: string
  site_id: string
  name: string
  filter_tree: FilterTree
  inserted_at: string
  updated_at: string
}

export interface FilterField {
  key: string
  label: string
  type: 'string' | 'number' | 'boolean' | 'set'
  operators: string[]
}

export const VISITOR_FIELDS: FilterField[] = [
  { key: 'country', label: 'Country', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'region', label: 'Region', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'city', label: 'City', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'device', label: 'Device', type: 'set', operators: ['equals', 'does_not_equal', 'is_one_of'] },
  { key: 'browser', label: 'Browser', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'os', label: 'Operating System', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'source', label: 'Traffic Source', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'utm_medium', label: 'UTM Medium', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'utm_source', label: 'UTM Source', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'utm_campaign', label: 'UTM Campaign', type: 'string', operators: ['equals', 'does_not_equal', 'contains', 'is_one_of'] },
  { key: 'utm_content', label: 'UTM Content', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'utm_term', label: 'UTM Term', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'hostname', label: 'Hostname', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'entry_page', label: 'Entry Page', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'exit_page', label: 'Exit Page', type: 'string', operators: ['equals', 'does_not_equal', 'contains'] },
  { key: 'pageviews', label: 'Pageviews', type: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than', 'greater_or_equal', 'less_or_equal'] },
  { key: 'events', label: 'Events', type: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than', 'greater_or_equal', 'less_or_equal'] },
  { key: 'duration', label: 'Session Duration (seconds)', type: 'number', operators: ['equals', 'not_equals', 'greater_than', 'less_than', 'greater_or_equal', 'less_or_equal'] },
  { key: 'is_bounce', label: 'Is Bounce', type: 'boolean', operators: ['is_true', 'is_false'] },
  { key: 'channel', label: 'Traffic Channel', type: 'string', operators: ['equals', 'does_not_equal', 'is_one_of'] },
]

export const DEVICE_OPTIONS = ['Desktop', 'Mobile', 'Tablet']
