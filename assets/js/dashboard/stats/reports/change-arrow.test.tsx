import React from 'react'
import { render, screen } from '@testing-library/react'
import { ChangeArrow } from './change-arrow'

jest.mock('@heroicons/react/24/solid', () => ({
  ArrowUpRightIcon: ({ className }: { className: string }) => (
    <span className={className}>↑</span>
  ),
  ArrowDownRightIcon: ({ className }: { className: string }) => (
    <span className={className}>↓</span>
  )
}))

it('renders green for positive change', () => {
  render(<ChangeArrow change={1} className="text-xs" metric="visitors" />)

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('↑ +1%')
  expect(arrowElement.children[0]).toHaveClass('text-green-500')
})

it('renders red for positive change', () => {
  render(<ChangeArrow change={-10} className="text-xs" metric="visitors" />)

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('↓ 10%')
  expect(arrowElement.children[0]).toHaveClass('text-red-400')
})

it('renders tilde for no change', () => {
  render(<ChangeArrow change={0} className="text-xs" metric="visitors" />)

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('0%')
})

it('inverts colors for positive bounce_rate change', () => {
  render(<ChangeArrow change={15} className="text-xs" metric="bounce_rate" />)

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('↑ +15%')
  expect(arrowElement.children[0]).toHaveClass('text-red-400')
})

it('inverts colors for negative bounce_rate change', () => {
  render(<ChangeArrow change={-3} className="text-xs" metric="bounce_rate" />)

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('↓ 3%')
  expect(arrowElement.children[0]).toHaveClass('text-green-500')
})

it('renders with text hidden', () => {
  render(
    <ChangeArrow change={-3} className="text-xs" metric="visitors" hideNumber />
  )

  const arrowElement = screen.getByTestId('change-arrow')

  expect(arrowElement).toHaveTextContent('↓')
  expect(arrowElement.children[0]).toHaveClass('text-red-400')
})

it('renders no content with text hidden and 0 change', () => {
  render(
    <ChangeArrow change={0} className="text-xs" metric="visitors" hideNumber />
  )

  const arrowElement = screen.getByTestId('change-arrow')
  expect(arrowElement).toHaveTextContent('')
})

// FR-008: Zero/null/undefined value metrics should show "N/A"
it('renders N/A when change is null', () => {
  render(<ChangeArrow change={null} className="text-xs" metric="visitors" />)

  const arrowElement = screen.getByTestId('change-arrow')
  const naElement = arrowElement.querySelector('span.text-gray-400')

  expect(arrowElement).toHaveTextContent('N/A')
  expect(naElement).toHaveClass('text-gray-400')
})

it('renders N/A when change is undefined', () => {
  render(<ChangeArrow change={undefined} className="text-xs" metric="visitors" />)

  const arrowElement = screen.getByTestId('change-arrow')
  const naElement = arrowElement.querySelector('span.text-gray-400')

  expect(arrowElement).toHaveTextContent('N/A')
  expect(naElement).toHaveClass('text-gray-400')
})

it('renders nothing when change is null and hideNumber is true', () => {
  render(
    <ChangeArrow change={null} className="text-xs" metric="visitors" hideNumber />
  )

  expect(screen.queryByTestId('change-arrow')).toBeNull()
})

it('renders nothing when change is undefined and hideNumber is true', () => {
  render(
    <ChangeArrow change={undefined} className="text-xs" metric="visitors" hideNumber />
  )

  expect(screen.queryByTestId('change-arrow')).toBeNull()
})

// T013: Test percentage prefix display - + for positive, - for negative
describe('percentage prefix display', () => {
  it('displays + prefix for positive percentage change', () => {
    render(<ChangeArrow change={25} className="text-xs" metric="visitors" />)

    const arrowElement = screen.getByTestId('change-arrow')

    // Positive changes should show + prefix
    expect(arrowElement).toHaveTextContent('+25%')
  })

  it('displays down arrow for negative percentage change', () => {
    render(<ChangeArrow change={-15} className="text-xs" metric="visitors" />)

    const arrowElement = screen.getByTestId('change-arrow')

    // Negative changes show down arrow (↓) with the percentage value
    expect(arrowElement).toHaveTextContent('↓ 15%')
  })

  it('shows no prefix for zero percentage change', () => {
    render(<ChangeArrow change={0} className="text-xs" metric="visitors" />)

    const arrowElement = screen.getByTestId('change-arrow')

    // Zero should not have + or - prefix
    expect(arrowElement).toHaveTextContent('0%')
  })
})
