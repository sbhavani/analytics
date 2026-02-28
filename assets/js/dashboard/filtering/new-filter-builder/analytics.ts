/**
 * Analytics events for the Filter Builder
 */

export type FilterBuilderEvent =
  | { type: 'FILTER_BUILDER_OPENED'; source?: string }
  | { type: 'CONDITION_ADDED'; attribute: string; operator: string }
  | { type: 'CONDITION_UPDATED'; attribute: string; field: string }
  | { type: 'CONDITION_DELETED'; attribute: string }
  | { type: 'CONNECTOR_CHANGED'; from: string; to: string; groupId: string }
  | { type: 'NESTED_GROUP_ADDED'; depth: number }
  | { type: 'NESTED_GROUP_DELETED'; depth: number }
  | { type: 'SEGMENT_SAVED'; segmentId: number; name: string }
  | { type: 'SEGMENT_APPLIED'; hasNestedGroups: boolean; conditionCount: number }
  | { type: 'FILTER_APPLIED'; conditionCount: number; hasOr: boolean; hasNested: boolean }
  | { type: 'FILTER_CLEARED' }

interface AnalyticsConfig {
  trackEvent: (event: string, properties?: Record<string, unknown>) => void
}

let analyticsConfig: AnalyticsConfig | null = null

/**
 * Initialize analytics tracking for the Filter Builder
 */
export function initFilterBuilderAnalytics(config: AnalyticsConfig): void {
  analyticsConfig = config
}

/**
 * Track a Filter Builder event
 */
export function trackFilterBuilderEvent(event: FilterBuilderEvent): void {
  if (!analyticsConfig) {
    console.warn('[FilterBuilder] Analytics not initialized')
    return
  }

  const [eventType, properties] = eventToProps(event)
  analyticsConfig.trackEvent(eventType, properties)
}

function eventToProps(event: FilterBuilderEvent): [string, Record<string, unknown>] {
  switch (event.type) {
    case 'FILTER_BUILDER_OPENED':
      return ['Filter Builder Opened', { source: event.source }]

    case 'CONDITION_ADDED':
      return ['Filter Condition Added', { attribute: event.attribute, operator: event.operator }]

    case 'CONDITION_UPDATED':
      return ['Filter Condition Updated', { attribute: event.attribute, field: event.field }]

    case 'CONDITION_DELETED':
      return ['Filter Condition Deleted', { attribute: event.attribute }]

    case 'CONNECTOR_CHANGED':
      return ['Filter Connector Changed', { from: event.from, to: event.to, groupId: event.groupId }]

    case 'NESTED_GROUP_ADDED':
      return ['Filter Nested Group Added', { depth: event.depth }]

    case 'NESTED_GROUP_DELETED':
      return ['Filter Nested Group Deleted', { depth: event.depth }]

    case 'SEGMENT_SAVED':
      return ['Filter Segment Saved', { segmentId: event.segmentId, name: event.name }]

    case 'SEGMENT_APPLIED':
      return ['Filter Segment Applied', { hasNestedGroups: event.hasNestedGroups, conditionCount: event.conditionCount }]

    case 'FILTER_APPLIED':
      return ['Filter Applied', {
        conditionCount: event.conditionCount,
        hasOr: event.hasOr,
        hasNested: event.hasNested
      }]

    case 'FILTER_CLEARED':
      return ['Filter Cleared', {}]

    default:
      return ['Unknown Event', {}]
  }
}

/**
 * Hook to use analytics in components
 */
export function useFilterBuilderAnalytics() {
  return {
    trackEvent: trackFilterBuilderEvent
  }
}
