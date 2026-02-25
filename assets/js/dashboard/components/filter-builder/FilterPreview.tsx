import React, { useState, useEffect } from 'react'
import { useSiteContext } from '../../site-context'
import { useDashboardStateContext } from '../../dashboard-state-context'

export default function FilterPreview() {
  const site = useSiteContext()
  const { dashboardState } = useDashboardStateContext()
  const [count, setCount] = useState<number | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchPreviewCount() {
      setIsLoading(true)
      setError(null)

      try {
        const siteId = site.domain
        const queryParams = new URLSearchParams({
          period: dashboardState.period || '30d',
          filters: JSON.stringify(dashboardState.filters || [])
        })

        const response = await fetch(`/api/stats/${siteId}/visitors?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch preview')
        }

        const data = await response.json()
        setCount(data.results?.[0]?.visitors || 0)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setIsLoading(false)
      }
    }

    // Debounce the fetch
    const timer = setTimeout(() => {
      fetchPreviewCount()
    }, 500)

    return () => clearTimeout(timer)
  }, [site.domain, dashboardState.period, dashboardState.filters])

  if (isLoading) {
    return (
      <div className="text-sm text-gray-500">
        Calculating...
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-sm text-red-500">
        Error: {error}
      </div>
    )
  }

  if (count === null) {
    return (
      <div className="text-sm text-gray-500">
        No preview available
      </div>
    )
  }

  if (count === 0) {
    return (
      <div className="text-sm">
        <span className="text-gray-600">Visitors matching filter: </span>
        <span className="font-medium text-gray-900">0</span>
        <p className="text-xs text-gray-500 mt-1">
          No visitors match your current filter criteria. Try adjusting your conditions.
        </p>
      </div>
    )
  }

  return (
    <div className="text-sm">
      <span className="text-gray-600">Visitors matching filter: </span>
      <span className="font-medium text-gray-900">
        {count.toLocaleString()}
      </span>
    </div>
  )
}
