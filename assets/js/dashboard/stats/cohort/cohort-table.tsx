import React, { useState, useEffect, useCallback } from 'react'
import { getCohorts } from '../../api'
import { Tooltip } from '../../util/tooltip'

interface CohortRetention {
  period_number: number
  retained_count: number
  retention_rate: number
}

interface Cohort {
  id: string
  date: string
  size: number
  retention: CohortRetention[]
}

interface CohortData {
  cohorts: Cohort[]
  meta: {
    period: string
    date_range: {
      from: string
      to: string
    }
  }
}

interface CohortTableProps {
  siteId: string
  domain: string
}

type PeriodOption = 'daily' | 'weekly' | 'monthly'

const PERIOD_LABELS: Record<PeriodOption, string> = {
  daily: 'Daily',
  weekly: 'Weekly',
  monthly: 'Monthly'
}

const PERIOD_TOOLTIP: Record<PeriodOption, string> = {
  daily: 'Users grouped by the day they were first seen',
  weekly: 'Users grouped by the ISO week they were first seen',
  monthly: 'Users grouped by the month they were first seen'
}

export default function CohortTable({ siteId, domain }: CohortTableProps) {
  const [period, setPeriod] = useState<PeriodOption>('monthly')
  const [dateFrom, setDateFrom] = useState<string>('')
  const [dateTo, setDateTo] = useState<string>('')
  const [cohortData, setCohortData] = useState<CohortData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchCohorts = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await getCohorts(domain, {
        period,
        from: dateFrom || undefined,
        to: dateTo || undefined
      })
      setCohortData(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load cohort data')
    } finally {
      setLoading(false)
    }
  }, [domain, period, dateFrom, dateTo])

  useEffect(() => {
    fetchCohorts()
  }, [fetchCohorts])

  const handlePeriodChange = (newPeriod: PeriodOption) => {
    setPeriod(newPeriod)
  }

  const handleDateFromChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setDateFrom(e.target.value)
  }

  const handleDateToChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setDateTo(e.target.value)
  }

  const formatPercentage = (rate: number): string => {
    return `${Math.round(rate * 100)}%`
  }

  const formatCohortDate = (dateStr: string, periodType: string): string => {
    const date = new Date(dateStr)
    if (periodType === 'monthly') {
      return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
    }
    if (periodType === 'weekly') {
      return `W${dateStr.split('-W')[1]} ${date.getFullYear()}`
    }
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  }

  const getMaxPeriods = (): number => {
    if (!cohortData?.cohorts.length) return 6
    const maxRetention = Math.max(
      ...cohortData.cohorts.map((c) => c.retention.length)
    )
    return Math.min(maxRetention, 6)
  }

  const renderRetentionCell = (
    cohort: Cohort,
    periodNum: number
  ): React.ReactNode => {
    const retentionData = cohort.retention.find(
      (r) => r.period_number === periodNum
    )

    if (!retentionData) {
      return <span className="text-gray-400">-</span>
    }

    const { retained_count, retention_rate } = retentionData

    // Edge cases: 100% or 0% retention
    const isFullRetention = retention_rate >= 1.0
    const isZeroRetention = retention_rate <= 0

    let bgColorClass = ''
    if (isFullRetention) {
      bgColorClass = 'bg-green-500'
    } else if (isZeroRetention) {
      bgColorClass = 'bg-red-300'
    } else {
      // Gradient from light to dark green based on retention rate
      const intensity = Math.min(Math.round(retention_rate * 100), 100)
      if (intensity >= 50) {
        bgColorClass = `bg-green-${Math.max(100, 600 - intensity * 5)}`
      } else if (intensity >= 25) {
        bgColorClass = `bg-green-${Math.max(100, 400 - (intensity - 25) * 8)}`
      } else {
        bgColorClass = `bg-green-${100 + (intensity * 4)}`
      }
    }

    return (
      <div
        className={`text-center px-2 py-1 rounded ${bgColorClass} ${
          retention_rate > 0.5 ? 'text-white' : 'text-gray-900'
        }`}
        title={`${retained_count} users (${formatPercentage(retention_rate)})`}
      >
        {formatPercentage(retention_rate)}
      </div>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-red-600">{error}</p>
        <button
          onClick={fetchCohorts}
          className="mt-4 px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
        >
          Retry
        </button>
      </div>
    )
  }

  if (!cohortData) {
    return null
  }

  const maxPeriods = getMaxPeriods()
  const periodType = cohortData.meta.period

  return (
    <div className="cohort-analysis">
      {/* Period Selector */}
      <div className="flex items-center gap-4 mb-6">
        <div className="flex gap-2">
          {(Object.keys(PERIOD_LABELS) as PeriodOption[]).map((periodOption) => (
            <Tooltip key={periodOption} info={PERIOD_TOOLTIP[periodOption]}>
              <button
                onClick={() => handlePeriodChange(periodOption)}
                className={`px-4 py-2 rounded ${
                  period === periodOption
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {PERIOD_LABELS[periodOption]}
              </button>
            </Tooltip>
          ))}
        </div>

        {/* Date Range Picker */}
        <div className="flex items-center gap-2 ml-auto">
          <label className="text-sm text-gray-600">From:</label>
          <input
            type="date"
            value={dateFrom}
            onChange={handleDateFromChange}
            className="px-3 py-1 border border-gray-300 rounded text-sm"
          />
          <label className="text-sm text-gray-600">To:</label>
          <input
            type="date"
            value={dateTo}
            onChange={handleDateToChange}
            className="px-3 py-1 border border-gray-300 rounded text-sm"
          />
        </div>
      </div>

      {/* Cohort Table */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse">
          <thead>
            <tr>
              {/* Cohort Identifier Column */}
              <th className="text-left px-4 py-3 bg-gray-50 border-b border-gray-200 font-semibold">
                <Tooltip info="The time period when users were first acquired">
                  Cohort
                </Tooltip>
              </th>
              {/* Cohort Size Column */}
              <th className="text-right px-4 py-3 bg-gray-50 border-b border-gray-200 font-semibold">
                <Tooltip info="Total number of users in this cohort">
                  Size
                </Tooltip>
              </th>
              {/* Retention Period Columns */}
              {Array.from({ length: maxPeriods }, (_, i) => i + 1).map((periodNum) => {
                const tooltipText =
                  periodType === 'monthly'
                    ? `Users who returned in month ${periodNum} after acquisition`
                    : periodType === 'weekly'
                    ? `Users who returned in week ${periodNum} after acquisition`
                    : `Users who returned ${periodNum} day(s) after acquisition`

                const columnLabel =
                  periodType === 'monthly'
                    ? `Month ${periodNum}`
                    : periodType === 'weekly'
                    ? `Week ${periodNum}`
                    : `Day ${periodNum}`

                return (
                  <th
                    key={periodNum}
                    className="text-center px-4 py-3 bg-gray-50 border-b border-gray-200 font-semibold"
                  >
                    <Tooltip info={tooltipText}>
                      {columnLabel}
                    </Tooltip>
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody>
            {cohortData.cohorts.length === 0 ? (
              <tr>
                <td
                  colSpan={maxPeriods + 2}
                  className="text-center py-8 text-gray-500"
                >
                  No users acquired in the selected period
                </td>
              </tr>
            ) : (
              cohortData.cohorts.map((cohort) => (
                <tr key={cohort.id} className="hover:bg-gray-50">
                  {/* Cohort Identifier */}
                  <td className="px-4 py-3 border-b border-gray-100 font-medium">
                    {formatCohortDate(cohort.date, periodType)}
                  </td>
                  {/* Cohort Size */}
                  <td className="text-right px-4 py-3 border-b border-gray-100">
                    {cohort.size > 0 ? (
                      cohort.size.toLocaleString()
                    ) : (
                      <span className="text-gray-400">No users</span>
                    )}
                  </td>
                  {/* Retention Cells */}
                  {Array.from({ length: maxPeriods }, (_, i) => i + 1).map(
                    (periodNum) => (
                      <td
                        key={periodNum}
                        className="px-1 py-1 border-b border-gray-100"
                      >
                        {renderRetentionCell(cohort, periodNum)}
                      </td>
                    )
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Legend */}
      <div className="mt-4 flex items-center gap-4 text-sm text-gray-600">
        <span>Retention:</span>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 bg-green-100 rounded"></div>
          <span>0-25%</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 bg-green-300 rounded"></div>
          <span>25-50%</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 bg-green-500 rounded"></div>
          <span>50-75%</span>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-4 bg-green-700 rounded"></div>
          <span>75-100%</span>
        </div>
      </div>
    </div>
  )
}
