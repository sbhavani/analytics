import React, { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSiteContext } from '../../site-context'
import { useFilterBuilder, FilterCondition, FilterGroup, FilterNode } from './FilterBuilderContext'
import { getDimensionLabel } from './DimensionSelector'
import { numberShortFormatter } from '../../util/number-formatter'
import { serializeApiFilters } from '../../util/filters'
import * as url from '../../util/url'
import * as api from '../../api'

/**
 * Operator display labels
 */
const OPERATOR_LABELS: Record<string, string> = {
  is: 'is',
  is_not: 'is not',
  contains: 'contains',
  contains_not: 'does not contain',
  greater_than: 'is greater than',
  less_than: 'is less than',
  between: 'is between',
  has_done: 'has done',
  has_not_done: 'has not done'
}

/**
 * Get the display label for an operator.
 */
function getOperatorLabel(operator: string): string {
  return OPERATOR_LABELS[operator] || operator
}

/**
 * Format a single condition for display.
 */
function formatCondition(condition: FilterCondition): string {
  const dimension = getDimensionLabel(condition.dimension)
  const operator = getOperatorLabel(condition.operator)
  const value = Array.isArray(condition.value)
    ? condition.value.join(', ')
    : condition.value

  return `${dimension} ${operator} "${value}"`
}

/**
 * Format a group of conditions for display.
 */
function formatGroup(group: FilterGroup, indent: number = 0): string {
  const prefix = '  '.repeat(indent)
  const operatorLabel = group.operator === 'AND' ? 'AND' : 'OR'

  const parts = group.children.map((child) => {
    if ('children' in child) {
      return formatGroup(child, indent + 1)
    }
    return formatCondition(child)
  })

  return parts.join(`\n${prefix}${operatorLabel} `)
}

/**
 * Get a readable summary of the current filter.
 */
function getFilterSummary(filters: FilterNode[]): string {
  if (filters.length === 0) {
    return 'No filters applied'
  }

  if (filters.length === 1) {
    const item = filters[0]
    if ('children' in item) {
      return formatGroup(item)
    }
    return formatCondition(item)
  }

  // Multiple top-level items - join with AND
  return filters.map((item) => {
    if ('children' in item) {
      return `(${formatGroup(item)})`
    }
    return formatCondition(item)
  }).join(' AND ')
}

/**
 * Convert filter to API format for querying stats.
 * Returns filters in the Filter type format: [[operator, dimension, [value]], ...]
 */
function filtersToApiFormat(filters: FilterNode[]): [string, string, string[]][] {
  return filters.map((node): [string, string, string[]] => {
    if ('children' in node) {
      // It's a group - for now, flatten to individual conditions (simpler approach)
      // A more complete solution would handle nested groups properly
      const childFilters = filtersToApiFormat(node.children)
      return [node.operator.toLowerCase(), '', []] as unknown as [string, string, string[]]
    }
    // It's a condition - format as [operator, dimension, [value]]
    const value = Array.isArray(node.value) ? node.value : [node.value]
    return [node.operator, node.dimension, value]
  }).filter((f): f is [string, string, string[]] => f[1] !== '')
}

interface TopStatsResponse {
  metrics: Array<{
    name: string
    value: number
    graph_metric: string
  }>
}

/**
 * FilterSummary component displays a readable summary of the current filter
 * along with a preview of how many visitors match the filter.
 */
export default function FilterSummary() {
  const site = useSiteContext()
  const { filters } = useFilterBuilder()

  // Convert filters to API format (Filter type: [operator, key, values])
  const apiFilters = useMemo((): [string, string, string[]][] => {
    if (filters.length === 0) return []
    return filtersToApiFormat(filters)
  }, [filters])

  // Fetch visitor count preview using the API
  const { data: statsData, isLoading, error } = useQuery<TopStatsResponse>({
    queryKey: ['filter-preview-stats', site.domain, apiFilters],
    queryFn: async () => {
      if (filters.length === 0) {
        return { metrics: [] }
      }

      // Serialize filters for API
      const serializedFilters = serializeApiFilters(apiFilters)

      // Call the API with filters as extra query param
      return api.get(url.apiPath(site, '/top-stats'), undefined, { filters: serializedFilters })
    },
    enabled: filters.length > 0,
    staleTime: 30000 // Cache for 30 seconds
  })

  // Get visitor count from the stats response
  const visitorCount = useMemo(() => {
    if (!statsData?.metrics) return null
    const visitorsMetric = statsData.metrics.find(
      (m) => m.graph_metric === 'visitors'
    )
    return visitorsMetric?.value ?? null
  }, [statsData])

  const summary = useMemo(() => getFilterSummary(filters), [filters])
  const hasFilters = filters.length > 0

  return (
    <div className="filter-summary p-3 bg-gray-50 rounded-md border border-gray-200">
      <div className="text-sm font-medium text-gray-700 mb-2">
        Filter Summary
      </div>

      <div className="text-sm text-gray-600 mb-3 whitespace-pre-wrap">
        {summary}
      </div>

      {hasFilters && (
        <div className="flex items-center text-sm">
          <span className="text-gray-500 mr-2">Preview:</span>
          {isLoading ? (
            <span className="text-gray-400">Loading...</span>
          ) : error ? (
            <span className="text-red-500">Error loading count</span>
          ) : visitorCount !== null ? (
            <span className="font-medium text-gray-900">
              {numberShortFormatter(visitorCount)} visitors
            </span>
          ) : (
            <span className="text-gray-400">-</span>
          )}
        </div>
      )}
    </div>
  )
}
