import { DashboardState, Filter } from '../dashboard-state'
import { cleanLabels, remapFromApiFilters } from '../util/filters'
import { plainFilterText } from '../util/filter-text'
import { AppNavigationTarget } from '../navigation/use-app-navigate'
import { PlausibleSite } from '../site-context'
import { Role, UserContextValue } from '../user-context'

export enum SegmentType {
  personal = 'personal',
  site = 'site'
}

/** keep in sync with Plausible.Segments */
const ROLES_WITH_MAYBE_SITE_SEGMENTS = [Role.admin, Role.editor, Role.owner]
const ROLES_WITH_PERSONAL_SEGMENTS = [
  Role.billing,
  Role.viewer,
  Role.admin,
  Role.editor,
  Role.owner
]

/** This type signifies that the owner can't be shown. */
type SegmentOwnershipHidden = { owner_id: null; owner_name: null }

/** This type signifies that the original owner has been removed from the site. */
type SegmentOwnershipDangling = { owner_id: null; owner_name: null }

type SegmentOwnership =
  | SegmentOwnershipDangling
  | { owner_id: number; owner_name: string }

export type SavedSegment = {
  id: number
  name: string
  type: SegmentType
  /** datetime in site timezone, example 2025-02-26 10:00:00 */
  inserted_at: string
  /** datetime in site timezone, example 2025-02-26 10:00:00 */
  updated_at: string
} & SegmentOwnership

export type SavedSegmentPublic = Pick<
  SavedSegment,
  'id' | 'type' | 'name' | 'inserted_at' | 'updated_at'
> &
  SegmentOwnershipHidden

export type SegmentDataFromApi = {
  filters: unknown[]
  labels: Record<string, string>
}

/** In this type, filters are parsed to dashboard format */
export type SegmentData = {
  filters: Filter[]
  labels: Record<string, string>
}

export type SavedSegments = Array<
  (SavedSegment | SavedSegmentPublic) & {
    segment_data: SegmentData
  }
>

const SEGMENT_LABEL_KEY_PREFIX = 'segment-'

export function handleSegmentResponse(
  segment: SavedSegment & {
    segment_data: SegmentDataFromApi
  }
): SavedSegment & { segment_data: SegmentData } {
  return {
    ...segment,
    segment_data: parseApiSegmentData(segment.segment_data)
  }
}

export const getSegmentNamePlaceholder = (
  dashboardState: Pick<DashboardState, 'labels' | 'filters'>
) =>
  dashboardState.filters
    .reduce(
      (combinedName, filter) =>
        combinedName.length > 100
          ? combinedName
          : `${combinedName}${combinedName.length ? ' and ' : ''}${plainFilterText(dashboardState, filter)}`,
      ''
    )
    .slice(0, 255)

export function isSegmentIdLabelKey(labelKey: string): boolean {
  return labelKey.startsWith(SEGMENT_LABEL_KEY_PREFIX)
}

export function formatSegmentIdAsLabelKey(id: number | string): string {
  return `${SEGMENT_LABEL_KEY_PREFIX}${id}`
}

export const isSegmentFilter = (
  filter: Filter
): filter is ['is', 'segment', (number | string)[]] => {
  const [operation, dimension, clauses] = filter
  return operation === 'is' && dimension === 'segment' && Array.isArray(clauses)
}

export const parseApiSegmentData = ({
  filters,
  ...rest
}: {
  filters: unknown[]
  labels: Record<string, string>
}): SegmentData => ({
  filters: remapFromApiFilters(filters),
  ...rest
})

export function getSearchToRemoveSegmentFilter(): Required<AppNavigationTarget>['search'] {
  return (searchRecord) => {
    const updatedFilters = (
      (Array.isArray(searchRecord.filters)
        ? searchRecord.filters
        : []) as Filter[]
    ).filter((f) => !isSegmentFilter(f))
    const currentLabels = searchRecord.labels ?? {}
    return {
      ...searchRecord,
      filters: updatedFilters,
      labels: cleanLabels(updatedFilters, currentLabels)
    }
  }
}

export function getSearchToSetSegmentFilter(
  segment: Pick<SavedSegment, 'id' | 'name'>,
  options: { omitAllOtherFilters?: boolean } = {}
): Required<AppNavigationTarget>['search'] {
  return (searchRecord) => {
    const otherFilters = (
      (Array.isArray(searchRecord.filters)
        ? searchRecord.filters
        : []) as Filter[]
    ).filter((f) => !isSegmentFilter(f))
    const currentLabels = searchRecord.labels ?? {}

    const filters = [
      ['is', 'segment', [segment.id]],
      ...(options.omitAllOtherFilters ? [] : otherFilters)
    ]

    const labels = cleanLabels(filters, currentLabels, 'segment', {
      [formatSegmentIdAsLabelKey(segment.id)]: segment.name
    })
    return {
      ...searchRecord,
      filters,
      labels
    }
  }
}

export const SEGMENT_TYPE_LABELS = {
  [SegmentType.personal]: 'Personal segment',
  [SegmentType.site]: 'Site segment'
}

export function resolveFilters(
  filters: Filter[],
  segments: Array<Pick<SavedSegment, 'id'> & { segment_data: SegmentData }>
): Filter[] {
  let segmentsInFilter = 0
  return filters.flatMap((filter): Filter[] => {
    if (isSegmentFilter(filter)) {
      segmentsInFilter++
      const [_operation, _dimension, clauses] = filter
      if (segmentsInFilter > 1 || clauses.length !== 1) {
        throw new Error('Dashboard can be filtered by only one segment')
      }
      const segment = segments.find(
        (segment) => String(segment.id) == String(clauses[0])
      )
      return segment ? segment.segment_data.filters : [filter]
    } else {
      return [filter]
    }
  })
}

export function canExpandSegment({
  segment,
  user
}: {
  segment: Pick<SavedSegment, 'id' | 'owner_id' | 'type'>
  user: UserContextValue
}) {
  if (
    segment.type === SegmentType.site &&
    user.loggedIn &&
    ROLES_WITH_MAYBE_SITE_SEGMENTS.includes(user.role)
  ) {
    return true
  }

  if (
    segment.type === SegmentType.personal &&
    user.loggedIn &&
    ROLES_WITH_PERSONAL_SEGMENTS.includes(user.role) &&
    user.id === segment.owner_id
  ) {
    return true
  }

  return false
}

export function isListableSegment({
  segment,
  site,
  user
}: {
  segment:
    | Pick<SavedSegment, 'id' | 'type' | 'owner_id'>
    | Pick<SavedSegmentPublic, 'id' | 'type' | 'owner_id'>
  site: Pick<PlausibleSite, 'siteSegmentsAvailable'>
  user: UserContextValue
}) {
  if (segment.type === SegmentType.site && site.siteSegmentsAvailable) {
    return true
  }

  if (segment.type === SegmentType.personal) {
    if (!user.loggedIn || user.id === null || user.role === Role.public) {
      return false
    }
    return segment.owner_id === user.id
  }

  return false
}

export function canSeeSegmentDetails({ user }: { user: UserContextValue }) {
  return user.loggedIn && user.role !== Role.public
}

export function canRemoveFilter(
  filter: Filter,
  limitedToSegment: Pick<SavedSegment, 'id' | 'name'> | null
) {
  if (isSegmentFilter(filter) && limitedToSegment) {
    const [_operation, _dimension, clauses] = filter
    return (
      clauses.length === 1 && String(limitedToSegment.id) === String(clauses[1])
    )
  }
  return true
}

export function findAppliedSegmentFilter({ filters }: { filters: Filter[] }) {
  const segmentFilter = filters.find(isSegmentFilter)
  if (!segmentFilter) {
    return undefined
  }
  const [_operation, _dimension, clauses] = segmentFilter
  if (clauses.length !== 1) {
    throw new Error('Dashboard can be filtered by only one segment')
  }
  return segmentFilter
}

// =============================================================================
// Advanced Filter Builder Types
// =============================================================================

/** Filter operator types for the advanced filter builder */
export type FilterOperatorType = 'is' | 'is_not' | 'contains' | 'contains_not'

/** A single filter condition in the advanced filter builder */
export type FilterCondition = {
  id: string
  dimension: string
  operator: FilterOperatorType
  value: string[]
}

/** Logic type for combining conditions or groups */
export type FilterLogic = 'AND' | 'OR'

/** A condition group that can contain conditions or nested groups */
export type ConditionGroup = {
  id: string
  logic: FilterLogic
  children: FilterItem[]
  depth: number
}

/** Union type for filter items (conditions or groups) */
export type FilterItem = FilterCondition | ConditionGroup

/** Root filter structure for advanced filter builder */
export type AdvancedFilter = {
  items: FilterItem[]
}

/** Validation result for filter structure */
export type FilterValidationResult = {
  valid: boolean
  errors: string[]
}

/** Maximum nesting depth for condition groups */
export const MAX_FILTER_DEPTH = 3

/**
 * Creates a new filter condition with default values
 */
export function createFilterCondition(overrides?: Partial<FilterCondition>): FilterCondition {
  return {
    id: crypto.randomUUID(),
    dimension: '',
    operator: 'is',
    value: [],
    ...overrides
  }
}

/**
 * Creates a new condition group with default values
 */
export function createConditionGroup(
  depth: number = 1,
  overrides?: Partial<ConditionGroup>
): ConditionGroup {
  return {
    id: crypto.randomUUID(),
    logic: 'AND',
    children: [],
    depth,
    ...overrides
  }
}

/**
 * Validates a filter condition
 */
export function validateFilterCondition(condition: FilterCondition): string[] {
  const errors: string[] = []

  if (!condition.dimension) {
    errors.push('Dimension is required')
  }

  if (!condition.operator) {
    errors.push('Operator is required')
  }

  if (!condition.value || condition.value.length === 0) {
    errors.push('At least one value is required')
  }

  return errors
}

/**
 * Validates the depth of nested condition groups
 */
export function validateFilterDepth(group: ConditionGroup): string[] {
  const errors: string[] = []

  if (group.depth > MAX_FILTER_DEPTH) {
    errors.push(`Maximum nesting depth of ${MAX_FILTER_DEPTH} exceeded`)
  }

  for (const child of group.children) {
    if ('children' in child) {
      errors.push(...validateFilterDepth(child))
    }
  }

  return errors
}

/**
 * Validates the entire filter structure
 */
export function validateAdvancedFilter(filter: AdvancedFilter): FilterValidationResult {
  const errors: string[] = []

  if (!filter.items || filter.items.length === 0) {
    errors.push('At least one filter condition is required')
  }

  for (const item of filter.items) {
    if ('children' in item) {
      errors.push(...validateFilterDepth(item))
    } else {
      errors.push(...validateFilterCondition(item))
    }
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

/**
 * Converts advanced filter to legacy filter format for API compatibility
 */
export function advancedFilterToLegacyFilters(filter: AdvancedFilter): Filter[] {
  const result: Filter[] = []

  function processItem(item: FilterItem): Filter[] {
    if ('children' in item) {
      // It's a group - process children based on logic
      const childFilters = item.children.flatMap(processItem)
      if (childFilters.length === 0) return []

      if (item.logic === 'OR') {
        return [['or', childFilters] as Filter]
      } else {
        // AND logic - flatten
        return childFilters
      }
    } else {
      // It's a condition
      return [[item.operator, item.dimension, item.value] as Filter]
    }
  }

  for (const item of filter.items) {
    result.push(...processItem(item))
  }

  return result
}
