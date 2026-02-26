import React from 'react'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { TestContextProviders } from '../../test-utils/app-context-providers'
import { stringifySearch } from '../../js/dashboard/util/url-search-params'
import { getRouterBasepath } from '../../js/dashboard/router'
import { DashboardPeriodPicker } from '../../js/dashboard/nav-menu/query-periods/dashboard-period-picker'
import { mockAnimationsApi, mockResizeObserver } from 'jsdom-testing-mocks'
import { ComparisonMode } from '../../js/dashboard/dashboard-time-periods'

mockAnimationsApi()
mockResizeObserver()

const domain = 'period-picker.test'
const periodStorageKey = `period__${domain}`

describe('PeriodPicker Component', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  describe('Predefined Period Selection (User Story 2)', () => {
    test('displays predefined period options when clicking the period button', async () => {
      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('Last 28 days'))

      // Check predefined period options are present (text includes keyboard shortcut letter)
      const options = screen.getAllByRole('link').map((el) => el.textContent || '')
      expect(options.some((o) => o.startsWith('Today'))).toBe(true)
      expect(options.some((o) => o.startsWith('Yesterday'))).toBe(true)
      expect(options.some((o) => o.startsWith('Last 7 Days'))).toBe(true)
      expect(options.some((o) => o.startsWith('Last 28 Days'))).toBe(true)
      expect(options.some((o) => o.startsWith('Month to Date'))).toBe(true)
      expect(options.some((o) => o.startsWith('Year to Date'))).toBe(true)
    })

    test('can select predefined period option "Last 7 Days"', async () => {
      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('Last 28 days'))
      await userEvent.click(screen.getByText('Last 7 Days'))

      expect(screen.queryByTestId('datemenu')).not.toBeInTheDocument()
      expect(localStorage.getItem(periodStorageKey)).toBe('7d')
    })

    test('can select predefined period option "Month to Date"', async () => {
      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('Last 28 days'))
      await userEvent.click(screen.getByText('Month to Date'))

      expect(screen.queryByTestId('datemenu')).not.toBeInTheDocument()
      expect(localStorage.getItem(periodStorageKey)).toBe('month')
    })

    test('can select predefined period option "Year to Date"', async () => {
      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('Last 28 days'))
      await userEvent.click(screen.getByText('Year to Date'))

      expect(screen.queryByTestId('datemenu')).not.toBeInTheDocument()
      expect(localStorage.getItem(periodStorageKey)).toBe('year')
    })

    test('respects period from URL over stored value', async () => {
      localStorage.setItem(periodStorageKey, '28d')
      const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch({ period: '7d' })}`

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders
            siteOptions={{ domain }}
            routerProps={{ initialEntries: [startUrl] }}
            {...props}
          />
        )
      })

      expect(screen.getByText('Last 7 days')).toBeVisible()
      expect(localStorage.getItem(periodStorageKey)).toBe('7d')
    })
  })

  describe('Comparison Mode (User Story 2)', () => {
    test('shows "Compare" option in period menu', async () => {
      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('Last 28 days'))

      // The Compare option should be present in the menu
      expect(screen.getByText('Compare')).toBeInTheDocument()
    })

    test('does not show Compare option for "All time" period', async () => {
      localStorage.setItem(periodStorageKey, 'all')

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders siteOptions={{ domain }} {...props} />
        )
      })

      await userEvent.click(screen.getByText('All time'))
      expect(screen.getByTestId('datemenu')).toBeVisible()
      expect(screen.queryByText('Compare')).toBeNull()
    })

    test('displays comparison period selector when comparison is enabled', async () => {
      const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch({
        period: '7d',
        comparison: ComparisonMode.previous_period
      })}`

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          <TestContextProviders
            siteOptions={{ domain }}
            routerProps={{ initialEntries: [startUrl] }}
            {...props}
          />
        )
      })

      // Should show both period selectors
      expect(screen.getByText('Last 7 days')).toBeVisible()
      expect(screen.getByText('vs.')).toBeVisible()
      expect(screen.getByText('Previous period')).toBeVisible()
    })

    test('shows "Disable comparison" when comparison is already enabled', async () => {
      const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch({
        period: '7d',
        comparison: ComparisonMode.previous_period
      })}`

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          TestContextProviders({
            siteOptions: { domain },
            routerProps: { initialEntries: [startUrl] },
            children: <DashboardPeriodPicker />
          })
        )
      })

      await userEvent.click(screen.getByText('Last 7 days'))

      // Should show "Disable comparison" instead of "Compare"
      expect(screen.getByText('Disable comparison')).toBeVisible()
    })

    test('can switch from Previous period to Year over year', async () => {
      const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch({
        period: '7d',
        comparison: ComparisonMode.previous_period
      })}`

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          TestContextProviders({
            siteOptions: { domain },
            routerProps: { initialEntries: [startUrl] },
            children: <DashboardPeriodPicker />
          })
        )
      })

      await userEvent.click(screen.getByText('Previous period'))
      await userEvent.click(screen.getByText('Year over year'))

      expect(screen.getByText('Year over year')).toBeVisible()
    })
  })

  describe('Match Day of Week Option', () => {
    test('displays match day of week options when comparison is enabled', async () => {
      const startUrl = `${getRouterBasepath({ domain, shared: false })}${stringifySearch({
        period: '7d',
        comparison: ComparisonMode.previous_period
      })}`

      render(<DashboardPeriodPicker />, {
        wrapper: (props) => (
          TestContextProviders({
            siteOptions: { domain },
            routerProps: { initialEntries: [startUrl] },
            children: <DashboardPeriodPicker />
          })
        )
      })

      await userEvent.click(screen.getByText('Previous period'))

      // Should show match day of week options
      expect(screen.getByText('Match day of week')).toBeVisible()
      expect(screen.getByText('Match exact date')).toBeVisible()
    })
  })
})
