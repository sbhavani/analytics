import React, { useState } from 'react'
import { useTheme, UIMode } from '../../theme-context'
import { RETENTION_COLORS, getRetentionLevel } from './cohort-theme'

interface CohortCellProps {
  rate: number
  periodLabel: string
  cohortSize: number
}

export function CohortCell({ rate, periodLabel, cohortSize }: CohortCellProps) {
  const { mode } = useTheme()
  const [showTooltip, setShowTooltip] = useState(false)

  const formattedRate = `${Math.round(rate * 100)}%`
  const retainedUsers = Math.round(rate * cohortSize)

  // Minimum cohort size check for privacy
  if (cohortSize < 10) {
    return (
      <td className="px-2 py-3 text-center text-xs text-gray-400">
        N/A
      </td>
    )
  }

  const level = getRetentionLevel(rate)
  const themeColors = mode === UIMode.dark ? RETENTION_COLORS.dark[level] : RETENTION_COLORS.light[level]
  const bgColor = `${themeColors.bg} ${themeColors.text}`

  return (
    <td
      className="px-2 py-3 text-center relative"
      onMouseEnter={() => setShowTooltip(true)}
      onMouseLeave={() => setShowTooltip(false)}
    >
      <span
        className={`inline-block px-2 py-1 rounded text-xs font-medium ${bgColor} cursor-default`}
      >
        {formattedRate}
      </span>
      {showTooltip && (
        <div className="absolute z-10 bottom-full mb-2 left-1/2 -translate-x-1/2">
          <div className="bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 text-xs rounded py-1 px-2 shadow-lg whitespace-nowrap">
            <div className="font-medium">{periodLabel}</div>
            <div>{retainedUsers.toLocaleString()} of {cohortSize.toLocaleString()} users</div>
            <div>{formattedRate} retention rate</div>
          </div>
        </div>
      )}
    </td>
  )
}
