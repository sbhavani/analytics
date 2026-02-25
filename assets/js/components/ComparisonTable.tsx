import React from 'react'
import classNames from 'classnames'
import { numberShortFormatter, percentageFormatter } from '../dashboard/util/number-formatter'
import {
  ArrowUpRightIcon,
  ArrowDownRightIcon,
  MinusIcon,
  ExclamationCircleIcon
} from '@heroicons/react/24/solid'

export interface MetricComparison {
  name: string
  displayName: string
  currentValue: number
  comparisonValue: number
  absoluteChange: number
  percentageChange: number
  changeDirection: 'positive' | 'negative' | 'neutral' | 'no_data'
}

interface ComparisonTableProps {
  metrics: MetricComparison[]
  loading?: boolean
  onMetricClick?: (metricName: string) => void
}

export function ComparisonTable({
  metrics,
  loading = false,
  onMetricClick
}: ComparisonTableProps) {
  if (loading) {
    return (
      <div className="w-full animate-pulse">
        <div className="bg-gray-100 dark:bg-gray-800 h-12 rounded mb-2"></div>
        <div className="bg-gray-100 dark:bg-gray-800 h-12 rounded mb-2"></div>
        <div className="bg-gray-100 dark:bg-gray-800 h-12 rounded mb-2"></div>
      </div>
    )
  }

  if (metrics.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500 dark:text-gray-400">
        <ExclamationCircleIcon className="w-8 h-8 mx-auto mb-2" />
        <p>No comparison data available</p>
      </div>
    )
  }

  return (
    <table className="w-full">
      <thead>
        <tr className="text-xs font-semibold text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
          <th className="text-left py-3 px-4">Metric</th>
          <th className="text-right py-3 px-4">Current Period</th>
          <th className="text-right py-3 px-4">Previous Period</th>
          <th className="text-right py-3 px-4">Change</th>
          <th className="text-right py-3 px-4">% Change</th>
        </tr>
      </thead>
      <tbody>
        {metrics.map((metric) => (
          <ComparisonRow
            key={metric.name}
            metric={metric}
            onClick={onMetricClick}
          />
        ))}
      </tbody>
    </table>
  )
}

function ComparisonRow({
  metric,
  onClick
}: {
  metric: MetricComparison
  onClick?: (metricName: string) => void
}) {
  const handleClick = () => {
    if (onClick) {
      onClick(metric.name)
    }
  }

  const changeClassName = classNames(
    'inline-flex items-center gap-1 font-medium',
    {
      'text-green-500 dark:text-green-400': metric.changeDirection === 'positive',
      'text-red-500 dark:text-red-400': metric.changeDirection === 'negative',
      'text-gray-500 dark:text-gray-400': metric.changeDirection === 'neutral',
      'text-gray-400 dark:text-gray-500': metric.changeDirection === 'no_data'
    }
  )

  const rowClassName = classNames(
    'border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors',
    { 'cursor-pointer': !!onClick }
  )

  const ChangeIcon = () => {
    switch (metric.changeDirection) {
      case 'positive':
        return <ArrowUpRightIcon className="w-4 h-4" />
      case 'negative':
        return <ArrowDownRightIcon className="w-4 h-4" />
      case 'neutral':
        return <MinusIcon className="w-4 h-4" />
      case 'no_data':
        return <MinusIcon className="w-4 h-4" />
    }
  }

  return (
    <tr
      className={rowClassName}
      onClick={handleClick}
    >
      <td className="py-3 px-4 text-sm font-medium text-gray-900 dark:text-gray-100">
        {metric.displayName}
      </td>
      <td className="py-3 px-4 text-sm text-right text-gray-700 dark:text-gray-300">
        {numberShortFormatter(metric.currentValue)}
      </td>
      <td className="py-3 px-4 text-sm text-right text-gray-700 dark:text-gray-300">
        {numberShortFormatter(metric.comparisonValue)}
      </td>
      <td className="py-3 px-4 text-sm text-right">
        <span className={changeClassName}>
          <ChangeIcon />
          {metric.changeDirection !== 'no_data'
            ? numberShortFormatter(Math.abs(metric.absoluteChange))
            : '—'}
        </span>
      </td>
      <td className="py-3 px-4 text-sm text-right">
        {metric.changeDirection !== 'no_data' ? (
          <span className={changeClassName}>
            {metric.changeDirection === 'positive' ? '+' : ''}
            {percentageFormatter(metric.percentageChange)}
          </span>
        ) : (
          <span className="text-gray-400 dark:text-gray-500">—</span>
        )}
      </td>
    </tr>
  )
}
