import React, { useEffect, useRef, useCallback } from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import { ExclamationTriangleIcon, UserGroupIcon } from '@heroicons/react/24/outline'
import { countConditions, filterTreeToLegacyFilters } from './filterTreeUtils'

export function SegmentPreview() {
  const { state, setPreview } = useFilterBuilder()
  const { preview, filterTree } = state
  const hasConditions = countConditions(filterTree) > 0

  // Ref to track if component is mounted
  const isMountedRef = useRef(true)

  // Fetch preview data with debounce
  const fetchPreview = useCallback(async () => {
    if (!isMountedRef.current) return

    // Set loading state
    setPreview({ visitor_count: null, isLoading: true, hasError: false })

    try {
      // Convert filter tree to legacy filters for API
      const filters = filterTreeToLegacyFilters(filterTree)

      // Build query params
      const params = new URLSearchParams()
      params.set('filters', JSON.stringify(filters))

      // Fetch preview from API
      const response = await fetch(`/api/stats/visitor-count?${params.toString()}`, {
        credentials: 'include'
      })

      if (!response.ok) {
        throw new Error('Failed to fetch preview')
      }

      const data = await response.json()

      if (isMountedRef.current) {
        setPreview({
          visitor_count: data.visitor_count ?? 0,
          isLoading: false,
          hasError: false
        })
      }
    } catch (error) {
      if (isMountedRef.current) {
        setPreview({
          visitor_count: null,
          isLoading: false,
          hasError: true,
          errorMessage: error instanceof Error ? error.message : 'Unknown error'
        })
      }
    }
  }, [filterTree, setPreview])

  // Debounced preview fetch on filter tree changes
  useEffect(() => {
    if (!hasConditions) {
      return
    }

    isMountedRef.current = true

    // Debounce the fetch
    const timeoutId = setTimeout(() => {
      fetchPreview()
    }, 500)

    return () => {
      isMountedRef.current = false
      clearTimeout(timeoutId)
    }
  }, [filterTree, hasConditions, fetchPreview])

  if (!hasConditions) {
    return null
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <UserGroupIcon className="h-5 w-5 text-gray-400" />
          <span className="text-sm font-medium text-gray-700">Preview</span>
        </div>

        {preview.isLoading ? (
          <div className="flex items-center gap-2">
            <div className="animate-spin h-4 w-4 border-2 border-indigo-500 rounded-full border-t-transparent" />
            <span className="text-sm text-gray-500">Calculating...</span>
          </div>
        ) : preview.hasError ? (
          <div className="flex items-center gap-2 text-red-600">
            <ExclamationTriangleIcon className="h-5 w-5" />
            <span className="text-sm">Error loading preview</span>
          </div>
        ) : preview.visitor_count !== null ? (
          <div className="text-sm">
            <span className="font-semibold text-gray-900">
              {preview.visitor_count.toLocaleString()}
            </span>
            <span className="text-gray-500"> visitors</span>
          </div>
        ) : null}
      </div>

      {/* Warning for zero visitors */}
      {preview.visitor_count === 0 && !preview.isLoading && (
        <div className="mt-3 flex items-start gap-2 p-3 bg-yellow-50 rounded-md">
          <ExclamationTriangleIcon className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm font-medium text-yellow-800">
              No visitors match this filter
            </p>
            <p className="text-sm text-yellow-700">
              Try adjusting your conditions to broaden the match criteria.
            </p>
          </div>
        </div>
      )}
    </div>
  )
}

export default SegmentPreview
