import React from 'react'
import { PreviewResult } from '../lib/filterBuilder/usePreview'

interface PreviewPanelProps {
  result: PreviewResult | null
  loading: boolean
  error: string | null
}

export function PreviewPanel({ result, loading, error }: PreviewPanelProps) {
  if (loading) {
    return (
      <div className="flex items-center justify-center p-4 bg-gray-50 rounded-lg dark:bg-gray-800">
        <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
          <svg
            className="w-5 h-5 animate-spin"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          <span className="text-sm">Calculating...</span>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded-lg dark:bg-red-900/20 dark:border-red-800">
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      </div>
    )
  }

  if (!result) {
    return (
      <div className="p-4 bg-gray-50 rounded-lg dark:bg-gray-800">
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Add conditions to see matching visitor count
        </p>
      </div>
    )
  }

  const { matchingVisitors, totalVisitors, percentage } = result

  if (matchingVisitors === 0) {
    return (
      <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg dark:bg-amber-900/20 dark:border-amber-800">
        <p className="text-sm text-amber-700 dark:text-amber-400">
          No visitors match your current filter criteria. Try relaxing some conditions.
        </p>
        <div className="mt-2 text-xs text-amber-600 dark:text-amber-500">
          Total visitors: {totalVisitors.toLocaleString()}
        </div>
      </div>
    )
  }

  return (
    <div className="p-4 bg-green-50 border border-green-200 rounded-lg dark:bg-green-900/20 dark:border-green-800">
      <div className="flex items-baseline gap-2">
        <span className="text-2xl font-bold text-green-700 dark:text-green-400">
          {matchingVisitors.toLocaleString()}
        </span>
        <span className="text-sm text-green-600 dark:text-green-500">
          visitors match your filter
        </span>
      </div>

      <div className="mt-2 text-xs text-green-600 dark:text-green-500">
        {percentage.toFixed(1)}% of {totalVisitors.toLocaleString()} total visitors
      </div>

      <div className="mt-3 w-full bg-green-200 rounded-full h-2 dark:bg-green-800">
        <div
          className="bg-green-500 h-2 rounded-full transition-all duration-300"
          style={{ width: `${Math.min(percentage, 100)}%` }}
        />
      </div>
    </div>
  )
}
