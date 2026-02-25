import React from 'react'

interface PreviewCountProps {
  count?: number | null
  isLoading?: boolean
  hasError?: boolean
}

export function PreviewCount({ count, isLoading = false, hasError = false }: PreviewCountProps) {
  if (isLoading) {
    return (
      <div className="flex items-center text-sm text-gray-500">
        <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Calculating...
      </div>
    )
  }

  if (hasError) {
    return (
      <div className="text-sm text-gray-500">
        Unable to calculate preview
      </div>
    )
  }

  if (count === null || count === undefined) {
    return null
  }

  const formattedCount = new Intl.NumberFormat().format(count)

  return (
    <div className="text-sm">
      <span className="font-medium text-indigo-600">{formattedCount}</span>
      <span className="text-gray-500"> visitors match</span>
    </div>
  )
}

export default PreviewCount
