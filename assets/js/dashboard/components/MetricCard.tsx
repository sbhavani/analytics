import React from 'react'
import classNames from 'classnames'
import { numberShortFormatter } from '../util/number-formatter'

export type MetricComparison = {
  name: string
  displayName: string
  currentValue: number
  comparisonValue: number
  absoluteChange: number
  percentageChange: number
  changeDirection: 'positive' | 'negative' | 'neutral' | 'no_data'
}

export type MetricCardProps = {
  metric: MetricComparison
  onClick?: () => void
}

export function MetricCard({ metric, onClick }: MetricCardProps) {
  const {
    displayName,
    currentValue,
    comparisonValue,
    absoluteChange,
    percentageChange,
    changeDirection
  } = metric

  const renderChangeIndicator = () => {
    switch (changeDirection) {
      case 'positive':
        return (
          <span className="text-green-500 dark:text-green-400 flex items-center">
            <svg
              className="w-3 h-3 mr-0.5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 10l7-7m0 0l7 7m-7-7v18"
              />
            </svg>
            {percentageChange.toFixed(1)}%
          </span>
        )
      case 'negative':
        return (
          <span className="text-red-500 dark:text-red-400 flex items-center">
            <svg
              className="w-3 h-3 mr-0.5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 14l-7 7m0 0l-7-7m7 7V3"
              />
            </svg>
            {Math.abs(percentageChange).toFixed(1)}%
          </span>
        )
      case 'neutral':
        return (
          <span className="text-gray-500 dark:text-gray-400">
            0%
          </span>
        )
      case 'no_data':
        return (
          <span className="text-gray-400 dark:text-gray-500 italic">
            N/A
          </span>
        )
      default:
        return null
    }
  }

  const renderComparisonValue = () => {
    if (comparisonValue === 0 && changeDirection === 'no_data') {
      return <span className="text-gray-400 dark:text-gray-500 italic">No data</span>
    }
    return (
      <span className="text-gray-500 dark:text-gray-400 text-sm">
        vs {numberShortFormatter(comparisonValue)}
      </span>
    )
  }

  const cardClasses = classNames(
    'bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4',
    'hover:shadow-md transition-shadow duration-200',
    onClick && 'cursor-pointer'
  )

  return (
    <div
      className={cardClasses}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
      onKeyDown={onClick ? (e) => e.key === 'Enter' && onClick() : undefined}
    >
      <div className="flex flex-col gap-1">
        <span className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
          {displayName}
        </span>

        <div className="flex items-baseline justify-between">
          <span className="text-2xl font-bold text-gray-900 dark:text-gray-100">
            {numberShortFormatter(currentValue)}
          </span>
          {renderChangeIndicator()}
        </div>

        <div className="flex items-center justify-between mt-1">
          {renderComparisonValue()}
          <span className="text-xs text-gray-400 dark:text-gray-500">
            {absoluteChange >= 0 ? '+' : ''}{numberShortFormatter(absoluteChange)}
          </span>
        </div>
      </div>
    </div>
  )
}
