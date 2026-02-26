import React from 'react'

interface VisitorCountDisplayProps {
  count: number
  loading: boolean
  error: string | null
}

export function VisitorCountDisplay({
  count,
  loading,
  error
}: VisitorCountDisplayProps) {
  if (error) {
    return (
      <div className="flex items-center gap-2 text-sm text-red-600">
        <svg
          className="w-4 h-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <span>{error}</span>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <svg
          className="w-4 h-4 animate-spin"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
          />
        </svg>
        <span>Calculating...</span>
      </div>
    )
  }

  // Handle edge case: 0 visitors match filter
  if (count === 0 && !loading && !error) {
    return (
      <div className="flex items-center gap-2">
        <span className="text-sm text-gray-600">Matching visitors:</span>
        <span className="text-lg font-semibold text-gray-900">
          0
        </span>
        <span className="text-sm text-amber-600">
          (no visitors match this filter)
        </span>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-2">
      <span className="text-sm text-gray-600">Matching visitors:</span>
      <span className="text-lg font-semibold text-gray-900">
        {count.toLocaleString()}
      </span>
    </div>
  )
}
