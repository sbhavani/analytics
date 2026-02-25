import React from 'react'
import { render, screen } from '@testing-library/react'
import { CohortTable } from '../stats/cohort/cohort-table'
import { TestContextProviders } from '../../../test-utils/app-context-providers'
import { useCohortData } from '../hooks/use-cohort-data'

// Mock the useCohortData hook
jest.mock('../hooks/use-cohort-data', () => ({
  useCohortData: jest.fn()
}))

const mockCohortData = {
  cohorts: [
    {
      cohort_date: '2025-01-01',
      total_users: 1250,
      retention: [1.0, 0.45, 0.32, 0.28, 0.24, 0.21]
    },
    {
      cohort_date: '2024-12-01',
      total_users: 1180,
      retention: [1.0, 0.42, 0.30, 0.25, 0.22, 0.19]
    }
  ],
  period_labels: ['Month 0', 'Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5'],
  meta: {
    cohort_periods: 6,
    date_range: {
      from: '2024-07-01',
      to: '2025-01-31'
    }
  }
}

describe('CohortTable', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders loading state', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: true,
      isError: false,
      error: null,
      data: null
    })

    render(<CohortTable />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    expect(screen.getByText(/loading cohort data/i)).toBeInTheDocument()
  })

  it('renders error state', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: false,
      isError: true,
      error: new Error('Failed to load'),
      data: null
    })

    render(<CohortTable />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    expect(screen.getByText(/failed to load/i)).toBeInTheDocument()
  })

  it('renders cohort data', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: false,
      isError: false,
      error: null,
      data: mockCohortData
    })

    render(<CohortTable />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    // Check cohort dates are rendered
    expect(screen.getByText(/jan 2025/i)).toBeInTheDocument()
    expect(screen.getByText(/dec 2024/i)).toBeInTheDocument()

    // Check period labels are rendered
    expect(screen.getByText('Month 0')).toBeInTheDocument()
    expect(screen.getByText('Month 1')).toBeInTheDocument()
  })

  it('renders empty state when no data', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: false,
      isError: false,
      error: null,
      data: { cohorts: [], period_labels: [], meta: {} }
    })

    render(<CohortTable />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    expect(screen.getByText(/no cohort data available/i)).toBeInTheDocument()
  })

  it('renders cohort table with correct structure', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: false,
      isError: false,
      error: null,
      data: mockCohortData
    })

    render(<CohortTable />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    // Check table headers
    expect(screen.getByText('Cohort')).toBeInTheDocument()
    expect(screen.getByText('Users')).toBeInTheDocument()

    // Check user counts are rendered
    expect(screen.getByText('1,250')).toBeInTheDocument()
    expect(screen.getByText('1,180')).toBeInTheDocument()
  })

  it('passes cohortPeriods prop to useCohortData', () => {
    ;(useCohortData as jest.Mock).mockReturnValue({
      isLoading: true,
      isError: false,
      error: null,
      data: null
    })

    render(<CohortTable cohortPeriods={6} />, {
      wrapper: (props) => <TestContextProviders {...props} />
    })

    expect(useCohortData).toHaveBeenCalledWith(
      expect.objectContaining({ cohortPeriods: 6 })
    )
  })
})
