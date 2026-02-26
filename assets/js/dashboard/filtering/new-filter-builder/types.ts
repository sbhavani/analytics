import { SavedSegment } from '../filtering/segments'

/**
 * Represents a single filter condition in the builder UI.
 */
export interface FilterCondition {
  id: string
  dimension: string
  operator: string
  value: string | string[]
}

/**
 * Represents a collection of conditions combined with a logical operator.
 */
export interface FilterGroup {
  id: string
  operator: 'and' | 'or'
  children: FilterTreeNode[]
}

/**
 * Union type for filter tree nodes (condition or group).
 */
export type FilterTreeNode = FilterCondition | FilterGroup

/**
 * The root filter tree structure.
 */
export type FilterTree = FilterGroup

/**
 * Saved filter configuration for reuse.
 * Extends existing SavedSegment with filters field.
 */
export interface FilterTemplate extends Omit<SavedSegment, 'inserted_at' | 'updated_at' | 'owner_id' | 'owner_name'> {
  id?: number
  name: string
  type: 'personal' | 'site'
  filters: FilterGroup
  description?: string
}

/**
 * API representation of a filter condition (without internal id).
 */
export interface ApiFilterCondition {
  dimension: string
  operator: string
  value: string | string[]
}

/**
 * API representation of a filter group (without internal id).
 */
export interface ApiFilterGroup {
  operator: 'and' | 'or'
  children: ApiFilterTreeNode[]
}

/**
 * Union type for API filter tree nodes.
 */
export type ApiFilterTreeNode = ApiFilterCondition | ApiFilterGroup

/**
 * Available filter dimension options for the filter builder.
 */
export interface DimensionOption {
  value: string
  label: string
  group: string
}

/**
 * List of available dimensions grouped by category.
 */
export const AVAILABLE_DIMENSIONS: DimensionOption[] = [
  // Page filters
  { value: 'page', label: 'Page', group: 'Pages' },
  { value: 'entry_page', label: 'Entry page', group: 'Pages' },
  { value: 'exit_page', label: 'Exit page', group: 'Pages' },

  // Source filters
  { value: 'source', label: 'Source', group: 'Sources' },
  { value: 'channel', label: 'Channel', group: 'Sources' },
  { value: 'referrer', label: 'Referrer URL', group: 'Sources' },

  // UTM filters
  { value: 'utm_medium', label: 'UTM medium', group: 'UTM Tags' },
  { value: 'utm_source', label: 'UTM source', group: 'UTM Tags' },
  { value: 'utm_campaign', label: 'UTM campaign', group: 'UTM Tags' },
  { value: 'utm_term', label: 'UTM term', group: 'UTM Tags' },
  { value: 'utm_content', label: 'UTM content', group: 'UTM Tags' },

  // Location filters
  { value: 'country', label: 'Country', group: 'Location' },
  { value: 'region', label: 'Region', group: 'Location' },
  { value: 'city', label: 'City', group: 'Location' },

  // Device filters
  { value: 'browser', label: 'Browser', group: 'Devices' },
  { value: 'browser_version', label: 'Browser version', group: 'Devices' },
  { value: 'os', label: 'Operating system', group: 'Devices' },
  { value: 'os_version', label: 'OS version', group: 'Devices' },
  { value: 'screen', label: 'Screen size', group: 'Devices' },

  // Other
  { value: 'hostname', label: 'Hostname', group: 'Other' },
  { value: 'goal', label: 'Goal', group: 'Goals' },
]

/**
 * Get unique dimension groups.
 */
export function getDimensionGroups(): string[] {
  const groups = new Set(AVAILABLE_DIMENSIONS.map((d) => d.group))
  return Array.from(groups)
}

/**
 * Get dimensions by group.
 */
export function getDimensionsByGroup(group: string): DimensionOption[] {
  return AVAILABLE_DIMENSIONS.filter((d) => d.group === group)
}
