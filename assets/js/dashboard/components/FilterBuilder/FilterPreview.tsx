import React, { useState, useEffect, useCallback, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import classNames from 'classnames'
import { FilterTree, filterTreeToDashboardFilters } from '../../lib/filter-parser'
import * as api from '../../api'

interface FilterPreviewProps {
  filterTree: FilterTree
  siteId: string
  loading?: boolean
}

// Create a stable query key based on filter tree
function createFilterKey(filterTree: FilterTree, siteId: string): string {
  // Use a simplified representation of the filter tree for caching
  const conditions = filterTree.rootGroup.conditions.map(c =>
    `${c.dimension}:${c.operator}:${c.value.join(',')}`
  ).join('|')

  const children = filterTree.rootGroup.children.map(child => {
    return child.conditions.map(c =>
      `${c.dimension}:${c.operator}:${c.value.join(',')}`
    ).join('|')
  }).join('||')

  return `filter-preview:${siteId}:${conditions}:${children}`
}

// Fetch preview data
async function fetchPreviewCount(
  filterTree: FilterTree,
  siteId: string
): Promise<number> {
  const hasConditions = filterTree.rootGroup.conditions.length > 0 ||
    filterTree.rootGroup.children.some(c => c.conditions.length > 0)

  if (!hasConditions) {
    return 0
  }

  const filters = filterTreeToDashboardFilters(filterTree)
  const response = await api.getStats(
    siteId,
    { filters, metrics: ['visitors'] },
    'aggregate'
  )

  return response?.visitors?.[0]?.value || 0
}

export const FilterPreview: React.FC<FilterPreviewProps> = ({
  filterTree,
  siteId,
  loading: externalLoading = false
}) => {
  const [debouncedTree, setDebouncedTree] = useState(filterTree)

  // Debounce the filter tree changes to reduce API calls
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedTree(filterTree)
    }, 300) // 300ms debounce for API calls

    return () => clearTimeout(timer)
  }, [filterTree])

  // Create stable query key
  const queryKey = useMemo(() => {
    return ['filter-preview', siteId, debouncedTree]
  }, [siteId, debouncedTree])

  // Use TanStack Query for caching and background refetching
  const { data: visitors = 0, isLoading, isError, error } = useQuery({
    queryKey,
    queryFn: () => fetchPreviewCount(debouncedTree, siteId),
    // Cache the result for 5 minutes to avoid redundant API calls
    staleTime: 5 * 60 * 1000,
    // Keep previous data while fetching new data (smoother UX)
    placeholderData: (previousData) => previousData,
    // Don't refetch on window focus for this preview - it's expensive
    refetchOnWindowFocus: false,
    // Disable the query if there are no conditions
    enabled: debouncedTree.rootGroup.conditions.length > 0 ||
      debouncedTree.rootGroup.children.some(c => c.conditions.length > 0)
  })

  const isLoadingState = isLoading || externalLoading

  return (
    <div className="flex items-center gap-2">
      <span className="text-sm text-gray-500 dark:text-gray-400">
        Matching visitors:
      </span>
      <span className={classNames(
        'text-sm font-semibold',
        isLoadingState ? 'text-gray-400' : 'text-gray-900 dark:text-gray-100'
      )}>
        {isLoadingState ? (
          <span className="inline-flex items-center gap-1">
            <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            Loading...
          </span>
        ) : isError ? (
          <span className="text-red-500">Error loading preview</span>
        ) : (
          formatNumber(visitors)
        )}
      </span>
    </div>
  )
}

function formatNumber(num: number): string {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toLocaleString()
}

export default FilterPreview
