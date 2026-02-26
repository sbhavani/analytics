import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ThemeToggle from '../../dashboard/components/ThemeToggle'

// Define UIMode locally to avoid import issues with the mock
const UIMode = {
  light: 'light',
  dark: 'dark'
}

// Mock the theme context - allow returning different modes for different tests
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let mockMode: any = 'light'
const mockToggleTheme = jest.fn()

// eslint-disable-next-line no-undef
const MockUIMode = typeof UIMode !== 'undefined' ? UIMode : { light: 'light', dark: 'dark' }

jest.mock('../../dashboard/theme-context', () => ({
  useTheme: () => ({
    mode: mockMode,
    toggleTheme: mockToggleTheme
  }),
  UIMode: { light: 'light', dark: 'dark' }
}))

describe('ThemeToggle', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockMode = UIMode.light
  })

  it('renders light mode with sun icon', () => {
    mockMode = UIMode.light
    render(<ThemeToggle />)
    const button = screen.getByRole('switch', { name: /switch to dark mode/i })
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('aria-checked', 'false')
  })

  it('renders dark mode with moon icon', () => {
    mockMode = UIMode.dark
    render(<ThemeToggle />)
    const button = screen.getByRole('switch', { name: /switch to light mode/i })
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('aria-checked', 'true')
  })

  it('calls toggleTheme when clicked', async () => {
    render(<ThemeToggle />)
    const button = screen.getByRole('switch')

    await userEvent.click(button)

    expect(mockToggleTheme).toHaveBeenCalledTimes(1)
  })

  it('calls toggleTheme when Enter key is pressed', () => {
    render(<ThemeToggle />)
    const button = screen.getByRole('switch')

    fireEvent.keyDown(button, { key: 'Enter', code: 'Enter' })

    expect(mockToggleTheme).toHaveBeenCalledTimes(1)
  })

  it('calls toggleTheme when Space key is pressed', () => {
    render(<ThemeToggle />)
    const button = screen.getByRole('switch')

    fireEvent.keyDown(button, { key: ' ', code: 'Space' })

    expect(mockToggleTheme).toHaveBeenCalledTimes(1)
  })

  it('has correct accessibility attributes', () => {
    render(<ThemeToggle />)
    const button = screen.getByRole('switch')

    expect(button).toHaveAttribute('role', 'switch')
    expect(button).toHaveAttribute('aria-checked')
    expect(button).toHaveAttribute('tabIndex', '0')
  })

  it('has correct title based on current mode', () => {
    render(<ThemeToggle />)
    const button = screen.getByRole('switch')

    expect(button).toHaveAttribute('title', 'Switch to dark mode')
  })
})
