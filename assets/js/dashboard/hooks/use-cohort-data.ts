import { useQuery } from '@tanstack/react-query'
import * as api from '../api'
import { useSiteContext } from '../site-context'
import { useDashboardStateContext } from '../dashboard-state-context'

export interface CohortRow {
  cohort_date: string
  total_users: number
  retention: number[]
}

export interface CohortTable {
  cohorts: CohortRow[]
  period_labels: string[]
  meta: {
    cohort_periods: number
    date_range: {
      from: string
      to: string
    }
  }
}

export interface UseCohortDataOptions {
  cohortPeriods?: number
  enabled?: boolean
}

export function useCohortData(options: UseCohortDataOptions = {}) {
  const site = useSiteContext()
  const { dashboardState } = useDashboardStateContext()
  const { cohortPeriods = 12, enabled = true } = options

  const queryKey = ['cohorts', site?.domain, dashboardState, cohortPeriods] as const

  return useQuery({
    queryKey,
    queryFn: async () => {
      if (!site?.domain) {
        throw new Error('Site not loaded')
      }

      const queryParams = new URLSearchParams()
      queryParams.set('cohort_periods', String(cohortPeriods))

      // Add date range from dashboard state
      if (dashboardState.from) {
        queryParams.set('from', dashboardState.from.toISOString().split('T')[0])
      }
      if (dashboardState.to) {
        queryParams.set('to', dashboardState.to.toISOString().split('T')[0])
      }

      const url = `/api/stats/${encodeURIComponent(site.domain)}/cohorts?${queryParams.toString()}`

      const response = await api.get(url, dashboardState)
      return response as Promise<CohortTable>
    },
    enabled: enabled && !!site?.domain,
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnWindowFocus: false
  })
}
