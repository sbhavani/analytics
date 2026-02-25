import React from 'react'

export function CohortLoading() {
  return (
    <div className="flex items-center justify-center py-12">
      <div className="flex flex-col items-center gap-3">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
        <span className="text-gray-500 dark:text-gray-400 text-sm">
          Loading cohort data...
        </span>
      </div>
    </div>
  )
}
