import React from 'react'
import classNames from 'classnames'
import dayjs from 'dayjs'
import { formatISO, shiftDays, shiftMonths } from '../util/date'

export type PeriodOption = {
  id: string
  label: string
  primaryPeriod: { from: string; to: string }
  comparisonPeriod: { from: string; to: string }
}

export type SelectedPeriod = {
  primary: { from: string; to: string }
  comparison: { from: string; to: string }
}

type PeriodPickerProps = {
  selectedPeriodId?: string
  onSelect: (period: SelectedPeriod) => void
  site?: { offset: number }
  className?: string
}

function getWeekDates(siteOffset: number = 0): {
  primary: { from: string; to: string }
  comparison: { from: string; to: string }
} {
  const now = dayjs().utcOffset(siteOffset / 60)
  const startOfWeek = now.startOf('week')
  const endOfWeek = now.endOf('week')

  // This week
  const primary = {
    from: formatISO(startOfWeek),
    to: formatISO(endOfWeek)
  }

  // Last week
  const comparison = {
    from: formatISO(shiftDays(startOfWeek, -7)),
    to: formatISO(shiftDays(endOfWeek, -7))
  }

  return { primary, comparison }
}

function getMonthDates(siteOffset: number = 0): {
  primary: { from: string; to: string }
  comparison: { from: string; to: string }
} {
  const now = dayjs().utcOffset(siteOffset / 60)
  const startOfMonth = now.startOf('month')
  const endOfMonth = now.endOf('month')

  // This month
  const primary = {
    from: formatISO(startOfMonth),
    to: formatISO(endOfMonth)
  }

  // Last month
  const comparison = {
    from: formatISO(shiftMonths(startOfMonth, -1)),
    to: formatISO(shiftMonths(endOfMonth, -1))
  }

  return { primary, comparison }
}

function getQuarterDates(siteOffset: number = 0): {
  primary: { from: string; to: string }
  comparison: { from: string; to: string }
} {
  const now = dayjs().utcOffset(siteOffset / 60)
  const startOfQuarter = now.startOf('quarter')
  const endOfQuarter = now.endOf('quarter')

  // This quarter
  const primary = {
    from: formatISO(startOfQuarter),
    to: formatISO(endOfQuarter)
  }

  // Last quarter
  const comparison = {
    from: formatISO(shiftMonths(startOfQuarter, -3)),
    to: formatISO(shiftMonths(endOfQuarter, -3))
  }

  return { primary, comparison }
}

function getYearDates(siteOffset: number = 0): {
  primary: { from: string; to: string }
  comparison: { from: string; to: string }
} {
  const now = dayjs().utcOffset(siteOffset / 60)
  const startOfYear = now.startOf('year')
  const endOfYear = now.endOf('year')

  // This year
  const primary = {
    from: formatISO(startOfYear),
    to: formatISO(endOfYear)
  }

  // Last year (12 months ago)
  const comparison = {
    from: formatISO(shiftMonths(startOfYear, -12)),
    to: formatISO(shiftMonths(endOfYear, -12))
  }

  return { primary, comparison }
}

export const PREDEFINED_PERIODS: PeriodOption[] = [
  {
    id: 'this_week_last_week',
    label: 'This Week vs Last Week',
    ...getWeekDates()
  },
  {
    id: 'this_month_last_month',
    label: 'This Month vs Last Month',
    ...getMonthDates()
  },
  {
    id: 'this_quarter_last_quarter',
    label: 'This Quarter vs Last Quarter',
    ...getQuarterDates()
  },
  {
    id: 'this_year_last_year',
    label: 'This Year vs Last Year',
    ...getYearDates()
  }
]

export function PeriodPicker({
  selectedPeriodId,
  onSelect,
  site,
  className
}: PeriodPickerProps) {
  const siteOffset = site?.offset ?? 0

  const handleSelect = (period: PeriodOption) => {
    // Recalculate dates with the site's timezone offset
    let periodWithOffset: SelectedPeriod

    switch (period.id) {
      case 'this_week_last_week': {
        const dates = getWeekDates(siteOffset)
        periodWithOffset = dates
        break
      }
      case 'this_month_last_month': {
        const dates = getMonthDates(siteOffset)
        periodWithOffset = dates
        break
      }
      case 'this_quarter_last_quarter': {
        const dates = getQuarterDates(siteOffset)
        periodWithOffset = dates
        break
      }
      case 'this_year_last_year': {
        const dates = getYearDates(siteOffset)
        periodWithOffset = dates
        break
      }
      default:
        periodWithOffset = {
          primary: period.primaryPeriod,
          comparison: period.comparisonPeriod
        }
    }

    onSelect(periodWithOffset)
  }

  return (
    <div className={classNames('flex flex-col gap-1', className)}>
      <span className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">
        Compare to
      </span>
      <div className="flex flex-wrap gap-2">
        {PREDEFINED_PERIODS.map((period) => (
          <button
            key={period.id}
            onClick={() => handleSelect(period)}
            className={classNames(
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              'border focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-1',
              selectedPeriodId === period.id
                ? 'bg-indigo-50 dark:bg-indigo-900/30 border-indigo-300 dark:border-indigo-700 text-indigo-700 dark:text-indigo-300'
                : 'bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
            )}
          >
            {period.label}
          </button>
        ))}
      </div>
    </div>
  )
}
