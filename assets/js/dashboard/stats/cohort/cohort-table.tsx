import React from 'react'
import { useCohortData } from '../../hooks/use-cohort-data'
import { CohortRow } from './cohort-row'
import { CohortLoading } from './cohort-loading'
import { CohortError } from './cohort-error'
import { CohortLegend } from './cohort-legend'

interface CohortTableProps {
  cohortPeriods?: number
}

export function CohortTable({ cohortPeriods = 12 }: CohortTableProps) {
  const { data, isLoading, isError, error } = useCohortData({ cohortPeriods })

  if (isLoading) {
    return <CohortLoading />
  }

  if (isError) {
    return <CohortError error={error} />
  }

  if (!data || !data.cohorts || data.cohorts.length === 0) {
    return (
      <div className="text-gray-500 dark:text-gray-400 text-center py-8">
        No cohort data available for this time period.
      </div>
    )
  }

  return (
    <div className="cohort-table-container">
      <CohortLegend />
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead className="bg-gray-50 dark:bg-gray-800">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Cohort
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                Users
              </th>
              {data.period_labels.map((label, index) => (
                <th
                  key={index}
                  className="px-4 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
                >
                  {label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
            {data.cohorts.map((cohort, rowIndex) => (
              <CohortRow
                key={rowIndex}
                cohort={cohort}
                periodLabels={data.period_labels}
              />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
