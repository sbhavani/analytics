import React from 'react'
import { CohortCell } from './cohort-cell'
import { CohortRow as CohortRowType } from '../../hooks/use-cohort-data'

interface CohortRowProps {
  cohort: CohortRowType
  periodLabels: string[]
}

export function CohortRow({ cohort, periodLabels }: CohortRowProps) {
  const cohortDate = new Date(cohort.cohort_date)
  const formattedDate = cohortDate.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short'
  })

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800">
      <td className="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-gray-100">
        {formattedDate}
      </td>
      <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600 dark:text-gray-400">
        {cohort.total_users.toLocaleString()}
      </td>
      {cohort.retention.map((rate, index) => (
        <CohortCell
          key={index}
          rate={rate}
          periodLabel={periodLabels[index]}
          cohortSize={cohort.total_users}
        />
      ))}
    </tr>
  )
}
