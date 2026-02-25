import React from 'react'
import { render, screen } from '@testing-library/react'
import { Popover } from '@headlessui/react'
import { TestContextProviders } from '../../../../test-utils/app-context-providers'
import { stringifySearch } from '../../util/url-search-params'
import { getRouterBasepath } from '../../router'
import { ComparisonPeriodMenuItems, ComparisonPeriodMenu } from './comparison-period-menu'
import { ComparisonMode } from '../../dashboard-time-periods'
import { mockAnimationsApi, mockResizeObserver } from 'jsdom-testing-mocks'

mockAnimationsApi()
mockResizeObserver()

const domain = 'comparison-period-menu.test'

// Helper to render the component with comparison enabled
const renderWithComparisonEnabled = (
  comparisonMode: ComparisonMode,
  matchDayOfWeek: boolean = true,
  compareFrom?: string,
  compareTo?: string
) => {
  const searchParams: Record<string, string> = {
    period: '28d',
    comparison: comparisonMode
  }

  if (matchDayOfWeek !== undefined) {
    searchParams.match_day_of_week = matchDayOfWeek.toString()
  }

  if (compareFrom && compareTo) {
    searchParams.compare_from = compareFrom
    searchParams.compare_to = compareTo
  }

  const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch(searchParams)}`

  // Use ComparisonPeriodMenu with Popover wrapper to properly render the menu
  return render(
    <Popover>
      {() => (
        <>
          <Popover.Button>Open</Popover.Button>
          <ComparisonPeriodMenu closeDropdown={jest.fn()} calendarButtonRef={{ current: null }} />
        </>
      )}
    </Popover>,
    {
      wrapper: (props) => (
        <TestContextProviders
          siteOptions={{ domain }}
          routerProps={{ initialEntries: [startUrl] }}
          {...props}
        />
      )
    }
  )
}

describe('ComparisonPeriodMenuItems', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  test('renders comparison menu items when comparison is enabled (previous_period)', async () => {
    renderWithComparisonEnabled(ComparisonMode.previous_period)

    expect(screen.getByText('Disable comparison')).toBeInTheDocument()
    expect(screen.getByText('Previous period')).toBeInTheDocument()
    expect(screen.getByText('Year over year')).toBeInTheDocument()
    expect(screen.getByText('Custom period')).toBeInTheDocument()
  })

  test('renders comparison menu items when comparison is enabled (year_over_year)', async () => {
    renderWithComparisonEnabled(ComparisonMode.year_over_year)

    expect(screen.getByText('Disable comparison')).toBeInTheDocument()
    expect(screen.getByText('Previous period')).toBeInTheDocument()
    expect(screen.getByText('Year over year')).toBeInTheDocument()
    expect(screen.getByText('Custom period')).toBeInTheDocument()
  })

  test('renders comparison menu items when comparison is enabled (custom)', async () => {
    renderWithComparisonEnabled(
      ComparisonMode.custom,
      true,
      '2024-01-01',
      '2024-01-07'
    )

    expect(screen.getByText('Disable comparison')).toBeInTheDocument()
    expect(screen.getByText('Previous period')).toBeInTheDocument()
    expect(screen.getByText('Year over year')).toBeInTheDocument()
    expect(screen.getByText('Custom period')).toBeInTheDocument()
  })

  test('shows match day of week options when comparison is previous_period', async () => {
    renderWithComparisonEnabled(ComparisonMode.previous_period, true)

    expect(screen.getByText('Match day of week')).toBeInTheDocument()
    expect(screen.getByText('Match exact date')).toBeInTheDocument()
  })

  test('shows match day of week options when comparison is year_over_year', async () => {
    renderWithComparisonEnabled(ComparisonMode.year_over_year, false)

    expect(screen.getByText('Match day of week')).toBeInTheDocument()
    expect(screen.getByText('Match exact date')).toBeInTheDocument()
  })

  test('hides match day of week options when comparison is custom', async () => {
    renderWithComparisonEnabled(ComparisonMode.custom, true, '2024-01-01', '2024-01-07')

    expect(screen.queryByText('Match day of week')).not.toBeInTheDocument()
    expect(screen.queryByText('Match exact date')).not.toBeInTheDocument()
  })

  test('highlights the currently selected comparison mode (previous_period)', async () => {
    renderWithComparisonEnabled(ComparisonMode.previous_period)

    const previousPeriodLink = screen.getByText('Previous period')
    expect(previousPeriodLink.closest('a')).toHaveAttribute(
      'data-selected',
      'true'
    )
  })

  test('highlights the currently selected comparison mode (year_over_year)', async () => {
    renderWithComparisonEnabled(ComparisonMode.year_over_year)

    const yearOverYearLink = screen.getByText('Year over year')
    expect(yearOverYearLink.closest('a')).toHaveAttribute(
      'data-selected',
      'true'
    )
  })

  test('highlights custom when comparison is custom', async () => {
    renderWithComparisonEnabled(ComparisonMode.custom, true, '2024-01-01', '2024-01-07')

    const customLink = screen.getByText('Custom period')
    expect(customLink.closest('a')).toHaveAttribute(
      'data-selected',
      'true'
    )
  })

  test('does not render menu items when comparison is off', async () => {
    const searchParams = stringifySearch({
      period: '28d',
      comparison: ComparisonMode.off
    })
    const startUrl = `${getRouterBasepath({ domain, shared: false })}${searchParams}`

    render(<ComparisonPeriodMenuItems closeDropdown={jest.fn()} toggleCalendar={jest.fn()} />, {
      wrapper: (props) => (
        <TestContextProviders
          siteOptions={{ domain }}
          routerProps={{ initialEntries: [startUrl] }}
          {...props}
        />
      )
    })

    // When comparison is off, the menu items should not render at all
    expect(screen.queryByText('Disable comparison')).not.toBeInTheDocument()
    expect(screen.queryByText('Previous period')).not.toBeInTheDocument()
  })
})

describe('ComparisonPeriodMenu', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  test('displays the correct label when comparison is previous_period', async () => {
    const searchParams = stringifySearch({
      period: '28d',
      comparison: ComparisonMode.previous_period
    })
    const startUrl = `${getRouterBasepath({ domain, shared: false })}${searchParams}`

    render(
      <Popover>
        {() => <ComparisonPeriodMenu closeDropdown={jest.fn()} calendarButtonRef={{ current: null }} />}
      </Popover>,
      {
        wrapper: (props) => (
          <TestContextProviders
            siteOptions={{ domain }}
            routerProps={{ initialEntries: [startUrl] }}
            {...props}
          />
        )
      }
    )

    expect(screen.getByText('Previous period')).toBeInTheDocument()
  })

  test('displays the correct label when comparison is year_over_year', async () => {
    const searchParams = stringifySearch({
      period: '28d',
      comparison: ComparisonMode.year_over_year
    })
    const startUrl = `${getRouterBasepath({ domain, shared: false })}${searchParams}`

    render(
      <Popover>
        {() => <ComparisonPeriodMenu closeDropdown={jest.fn()} calendarButtonRef={{ current: null }} />}
      </Popover>,
      {
        wrapper: (props) => (
          <TestContextProviders
            siteOptions={{ domain }}
            routerProps={{ initialEntries: [startUrl] }}
            {...props}
          />
        )
      }
    )

    expect(screen.getByText('Year over year')).toBeInTheDocument()
  })

  test('displays custom date range when comparison is custom with dates', async () => {
    const searchParams = stringifySearch({
      period: '28d',
      comparison: ComparisonMode.custom,
      compare_from: '2024-01-01',
      compare_to: '2024-01-07'
    })
    const startUrl = `${getRouterBasepath({ domain, shared: false })}${searchParams}`

    render(
      <Popover>
        {() => <ComparisonPeriodMenu closeDropdown={jest.fn()} calendarButtonRef={{ current: null }} />}
      </Popover>,
      {
        wrapper: (props) => (
          <TestContextProviders
            siteOptions={{ domain }}
            routerProps={{ initialEntries: [startUrl] }}
            {...props}
          />
        )
      }
    )

    // Should show formatted custom date range
    expect(screen.getByText(/1 Jan - 7 Jan 24/)).toBeInTheDocument()
  })
})
