import React from 'react'
import { useTheme, UIMode } from '../../theme-context'
import { RETENTION_THRESHOLDS } from './cohort-theme'

export function CohortLegend() {
  const { mode } = useTheme()

  const highColor = mode === UIMode.dark
    ? 'bg-emerald-900 text-emerald-100'
    : 'bg-emerald-100 text-emerald-800'
  const mediumColor = mode === UIMode.dark
    ? 'bg-yellow-900 text-yellow-100'
    : 'bg-yellow-100 text-yellow-800'
  const lowColor = mode === UIMode.dark
    ? 'bg-red-900 text-red-100'
    : 'bg-red-100 text-red-800'

  const textColor = mode === UIMode.dark ? 'text-gray-300' : 'text-gray-600'

  return (
    <div className={`flex items-center gap-6 mb-4 text-sm ${textColor}`}>
      <span className="font-medium">Retention:</span>
      <div className="flex items-center gap-2">
        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${highColor}`}>
          {Math.round(RETENTION_THRESHOLDS.HIGH * 100)}%+
        </span>
        <span>High</span>
      </div>
      <div className="flex items-center gap-2">
        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${mediumColor}`}>
          {Math.round(RETENTION_THRESHOLDS.LOW * 100)}% - {Math.round(RETENTION_THRESHOLDS.HIGH * 100)}%
        </span>
        <span>Medium</span>
      </div>
      <div className="flex items-center gap-2">
        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${lowColor}`}>
          &lt;{Math.round(RETENTION_THRESHOLDS.LOW * 100)}%
        </span>
        <span>Low</span>
      </div>
      <div className="ml-auto text-xs">
        <span className="opacity-75">Cohorts with &lt;10 users shown as N/A</span>
      </div>
    </div>
  )
}
