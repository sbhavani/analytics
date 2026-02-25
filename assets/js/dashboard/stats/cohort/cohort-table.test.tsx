import React from 'react'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import CohortTable from './cohort-table'
import { getCohorts } from '../../api'

jest.mock('../../api', () => ({
  getCohorts: jest.fn()
}))

const mockGetCohorts = getCohorts as jest.MockedFunction<typeof getCohorts>

const mockCohortData = {
  cohorts: [
    {
      id: 'cohort-1',
      date: '2024-01',
      size: 1000,
      retention: [
        { period_number: 1, retained_count: 1000, retention_rate: 1.0 },
        { period_number: 2, retained_count: 800, retention_rate: 0.8 },
        { period_number: 3, retained_count: 600, retention_rate: 0.6 },
        { period_number: 4, retained_count: 500, retention_rate: 0.5 },
        { period_number: 5, retained_count: 400, retention_rate: 0.4 },
        { period_number: 6, retained_count: 350, retention_rate: 0.35 }
      ]
    },
    {
      id: 'cohort-2',
      date: '2024-02',
      size: 1200,
      retention: [
        { period_number: 1, retained_count: 1100, retention_rate: 0.917 },
        { period_number: 2, retained_count: 900, retention_rate: 0.75 },
        { period_number: 3, retained_count: 700, retention_rate: 0.583 },
        { period_number: 4, retained_count: 550, retention_rate: 0.458 },
        { period_number: 5, retained_count: 450, retention_rate: 0.375 }
      ]
    },
    {
      id: 'cohort-3',
      date: '2024-03',
      size: 800,
      retention: [
        { period_number: 1, retained_count: 600, retention_rate: 0.75 },
        { period_number: 2, retained_count: 400, retention_rate: 0.5 },
        { period_number: 3, retained_count: 200, retention_rate: 0.25 }
      ]
    }
  ],
  meta: {
    period: 'monthly',
    date_range: {
      from: '2024-01-01',
      to: '2024-03-31'
    }
  }
}

describe('CohortTable', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading state initially', () => {
    mockGetCohorts.mockImplementation(
      () => new Promise(() => {}) // Never resolves to keep loading
    )

    render(<CohortTable siteId="site-1" domain="example.com" />)

    // Should show spinner
    expect(screen.getByRole('status')).toBeInTheDocument()
  })

  it('renders error state when API fails', async () => {
    mockGetCohorts.mockRejectedValue(new Error('Failed to load'))

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText(/Failed to load cohort data/i)).toBeInTheDocument()
    })

    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument()
  })

  it('renders cohort table with data', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      // Check cohort headers
      expect(screen.getByText('Cohort')).toBeInTheDocument()
      expect(screen.getByText('Size')).toBeInTheDocument()
      expect(screen.getByText('Month 1')).toBeInTheDocument()
      expect(screen.getByText('Month 2')).toBeInTheDocument()
    })

    // Check cohort rows exist
    expect(screen.getByText('Jan 2024')).toBeInTheDocument()
    expect(screen.getByText('Feb 2024')).toBeInTheDocument()
    expect(screen.getByText('Mar 2024')).toBeInTheDocument()

    // Check cohort sizes
    expect(screen.getByText('1,000')).toBeInTheDocument()
    expect(screen.getByText('1,200')).toBeInTheDocument()
    expect(screen.getByText('800')).toBeInTheDocument()

    // Check retention rates are rendered
    expect(screen.getByText('100%')).toBeInTheDocument()
    expect(screen.getByText('80%')).toBeInTheDocument()
    expect(screen.getByText('60%')).toBeInTheDocument()
  })

  it('renders empty state when no cohorts', async () => {
    mockGetCohorts.mockResolvedValue({
      cohorts: [],
      meta: {
        period: 'monthly',
        date_range: { from: '2024-01-01', to: '2024-03-31' }
      }
    })

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(
        screen.getByText(/no users acquired in the selected period/i)
      ).toBeInTheDocument()
    })
  })

  it('renders period selector buttons', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /daily/i })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /weekly/i })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /monthly/i })).toBeInTheDocument()
    })
  })

  it('calls API with correct period when changed', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /weekly/i })).toBeInTheDocument()
    })

    // Click weekly button
    mockGetCohorts.mockClear()
    mockGetCohorts.mockResolvedValue({
      ...mockCohortData,
      meta: { ...mockCohortData.meta, period: 'weekly' }
    })

    fireEvent.click(screen.getByRole('button', { name: /weekly/i }))

    await waitFor(() => {
      expect(mockGetCohorts).toHaveBeenCalledWith('example.com', {
        period: 'weekly',
        from: undefined,
        to: undefined
      })
    })
  })

  it('calls API with date range when changed', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByLabelText(/from:/i)).toBeInTheDocument()
    })

    const dateFromInput = screen.getByLabelText(/from:/i)
    const dateToInput = screen.getByLabelText(/to:/i)

    // Change date from
    mockGetCohorts.mockClear()
    mockGetCohorts.mockResolvedValue(mockCohortData)

    fireEvent.change(dateFromInput, { target: { value: '2024-01-15' } })

    await waitFor(() => {
      expect(mockGetCohorts).toHaveBeenCalledWith('example.com', {
        period: 'monthly',
        from: '2024-01-15',
        to: undefined
      })
    })

    // Change date to
    mockGetCohorts.mockClear()
    mockGetCohorts.mockResolvedValue(mockCohortData)

    fireEvent.change(dateToInput, { target: { value: '2024-02-28' } })

    await waitFor(() => {
      expect(mockGetCohorts).toHaveBeenCalledWith('example.com', {
        period: 'monthly',
        from: '2024-01-15',
        to: '2024-02-28'
      })
    })
  })

  it('renders legend with retention color ranges', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText('Retention:')).toBeInTheDocument()
      expect(screen.getByText('0-25%')).toBeInTheDocument()
      expect(screen.getByText('25-50%')).toBeInTheDocument()
      expect(screen.getByText('50-75%')).toBeInTheDocument()
      expect(screen.getByText('75-100%')).toBeInTheDocument()
    })
  })

  it('highlights active period button', async () => {
    mockGetCohorts.mockResolvedValue(mockCohortData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      // Monthly should be active by default
      const monthlyButton = screen.getByRole('button', { name: /monthly/i })
      expect(monthlyButton).toHaveClass('bg-gray-900')
      expect(monthlyButton).toHaveTextContent('white')
    })
  })

  it('renders daily period cohort data correctly', async () => {
    const dailyData = {
      cohorts: [
        {
          id: 'cohort-1',
          date: '2024-01-15',
          size: 500,
          retention: [
            { period_number: 1, retained_count: 250, retention_rate: 0.5 },
            { period_number: 2, retained_count: 125, retention_rate: 0.25 }
          ]
        }
      ],
      meta: {
        period: 'daily',
        date_range: { from: '2024-01-15', to: '2024-01-17' }
      }
    }
    mockGetCohorts.mockResolvedValue(dailyData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText('Day 1')).toBeInTheDocument()
      expect(screen.getByText('Day 2')).toBeInTheDocument()
    })
  })

  it('renders weekly period cohort data correctly', async () => {
    const weeklyData = {
      cohorts: [
        {
          id: 'cohort-1',
          date: '2024-W01',
          size: 750,
          retention: [
            { period_number: 1, retained_count: 500, retention_rate: 0.667 },
            { period_number: 2, retained_count: 350, retention_rate: 0.467 }
          ]
        }
      ],
      meta: {
        period: 'weekly',
        date_range: { from: '2024-01-01', to: '2024-01-31' }
      }
    }
    mockGetCohorts.mockResolvedValue(weeklyData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText('Week 1')).toBeInTheDocument()
      expect(screen.getByText('Week 2')).toBeInTheDocument()
    })
  })

  it('calls retry button to reload data', async () => {
    mockGetCohorts.mockRejectedValue(new Error('Failed to load'))

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument()
    })

    // Click retry
    mockGetCohorts.mockResolvedValue(mockCohortData)

    fireEvent.click(screen.getByRole('button', { name: /retry/i }))

    await waitFor(() => {
      expect(mockGetCohorts).toHaveBeenCalled()
    })
  })

  it('renders cohort with 0% retention correctly', async () => {
    const zeroRetentionData = {
      cohorts: [
        {
          id: 'cohort-1',
          date: '2024-01',
          size: 100,
          retention: [
            { period_number: 1, retained_count: 0, retention_rate: 0 }
          ]
        }
      ],
      meta: {
        period: 'monthly',
        date_range: { from: '2024-01-01', to: '2024-01-31' }
      }
    }
    mockGetCohorts.mockResolvedValue(zeroRetentionData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText('0%')).toBeInTheDocument()
    })
  })

  it('renders cohort with 100% retention correctly', async () => {
    const fullRetentionData = {
      cohorts: [
        {
          id: 'cohort-1',
          date: '2024-01',
          size: 100,
          retention: [
            { period_number: 1, retained_count: 100, retention_rate: 1.0 }
          ]
        }
      ],
      meta: {
        period: 'monthly',
        date_range: { from: '2024-01-01', to: '2024-01-31' }
      }
    }
    mockGetCohorts.mockResolvedValue(fullRetentionData)

    render(<CohortTable siteId="site-1" domain="example.com" />)

    await waitFor(() => {
      expect(screen.getByText('100%')).toBeInTheDocument()
    })
  })
})
