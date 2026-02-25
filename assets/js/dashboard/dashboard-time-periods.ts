import { useEffect } from 'react'
import {
  clearedComparisonSearch,
  clearedDateSearch,
  DashboardState
} from './dashboard-state'
import { PlausibleSite } from './site-context'
import {
  formatDateRange,
  formatDay,
  formatISO,
  formatMonthYYYY,
  formatYear,
  isSameDate,
  isSameMonth,
  isThisMonth,
  isThisYear,
  isToday,
  isTodayOrYesterday,
  lastMonth,
  nowForSite,
  parseNaiveDate,
  shiftDays,
  shiftMonths,
  yesterday
} from './util/date'
import { AppNavigationTarget } from './navigation/use-app-navigate'
import { getDomainScopedStorageKey, getItem, setItem } from './util/storage'

export enum DashboardPeriod {
  'realtime' = 'realtime',
  'day' = 'day',
  'month' = 'month',
  '7d' = '7d',
  '24h' = '24h',
  '28d' = '28d',
  '30d' = '30d',
  '91d' = '91d',
  '6mo' = '6mo',
  '12mo' = '12mo',
  'year' = 'year',
  'all' = 'all',
  'custom' = 'custom'
}

export enum ComparisonMode {
  off = 'off',
  previous_period = 'previous_period',
  year_over_year = 'year_over_year',
  custom = 'custom',
  // Predefined period comparison options
  this_week_vs_last_week = 'this_week_vs_last_week',
  this_month_vs_last_month = 'this_month_vs_last_month',
  last_7_days_vs_previous_7_days = 'last_7_days_vs_previous_7_days'
}

export const COMPARISON_MODES = {
  [ComparisonMode.off]: 'Disable comparison',
  [ComparisonMode.previous_period]: 'Previous period',
  [ComparisonMode.year_over_year]: 'Year over year',
  [ComparisonMode.custom]: 'Custom period',
  [ComparisonMode.this_week_vs_last_week]: 'This week vs last week',
  [ComparisonMode.this_month_vs_last_month]: 'This month vs last month',
  [ComparisonMode.last_7_days_vs_previous_7_days]: 'Last 7 days vs previous 7 days'
}

export enum ComparisonMatchMode {
  MatchExactDate = 0,
  MatchDayOfWeek = 1
}

export const COMPARISON_MATCH_MODE_LABELS = {
  [ComparisonMatchMode.MatchDayOfWeek]: 'Match day of week',
  [ComparisonMatchMode.MatchExactDate]: 'Match exact date'
}

export const DEFAULT_COMPARISON_MODE = ComparisonMode.previous_period

const COMPARISON_DISABLED_PERIODS = [
  DashboardPeriod.realtime,
  DashboardPeriod.all
]

export const isComparisonForbidden = ({
  period,
  segmentIsExpanded
}: {
  period: DashboardPeriod
  segmentIsExpanded: boolean
}) => COMPARISON_DISABLED_PERIODS.includes(period) || segmentIsExpanded

export const DEFAULT_COMPARISON_MATCH_MODE = ComparisonMatchMode.MatchDayOfWeek

export function getPeriodStorageKey(domain: string): string {
  return getDomainScopedStorageKey('period', domain)
}

export function isValidPeriod(period: unknown): period is DashboardPeriod {
  return Object.values<unknown>(DashboardPeriod).includes(period)
}

export function getStoredPeriod(
  domain: string,
  fallbackValue: DashboardPeriod | null
) {
  const item = getItem(getPeriodStorageKey(domain))
  return isValidPeriod(item) ? item : fallbackValue
}

function storePeriod(domain: string, value: DashboardPeriod) {
  return setItem(getPeriodStorageKey(domain), value)
}

export const isValidComparison = (
  comparison: unknown
): comparison is ComparisonMode =>
  Object.values<unknown>(ComparisonMode).includes(comparison)

export const getMatchDayOfWeekStorageKey = (domain: string) =>
  getDomainScopedStorageKey('comparison_match_day_of_week', domain)

export const isValidMatchDayOfWeek = (
  matchDayOfWeek: unknown
): matchDayOfWeek is boolean =>
  [true, false].includes(matchDayOfWeek as boolean)

export const storeMatchDayOfWeek = (domain: string, matchDayOfWeek: boolean) =>
  setItem(getMatchDayOfWeekStorageKey(domain), matchDayOfWeek.toString())

export const getStoredMatchDayOfWeek = function (
  domain: string,
  fallbackValue: boolean | null
) {
  const storedValue = getItem(getMatchDayOfWeekStorageKey(domain))
  if (storedValue === 'true') {
    return true
  }
  if (storedValue === 'false') {
    return false
  }
  return fallbackValue
}

export const getComparisonModeStorageKey = (domain: string) =>
  getDomainScopedStorageKey('comparison_mode', domain)

export const getStoredComparisonMode = function (
  domain: string,
  fallbackValue: ComparisonMode | null
): ComparisonMode | null {
  const storedValue = getItem(getComparisonModeStorageKey(domain))
  if (Object.values(ComparisonMode).includes(storedValue)) {
    return storedValue
  }

  return fallbackValue
}

export const storeComparisonMode = function (
  domain: string,
  mode: ComparisonMode
) {
  setItem(getComparisonModeStorageKey(domain), mode)
}

export const isComparisonEnabled = function (
  mode?: ComparisonMode | null
): mode is Exclude<ComparisonMode, ComparisonMode.off> {
  if (
    [
      ComparisonMode.custom,
      ComparisonMode.previous_period,
      ComparisonMode.year_over_year,
      ComparisonMode.this_week_vs_last_week,
      ComparisonMode.this_month_vs_last_month,
      ComparisonMode.last_7_days_vs_previous_7_days
    ].includes(mode as ComparisonMode)
  ) {
    return true
  }
  return false
}

export const getSearchToToggleComparison = ({
  site,
  dashboardState
}: {
  site: PlausibleSite
  dashboardState: DashboardState
}): Required<AppNavigationTarget>['search'] => {
  return (search) => {
    if (isComparisonEnabled(dashboardState.comparison)) {
      return {
        ...search,
        ...clearedComparisonSearch,
        comparison: ComparisonMode.off,
        keybindHint: 'X'
      }
    }
    const storedMode = getStoredComparisonMode(site.domain, null)
    const newMode = isComparisonEnabled(storedMode)
      ? storedMode
      : DEFAULT_COMPARISON_MODE
    return {
      ...search,
      ...clearedComparisonSearch,
      comparison: newMode,
      keybindHint: 'X'
    }
  }
}

export const getSearchToApplyCustomDates = ([selectionStart, selectionEnd]: [
  Date,
  Date
]): AppNavigationTarget['search'] => {
  const [from, to] = [
    parseNaiveDate(selectionStart),
    parseNaiveDate(selectionEnd)
  ]
  const singleDaySelected = from.isSame(to, 'day')

  if (singleDaySelected) {
    return (search) => ({
      ...search,
      ...clearedDateSearch,
      period: DashboardPeriod.day,
      date: formatISO(from),
      keybindHint: 'C'
    })
  }

  return (search) => ({
    ...search,
    ...clearedDateSearch,
    period: DashboardPeriod.custom,
    from: formatISO(from),
    to: formatISO(to),
    keybindHint: 'C'
  })
}

export const getSearchToApplyCustomComparisonDates = ([
  selectionStart,
  selectionEnd
]: [Date, Date]): AppNavigationTarget['search'] => {
  const [from, to] = [
    parseNaiveDate(selectionStart),
    parseNaiveDate(selectionEnd)
  ]

  return (search) => ({
    ...search,
    comparison: ComparisonMode.custom,
    compare_from: formatISO(from),
    compare_to: formatISO(to),
    keybindHint: null
  })
}

// Helper to get start of week (Monday) for a Dayjs date
function getStartOfWeek(date: ReturnType<typeof nowForSite>): ReturnType<typeof nowForSite> {
  return date.startOf('week')
}

// Helper to get end of week (Sunday) for a Dayjs date
function getEndOfWeek(date: ReturnType<typeof nowForSite>): ReturnType<typeof nowForSite> {
  return date.endOf('week')
}

// Helper to get start of month for a Dayjs date
function getStartOfMonth(date: ReturnType<typeof nowForSite>): ReturnType<typeof nowForSite> {
  return date.startOf('month')
}

// Helper to get end of month for a Dayjs date
function getEndOfMonth(date: ReturnType<typeof nowForSite>): ReturnType<typeof nowForSite> {
  return date.endOf('month')
}

// Helper to apply "This Week vs Last Week" predefined comparison
export const getSearchToApplyThisWeekVsLastWeek = (site: PlausibleSite) => {
  const today = nowForSite(site)
  const thisWeekStart = getStartOfWeek(today)
  const thisWeekEnd = getEndOfWeek(today)
  const lastWeekStart = shiftDays(thisWeekStart, -7)
  const lastWeekEnd = shiftDays(thisWeekEnd, -7)

  return (search: Record<string, unknown>) => ({
    ...search,
    ...clearedDateSearch,
    period: DashboardPeriod.custom,
    from: formatISO(thisWeekStart),
    to: formatISO(thisWeekEnd),
    comparison: ComparisonMode.this_week_vs_last_week,
    compare_from: formatISO(lastWeekStart),
    compare_to: formatISO(lastWeekEnd),
    keybindHint: null
  })
}

// Helper to apply "This Month vs Last Month" predefined comparison
export const getSearchToApplyThisMonthVsLastMonth = (site: PlausibleSite) => {
  const today = nowForSite(site)
  const thisMonthStart = getStartOfMonth(today)
  const thisMonthEnd = getEndOfMonth(today)
  const lastMonthStart = shiftMonths(thisMonthStart, -1)
  const lastMonthEnd = getEndOfMonth(lastMonthStart)

  return (search: Record<string, unknown>) => ({
    ...search,
    ...clearedDateSearch,
    period: DashboardPeriod.custom,
    from: formatISO(thisMonthStart),
    to: formatISO(thisMonthEnd),
    comparison: ComparisonMode.this_month_vs_last_month,
    compare_from: formatISO(lastMonthStart),
    compare_to: formatISO(lastMonthEnd),
    keybindHint: null
  })
}

// Helper to apply "Last 7 Days vs Previous 7 Days" predefined comparison
export const getSearchToApplyLast7DaysVsPrevious7Days = (site: PlausibleSite) => {
  const today = nowForSite(site)
  const last7DaysStart = shiftDays(today, -6)
  const previous7DaysStart = shiftDays(today, -13)
  const previous7DaysEnd = shiftDays(today, -7)

  return (search: Record<string, unknown>) => ({
    ...search,
    ...clearedDateSearch,
    period: DashboardPeriod.custom,
    from: formatISO(last7DaysStart),
    to: formatISO(today),
    comparison: ComparisonMode.last_7_days_vs_previous_7_days,
    compare_from: formatISO(previous7DaysStart),
    compare_to: formatISO(previous7DaysEnd),
    keybindHint: null
  })
}

export type LinkItem = [
  string[],
  {
    search: AppNavigationTarget['search']
    isActive: (options: {
      site: PlausibleSite
      dashboardState: DashboardState
    }) => boolean
    onEvent?: (event: Pick<Event, 'preventDefault' | 'stopPropagation'>) => void
    hidden?: boolean
  }
]

/**
 * This function gets menu items with their respective navigation logic.
 * Used to render both menu items and keybind listeners.
 * `onEvent` is passed to all default items, but not extra items.
 */
export const getDatePeriodGroups = ({
  site,
  onEvent,
  extraItemsInLastGroup = [],
  extraGroups = []
}: {
  site: PlausibleSite
  onEvent?: LinkItem[1]['onEvent']
  extraItemsInLastGroup?: LinkItem[]
  extraGroups?: LinkItem[][]
}): LinkItem[][] => {
  const groups: LinkItem[][] = [
    [
      [
        ['Today', 'D'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.day,
            date: formatISO(nowForSite(site)),
            keybindHint: 'D'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.day &&
            isSameDate(dashboardState.date, nowForSite(site)),
          onEvent
        }
      ],
      [
        ['Yesterday', 'E'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.day,
            date: formatISO(yesterday(site)),
            keybindHint: 'E'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.day &&
            isSameDate(dashboardState.date, yesterday(site)),
          onEvent
        }
      ],
      [
        ['Realtime', 'R'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.realtime,
            keybindHint: 'R'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.realtime,
          onEvent
        }
      ]
    ],
    [
      [
        ['Last 24 Hours', 'H'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['24h'],
            keybindHint: 'H'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['24h'],
          onEvent
        }
      ],
      [
        ['Last 7 Days', 'W'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['7d'],
            keybindHint: 'W'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['7d'],
          onEvent
        }
      ],
      [
        ['Last 28 Days', 'F'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['28d'],
            keybindHint: 'F'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['28d'],
          onEvent
        }
      ],
      [
        ['Last 30 Days', 'T'],
        {
          hidden: true,
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['30d'],
            keybindHint: 'T'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['30d'],
          onEvent
        }
      ],
      [
        ['Last 91 Days', 'N'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['91d'],
            keybindHint: 'N'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['91d'],
          onEvent
        }
      ]
    ],
    [
      [
        ['Month to Date', 'M'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.month,
            keybindHint: 'M'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.month &&
            isSameMonth(dashboardState.date, nowForSite(site)),
          onEvent
        }
      ],
      [
        ['Last Month', 'P'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.month,
            date: formatISO(lastMonth(site)),
            keybindHint: 'P'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.month &&
            isSameMonth(dashboardState.date, lastMonth(site)),
          onEvent
        }
      ]
    ],
    [
      [
        ['Year to Date', 'Y'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod.year,
            keybindHint: 'Y'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod.year &&
            isThisYear(site, dashboardState.date),
          onEvent
        }
      ],
      [
        ['Last 6 months', 'S'],
        {
          hidden: true,
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['6mo'],
            keybindHint: 'S'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['6mo']
        }
      ],
      [
        ['Last 12 Months', 'L'],
        {
          search: (s) => ({
            ...s,
            ...clearedDateSearch,
            period: DashboardPeriod['12mo'],
            keybindHint: 'L'
          }),
          isActive: ({ dashboardState }) =>
            dashboardState.period === DashboardPeriod['12mo'],
          onEvent
        }
      ]
    ]
  ]

  const lastGroup: LinkItem[] = [
    [
      ['All time', 'A'],
      {
        search: (s) => ({
          ...s,
          ...clearedDateSearch,
          period: DashboardPeriod.all,
          keybindHint: 'A'
        }),
        isActive: ({ dashboardState }) =>
          dashboardState.period === DashboardPeriod.all,
        onEvent
      }
    ]
  ]

  return groups
    .concat([lastGroup.concat(extraItemsInLastGroup)])
    .concat(extraGroups)
}

export const getCompareLinkItem = ({
  dashboardState,
  site,
  onEvent
}: {
  dashboardState: DashboardState
  site: PlausibleSite
  onEvent: () => void
}): LinkItem => [
  [
    isComparisonEnabled(dashboardState.comparison)
      ? 'Disable comparison'
      : 'Compare',
    'X'
  ],
  {
    onEvent,
    search: getSearchToToggleComparison({ site, dashboardState }),
    isActive: () => false
  }
]

export function useSaveTimePreferencesToStorage({
  site,
  period,
  comparison,
  match_day_of_week
}: {
  site: PlausibleSite
  period: unknown
  comparison: unknown
  match_day_of_week: unknown
}) {
  useEffect(() => {
    if (
      isValidPeriod(period) &&
      ![DashboardPeriod.custom, DashboardPeriod.realtime].includes(period)
    ) {
      storePeriod(site.domain, period)
    }
    if (isValidComparison(comparison) && comparison !== ComparisonMode.custom) {
      storeComparisonMode(site.domain, comparison)
    }
    if (isValidMatchDayOfWeek(match_day_of_week)) {
      storeMatchDayOfWeek(site.domain, match_day_of_week)
    }
  }, [period, comparison, match_day_of_week, site.domain])
}

export function getSavedTimePreferencesFromStorage({
  site
}: {
  site: PlausibleSite
}): {
  period: null | DashboardPeriod
  comparison: null | ComparisonMode
  match_day_of_week: boolean | null
} {
  const stored = {
    period: getStoredPeriod(site.domain, null),
    comparison: getStoredComparisonMode(site.domain, null),
    match_day_of_week: getStoredMatchDayOfWeek(site.domain, true)
  }
  return stored
}

export function getDashboardTimeSettings({
  site,
  searchValues,
  storedValues,
  defaultValues,
  segmentIsExpanded
}: {
  site: PlausibleSite
  searchValues: Record<'period' | 'comparison' | 'match_day_of_week', unknown>
  storedValues: ReturnType<typeof getSavedTimePreferencesFromStorage>
  defaultValues: Pick<
    DashboardState,
    'period' | 'comparison' | 'match_day_of_week'
  >
  segmentIsExpanded: boolean
}): Pick<DashboardState, 'period' | 'comparison' | 'match_day_of_week'> {
  let period: DashboardPeriod
  if (isValidPeriod(searchValues.period)) {
    period = searchValues.period
  } else if (isValidPeriod(storedValues.period)) {
    period = storedValues.period
  } else if (isTodayOrYesterday(site.nativeStatsBegin)) {
    period = DashboardPeriod.day
  } else {
    period = defaultValues.period
  }

  let comparison: ComparisonMode | null

  if (isComparisonForbidden({ period, segmentIsExpanded })) {
    comparison = null
  } else {
    comparison = isValidComparison(searchValues.comparison)
      ? searchValues.comparison
      : storedValues.comparison

    if (!isComparisonEnabled(comparison)) {
      comparison = null
    }
  }

  const match_day_of_week = isValidMatchDayOfWeek(
    searchValues.match_day_of_week
  )
    ? (searchValues.match_day_of_week as boolean)
    : isValidMatchDayOfWeek(storedValues.match_day_of_week)
      ? (storedValues.match_day_of_week as boolean)
      : defaultValues.match_day_of_week

  return {
    period,
    comparison,
    match_day_of_week
  }
}

export function getCurrentPeriodDisplayName({
  dashboardState,
  site
}: {
  dashboardState: DashboardState
  site: PlausibleSite
}) {
  if (dashboardState.period === 'day') {
    if (isToday(site, dashboardState.date)) {
      return 'Today'
    }
    return formatDay(dashboardState.date)
  }

  if (dashboardState.period === '24h') {
    return 'Last 24 Hours'
  }
  if (dashboardState.period === '7d') {
    return 'Last 7 days'
  }
  if (dashboardState.period === '28d') {
    return 'Last 28 days'
  }
  if (dashboardState.period === '30d') {
    return 'Last 30 days'
  }
  if (dashboardState.period === '91d') {
    return 'Last 91 days'
  }
  if (dashboardState.period === 'month') {
    if (isThisMonth(site, dashboardState.date)) {
      return 'Month to Date'
    }
    return formatMonthYYYY(dashboardState.date)
  }
  if (dashboardState.period === '6mo') {
    return 'Last 6 months'
  }
  if (dashboardState.period === '12mo') {
    return 'Last 12 months'
  }
  if (dashboardState.period === 'year') {
    if (isThisYear(site, dashboardState.date)) {
      return 'Year to Date'
    }
    return formatYear(dashboardState.date)
  }
  if (dashboardState.period === 'all') {
    return 'All time'
  }
  if (dashboardState.period === 'custom') {
    return formatDateRange(site, dashboardState.from, dashboardState.to)
  }
  return 'Realtime'
}

export function getCurrentComparisonPeriodDisplayName({
  dashboardState,
  site
}: {
  dashboardState: DashboardState
  site: PlausibleSite
}) {
  if (!dashboardState.comparison) {
    return null
  }
  return dashboardState.comparison === ComparisonMode.custom &&
    dashboardState.compare_from &&
    dashboardState.compare_to
    ? formatDateRange(
        site,
        dashboardState.compare_from,
        dashboardState.compare_to
      )
    : COMPARISON_MODES[dashboardState.comparison]
}

// Check if main period and comparison period have different lengths
export function periodsHaveDifferentLengths(dashboardState: DashboardState): boolean {
  if (!dashboardState.comparison || dashboardState.comparison === ComparisonMode.off) {
    return false
  }

  // For custom comparison, check the actual date ranges
  if (dashboardState.comparison === ComparisonMode.custom &&
      dashboardState.from && dashboardState.to &&
      dashboardState.compare_from && dashboardState.compare_to) {
    const mainStart = dashboardState.from.toDate()
    const mainEnd = dashboardState.to.toDate()
    const compareStart = dashboardState.compare_from.toDate()
    const compareEnd = dashboardState.compare_to.toDate()

    const mainDays = Math.round((mainEnd.getTime() - mainStart.getTime()) / (1000 * 60 * 60 * 24)) + 1
    const compareDays = Math.round((compareEnd.getTime() - compareStart.getTime()) / (1000 * 60 * 60 * 24)) + 1

    return mainDays !== compareDays
  }

  // For predefined comparisons like previous_period, they should be the same length
  // by design, so return false
  return false
}
