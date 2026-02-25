import React, { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { get } from '../dashboard/api'

// Types from API contract
export interface DateRange {
  startDate: Date
  endDate: Date
}

export interface PeriodSelection {
  mode: 'predefined' | 'custom'
  predefinedPairId?: string
  customCurrentPeriod?: DateRange
  customComparisonPeriod?: DateRange
}

export interface PeriodPair {
  id: string
  name: string
  current_period_type: string
  comparison_period_type: string
}

export interface PeriodSelectorProps {
  siteId: string
  onPeriodChange: (period: PeriodSelection) => void
  selectedPair?: string
  selectedCurrentPeriod?: DateRange
  selectedComparisonPeriod?: DateRange
}

// Fetch predefined period pairs from API
async function fetchPeriodPairs(siteId: string): Promise<PeriodPair[]> {
  const response = await get(
    `/api/v1/sites/${siteId}/analytics/period-pairs`,
    undefined
  )
  return response.data
}

export function PeriodSelector({
  siteId,
  onPeriodChange,
  selectedPair,
  selectedCurrentPeriod,
  selectedComparisonPeriod
}: PeriodSelectorProps) {
  const [mode, setMode] = useState<'predefined' | 'custom'>(
    selectedPair ? 'predefined' : 'custom'
  )
  const [selectedPredefinedPair, setSelectedPredefinedPair] = useState<
    string | undefined
  >(selectedPair)
  const [currentStart, setCurrentStart] = useState<string>('')
  const [currentEnd, setCurrentEnd] = useState<string>('')
  const [comparisonStart, setComparisonStart] = useState<string>('')
  const [comparisonEnd, setComparisonEnd] = useState<string>('')

  // Fetch predefined period pairs
  const { data: periodPairs, isLoading } = useQuery({
    queryKey: ['period-pairs', siteId],
    queryFn: () => fetchPeriodPairs(siteId),
    staleTime: 5 * 60 * 1000 // 5 minutes
  })

  // Initialize custom date fields from props
  useEffect(() => {
    if (selectedCurrentPeriod) {
      setCurrentStart(formatDateForInput(selectedCurrentPeriod.startDate))
      setCurrentEnd(formatDateForInput(selectedCurrentPeriod.endDate))
    }
    if (selectedComparisonPeriod) {
      setComparisonStart(formatDateForInput(selectedComparisonPeriod.startDate))
      setComparisonEnd(formatDateForInput(selectedComparisonPeriod.endDate))
    }
  }, [selectedCurrentPeriod, selectedComparisonPeriod])

  // Format date to YYYY-MM-DD for input
  function formatDateForInput(date: Date): string {
    return date.toISOString().split('T')[0]
  }

  // Handle predefined pair selection
  function handlePredefinedPairChange(pairId: string) {
    setSelectedPredefinedPair(pairId)
    onPeriodChange({
      mode: 'predefined',
      predefinedPairId: pairId
    })
  }

  // Handle custom date changes
  function handleCustomDateChange() {
    if (currentStart && currentEnd && comparisonStart && comparisonEnd) {
      onPeriodChange({
        mode: 'custom',
        customCurrentPeriod: {
          startDate: new Date(currentStart),
          endDate: new Date(currentEnd)
        },
        customComparisonPeriod: {
          startDate: new Date(comparisonStart),
          endDate: new Date(comparisonEnd)
        }
      })
    }
  }

  // Handle mode toggle
  function handleModeChange(newMode: 'predefined' | 'custom') {
    setMode(newMode)
    if (newMode === 'predefined' && periodPairs && periodPairs.length > 0) {
      const firstPair = periodPairs[0].id
      setSelectedPredefinedPair(firstPair)
      onPeriodChange({
        mode: 'predefined',
        predefinedPairId: firstPair
      })
    }
  }

  return (
    <div className="flex flex-col gap-4 p-4 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
      {/* Mode Toggle */}
      <div className="flex gap-2">
        <button
          type="button"
          onClick={() => handleModeChange('predefined')}
          className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
            mode === 'predefined'
              ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300'
              : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700'
          }`}
        >
          Predefined Pairs
        </button>
        <button
          type="button"
          onClick={() => handleModeChange('custom')}
          className={`px-3 py-1.5 text-sm font-medium rounded-md transition-colors ${
            mode === 'custom'
              ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900 dark:text-indigo-300'
              : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700'
          }`}
        >
          Custom Range
        </button>
      </div>

      {/* Predefined Pairs Mode */}
      {mode === 'predefined' && (
        <div>
          {isLoading ? (
            <div className="text-sm text-gray-500 dark:text-gray-400">
              Loading period pairs...
            </div>
          ) : periodPairs && periodPairs.length > 0 ? (
            <select
              value={selectedPredefinedPair || ''}
              onChange={(e) => handlePredefinedPairChange(e.target.value)}
              className="w-full px-3 py-2 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:text-gray-100"
            >
              {periodPairs.map((pair) => (
                <option key={pair.id} value={pair.id}>
                  {pair.name}
                </option>
              ))}
            </select>
          ) : (
            <div className="text-sm text-gray-500 dark:text-gray-400">
              No predefined pairs available
            </div>
          )}
        </div>
      )}

      {/* Custom Range Mode */}
      {mode === 'custom' && (
        <div className="grid grid-cols-2 gap-4">
          {/* Current Period */}
          <div className="space-y-2">
            <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300">
              Current Period
            </h4>
            <div className="space-y-2">
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400">
                  Start Date
                </label>
                <input
                  type="date"
                  value={currentStart}
                  onChange={(e) => {
                    setCurrentStart(e.target.value)
                    // Debounce the callback
                    setTimeout(handleCustomDateChange, 300)
                  }}
                  className="w-full px-2 py-1.5 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400">
                  End Date
                </label>
                <input
                  type="date"
                  value={currentEnd}
                  onChange={(e) => {
                    setCurrentEnd(e.target.value)
                    setTimeout(handleCustomDateChange, 300)
                  }}
                  className="w-full px-2 py-1.5 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:text-gray-100"
                />
              </div>
            </div>
          </div>

          {/* Comparison Period */}
          <div className="space-y-2">
            <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300">
              Comparison Period
            </h4>
            <div className="space-y-2">
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400">
                  Start Date
                </label>
                <input
                  type="date"
                  value={comparisonStart}
                  onChange={(e) => {
                    setComparisonStart(e.target.value)
                    setTimeout(handleCustomDateChange, 300)
                  }}
                  className="w-full px-2 py-1.5 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:text-gray-100"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 dark:text-gray-400">
                  End Date
                </label>
                <input
                  type="date"
                  value={comparisonEnd}
                  onChange={(e) => {
                    setComparisonEnd(e.target.value)
                    setTimeout(handleCustomDateChange, 300)
                  }}
                  className="w-full px-2 py-1.5 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:text-gray-100"
                />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default PeriodSelector
