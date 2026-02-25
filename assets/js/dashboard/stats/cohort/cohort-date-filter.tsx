import React from 'react'
import { useDashboardStateContext } from '../../dashboard-state-context'

interface CohortDateFilterProps {
  onChange?: (from: Date | undefined, to: Date | undefined) => void
}

const DATE_RANGE_OPTIONS = [
  { label: 'Last 3 months', months: 3 },
  { label: 'Last 6 months', months: 6 },
  { label: 'Last 12 months', months: 12 },
  { label: 'Last 24 months', months: 24 },
]

export function CohortDateFilter({ onChange }: CohortDateFilterProps) {
  const { dashboardState, setDashboardState } = useDashboardStateContext()

  const handlePeriodChange = (months: number) => {
    const to = new Date()
    const from = new Date()
    from.setMonth(from.getMonth() - months)

    setDashboardState((prev) => ({
      ...prev,
      from,
      to,
    }))

    onChange?.(from, to)
  }

  const currentMonths = dashboardState.from && dashboardState.to
    ? Math.round((dashboardState.to.getTime() - dashboardState.from.getTime()) / (30 * 24 * 60 * 60 * 1000))
    : 12

  return (
    <div className="flex items-center gap-2">
      <label className="text-sm text-gray-600 dark:text-gray-400">
        Time range:
      </label>
      <select
        className="text-sm border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800 dark:text-gray-200"
        value={currentMonths}
        onChange={(e) => handlePeriodChange(Number(e.target.value))}
      >
        {DATE_RANGE_OPTIONS.map((option) => (
          <option key={option.months} value={option.months}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  )
}
