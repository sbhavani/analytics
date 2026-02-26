import React from 'react'
import { render, screen } from '@testing-library/react'
import { PercentageIndicator } from './PercentageIndicator'

describe('PercentageIndicator', () => {
  describe('positive change', () => {
    it('renders green color for positive percentage', () => {
      render(<PercentageIndicator value={25} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('+25%')
      expect(element).toHaveClass('text-green-500')
    })

    it('renders with proper sign for small positive percentage', () => {
      render(<PercentageIndicator value={5} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('+5%')
    })
  })

  describe('negative change', () => {
    it('renders red color for negative percentage', () => {
      render(<PercentageIndicator value={-15} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('-15%')
      expect(element).toHaveClass('text-red-400')
    })

    it('renders negative percentage without extra sign', () => {
      render(<PercentageIndicator value={-50} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('-50%')
    })
  })

  describe('zero value edge cases', () => {
    it('displays N/A for zero value', () => {
      render(<PercentageIndicator value={0} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('N/A')
    })

    it('displays N/A when comparing identical values (0% change)', () => {
      render(<PercentageIndicator value={0} showNAForZero={true} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('N/A')
    })
  })

  describe('null/undefined handling', () => {
    it('displays N/A for null value', () => {
      render(<PercentageIndicator value={null} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('N/A')
    })

    it('displays N/A for undefined value', () => {
      render(<PercentageIndicator value={undefined} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('N/A')
    })

    it('displays no data message when explicitly configured', () => {
      render(<PercentageIndicator value={null} emptyMessage="No data available" />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('No data available')
    })
  })

  describe('no change (zero)', () => {
    it('displays neutral styling for zero percentage when configured', () => {
      render(<PercentageIndicator value={0} showZeroAsNeutral={true} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('0%')
      expect(element).not.toHaveClass('text-green-500')
      expect(element).not.toHaveClass('text-red-400')
    })
  })

  describe('custom formatting', () => {
    it('accepts custom className', () => {
      render(<PercentageIndicator value={10} className="text-sm font-bold" />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveClass('text-sm', 'font-bold')
    })

    it('renders with absolute value when configured', () => {
      render(<PercentageIndicator value={-25} absoluteValue={true} />)

      const element = screen.getByTestId('percentage-indicator')

      expect(element).toHaveTextContent('25%')
    })
  })
})
