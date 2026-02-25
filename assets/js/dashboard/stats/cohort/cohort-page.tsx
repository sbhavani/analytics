import React, { useState } from 'react'
import { CohortTable } from './cohort-table'
import { CohortDateFilter } from './cohort-date-filter'

export function CohortPage() {
  const [cohortPeriods, setCohortPeriods] = useState(12)

  return (
    <div className="cohort-page">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
            Cohort Analysis
          </h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Track user retention over time based on acquisition date
          </p>
        </div>
        <div className="flex items-center gap-4">
          <CohortDateFilter />
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600 dark:text-gray-400">
              Periods:
            </label>
            <select
              className="text-sm border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:bg-gray-800 dark:text-gray-200"
              value={cohortPeriods}
              onChange={(e) => setCohortPeriods(Number(e.target.value))}
            >
              <option value={6}>6 months</option>
              <option value={12}>12 months</option>
              <option value={24}>24 months</option>
            </select>
          </div>
        </div>
      </div>

      <CohortTable cohortPeriods={cohortPeriods} />
    </div>
  )
}
