import React from 'react'
import { Metric } from '../../../types/query-api'
import { numberShortFormatter } from '../../util/number-formatter'
import { ArrowDownRightIcon, ArrowUpRightIcon } from '@heroicons/react/24/solid'
import classNames from 'classnames'

export function ChangeArrow({
  change,
  metric,
  className,
  hideNumber
}: {
  change: number | null | undefined
  metric: Metric
  className: string
  hideNumber?: boolean
}) {
  // Handle N/A case when change is null or undefined (e.g., zero values)
  if (change === null || change === undefined) {
    if (hideNumber) {
      return null
    }
    return (
      <span className={className} data-testid="change-arrow">
        {' '}
        <span className="text-gray-400">N/A</span>
      </span>
    )
  }

  let icon = null
  const arrowClassName = classNames(
    color(change, metric),
    'mb-0.5 inline-block size-3 stroke-[1px] stroke-current'
  )

  if (change > 0) {
    icon = <ArrowUpRightIcon className={arrowClassName} />
  } else if (change < 0) {
    icon = <ArrowDownRightIcon className={arrowClassName} />
  }

  const formattedChange = hideNumber
    ? null
    : `${icon ? ' ' : ''}${change > 0 ? '+' : ''}${numberShortFormatter(Math.abs(change))}%`

  return (
    <span className={className} data-testid="change-arrow">
      {icon}
      {formattedChange}
    </span>
  )
}

function color(change: number, metric: Metric) {
  const invert = metric === 'bounce_rate'

  return change > 0 != invert ? 'text-green-500' : 'text-red-400'
}
