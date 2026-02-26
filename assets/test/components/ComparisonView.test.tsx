import React from 'react'
import { render, screen } from '@testing-library/react'
import ComparisonView from '../../js/dashboard/components/comparison-view'

// Mock the PercentageIndicator component
jest.mock('../../js/dashboard/components/percentage-indicator', () => ({
  __esModule: true,
  default: ({ change, inverse }: { change: number; inverse?: boolean }) => {
    const isPositive = inverse ? change < 0 : change > 0
    const colorClass = isPositive ? 'text-green-500' : 'text-red-400'
    const arrow = change > 0 ? '↑' : change < 0 ? '↓' : ''
    return (
      <span data-testid="percentage-indicator" className={colorClass}>
        {arrow} {Math.abs(change)}%
      </span>
    )
  }
}))

interface MetricData {
  value: number
  previousValue: number
  change: number
}

interface ComparisonData {
  primary: {
    startDate: string
    endDate: string
    metrics: Record<string, MetricData>
  }
  comparison: {
    startDate: string
    endDate: string
    label: string
  }
}

const mockComparisonData: ComparisonData = {
  primary: {
    startDate: '2026-02-17',
    endDate: '2026-02-23',
    metrics: {
      visitors: { value: 1500, previousValue: 1000, change: 50 },
      pageviews: { value: 5000, previousValue: 4000, change: 25 },
      bounce_rate: { value: 45, previousValue: 50, change: -10 }
    }
  },
  comparison: {
    startDate: '2026-02-10',
    endDate: '2026-02-16',
    label: 'Last Week'
  }
}

describe('ComparisonView', () => {
  it('renders primary period date range', () => {
    render(<ComparisonView data={mockComparisonData} />)

    expect(screen.getByTestId('primary-period')).toHaveTextContent(
      'Feb 17 - Feb 23, 2026'
    )
  })

  it('renders comparison period date range', () => {
    render(<ComparisonView data={mockComparisonData} />)

    expect(screen.getByTestId('comparison-period')).toHaveTextContent(
      'Feb 10 - Feb 16, 2026 (Last Week)'
    )
  })

  it('renders all metrics with values', () => {
    render(<ComparisonView data={mockComparisonData} />)

    expect(screen.getByTestId('metric-visitors')).toHaveTextContent('1,500')
    expect(screen.getByTestId('metric-pageviews')).toHaveTextContent('5,000')
    expect(screen.getByTestId('metric-bounce_rate')).toHaveTextContent('45%')
  })

  it('renders percentage changes for each metric', () => {
    render(<ComparisonView data={mockComparisonData} />)

    const visitorsIndicator = screen.getByTestId('visitors-change')
    expect(visitorsIndicator).toHaveTextContent('↑ 50%')

    const pageviewsIndicator = screen.getByTestId('pageviews-change')
    expect(pageviewsIndicator).toHaveTextContent('↑ 25%')
  })

  it('displays positive change in green color', () => {
    render(<ComparisonView data={mockComparisonData} />)

    const visitorsIndicator = screen.getByTestId('visitors-change')
    expect(visitorsIndicator).toHaveClass('text-green-500')
  })

  it('displays negative change in red color', () => {
    render(<ComparisonView data={mockComparisonData} />)

    const bounceRateIndicator = screen.getByTestId('bounce_rate-change')
    expect(bounceRateIndicator).toHaveClass('text-red-400')
  })

  it('renders N/A when comparison value is zero', () => {
    const dataWithZeroComparison: ComparisonData = {
      ...mockComparisonData,
      primary: {
        ...mockComparisonData.primary,
        metrics: {
          visitors: { value: 100, previousValue: 0, change: 100 }
        }
      }
    }

    render(<ComparisonView data={dataWithZeroComparison} />)

    expect(screen.getByTestId('visitors-change')).toHaveTextContent('N/A')
  })

  it('renders N/A when both values are zero', () => {
    const dataWithBothZero: ComparisonData = {
      ...mockComparisonData,
      primary: {
        ...mockComparisonData.primary,
        metrics: {
          visitors: { value: 0, previousValue: 0, change: 0 }
        }
      }
    }

    render(<ComparisonView data={dataWithBothZero} />)

    expect(screen.getByTestId('visitors-change')).toHaveTextContent('N/A')
  })

  it('displays "No data available" when primary period has no data', () => {
    const dataWithNoPrimary: ComparisonData = {
      ...mockComparisonData,
      primary: {
        startDate: '2026-02-17',
        endDate: '2026-02-23',
        metrics: {
          visitors: { value: 0, previousValue: 100, change: -100 }
        }
      }
    }

    render(<ComparisonView data={dataWithNoPrimary} />)

    expect(screen.getByTestId('no-data-message')).toHaveTextContent(
      'No data available for this period'
    )
  })

  it('renders custom date range labels', () => {
    const customData: ComparisonData = {
      primary: {
        startDate: '2026-01-01',
        endDate: '2026-01-31',
        metrics: {
          visitors: { value: 5000, previousValue: 4500, change: 11.11 }
        }
      },
      comparison: {
        startDate: '2025-12-01',
        endDate: '2025-12-31',
        label: 'December 2025'
      }
    }

    render(<ComparisonView data={customData} />)

    expect(screen.getByTestId('primary-period')).toHaveTextContent(
      'Jan 1 - Jan 31, 2026'
    )
    expect(screen.getByTestId('comparison-period')).toHaveTextContent(
      'Dec 1 - Dec 31, 2025 (December 2025)'
    )
  })

  it('handles multiple metrics with mixed change directions', () => {
    const mixedData: ComparisonData = {
      ...mockComparisonData,
      primary: {
        ...mockComparisonData.primary,
        metrics: {
          visitors: { value: 1500, previousValue: 1000, change: 50 },
          bounce_rate: { value: 45, previousValue: 50, change: -10 },
          visit_duration: { value: 180, previousValue: 180, change: 0 }
        }
      }
    }

    render(<ComparisonView data={mixedData} />)

    // Positive change - green
    const visitorsIndicator = screen.getByTestId('visitors-change')
    expect(visitorsIndicator).toHaveClass('text-green-500')

    // Negative change - red (but inverse metric, so green for bounce rate)
    const bounceRateIndicator = screen.getByTestId('bounce_rate-change')
    expect(bounceRateIndicator).toHaveClass('text-green-500')

    // Zero change - no color
    const durationIndicator = screen.getByTestId('visit_duration-change')
    expect(durationIndicator).toHaveTextContent('0%')
  })

  it('renders inverse colors for bounce_rate metric', () => {
    const bounceRateData: ComparisonData = {
      ...mockComparisonData,
      primary: {
        ...mockComparisonData.primary,
        metrics: {
          bounce_rate: { value: 30, previousValue: 50, change: -40 }
        }
      }
    }

    render(<ComparisonView data={bounceRateData} />)

    // Lower bounce rate is positive, so should be green (decrease)
    const bounceRateIndicator = screen.getByTestId('bounce_rate-change')
    expect(bounceRateIndicator).toHaveClass('text-green-500')
  })

  it('renders inverse colors for conversion_rate when increase is negative', () => {
    const conversionData: ComparisonData = {
      ...mockComparisonData,
      primary: {
        ...mockComparisonData.primary,
        metrics: {
          conversion_rate: { value: 5, previousValue: 3, change: 66.67 }
        }
      }
    }

    render(<ComparisonView data={conversionData} />)

    // Higher conversion rate is positive, so should be green
    const conversionIndicator = screen.getByTestId('conversion_rate-change')
    expect(conversionIndicator).toHaveClass('text-green-500')
  })
})
