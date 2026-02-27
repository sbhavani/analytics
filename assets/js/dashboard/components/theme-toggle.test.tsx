import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ThemeToggle } from './theme-toggle'
import { UIMode, useTheme } from '../theme-context'

// Mock fetch globally
const mockFetch = jest.fn()
global.fetch = mockFetch

// Mock the useTheme hook
jest.mock('../theme-context', () => ({
  ...jest.requireActual('../theme-context'),
  useTheme: jest.fn()
}))

describe('ThemeToggle', () => {
  beforeEach(() => {
    mockFetch.mockClear()
    // Reset html element to light mode by default
    document.documentElement.classList.remove('dark')
    localStorage.clear();
    (useTheme as jest.Mock).mockReset()
  })

  it('renders moon icon in light mode', () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    render(<ThemeToggle />)
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    expect(button).toBeInTheDocument()
    expect(button.querySelector('svg')).toHaveAttribute('aria-hidden', 'true')
  })

  it('renders sun icon in dark mode', () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.dark })
    render(<ThemeToggle />)
    const button = screen.getByRole('button', { name: /switch to light mode/i })
    expect(button).toBeInTheDocument()
  })

  it('toggles theme when clicked in light mode', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({})
    })

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(button)

    // Should add dark class to html element
    expect(document.documentElement.classList.contains('dark')).toBe(true)

    // Should save to localStorage
    expect(localStorage.getItem('theme_preference')).toBe('dark')

    // Should call API
    expect(mockFetch).toHaveBeenCalledWith(
      '/settings/preferences/theme',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ user: { theme: 'dark' } })
      })
    )
  })

  it('toggles theme when clicked in dark mode', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.dark })
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({})
    })

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /switch to light mode/i })
    await userEvent.click(button)

    // Should remove dark class from html element
    expect(document.documentElement.classList.contains('dark')).toBe(false)

    // Should save to localStorage
    expect(localStorage.getItem('theme_preference')).toBe('light')
  })

  it('shows loading state while theme is being updated', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockImplementation(
      () =>
        new Promise((resolve) => {
          setTimeout(() => {
            resolve({
              ok: true,
              json: () => Promise.resolve({})
            })
          }, 100)
        })
    )

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(button)

    // Button should be disabled during loading
    expect(button).toBeDisabled()

    // Should show spinner (arrow path icon with animate-spin class)
    await waitFor(() => {
      expect(screen.getByRole('button').querySelector('.animate-spin')).toBeInTheDocument()
    })
  })

  it('handles API failure gracefully - theme stays in optimistic state', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status: 500
    })

    render(<ThemeToggle />)

    // Start in light mode
    expect(document.documentElement.classList.contains('dark')).toBe(false)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(button)

    // Wait for the API call
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalled()
    })

    // Theme stays in optimistic state (dark) even after API failure
    await waitFor(() => {
      expect(document.documentElement.classList.contains('dark')).toBe(true)
    })
  })

  it('handles network error gracefully - theme stays in optimistic state', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockRejectedValueOnce(new Error('Network error'))

    render(<ThemeToggle />)

    expect(document.documentElement.classList.contains('dark')).toBe(false)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(button)

    // Wait for the fetch to fail
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalled()
    })

    // Theme stays in optimistic state (dark) even after network error
    await waitFor(() => {
      expect(document.documentElement.classList.contains('dark')).toBe(true)
    })
  })

  it('handles localStorage being unavailable', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({})
    })

    // Mock localStorage.setItem to throw
    const originalSetItem = window.localStorage.setItem
    Object.defineProperty(window.localStorage, 'setItem', {
      writable: true,
      value: jest.fn(() => {
        throw new Error('QuotaExceededError')
      })
    })

    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(button)

    // Should still call API even if localStorage fails
    expect(mockFetch).toHaveBeenCalled()

    // Restore localStorage
    Object.defineProperty(window.localStorage, 'setItem', {
      writable: true,
      value: originalSetItem
    })
  })

  it('accepts custom className', () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    render(<ThemeToggle className="custom-class" />)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('custom-class')
  })

  it('is accessible via keyboard', async () => {
    ;(useTheme as jest.Mock).mockReturnValue({ mode: UIMode.light })
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({})
    })

    render(<ThemeToggle />)

    const button = screen.getByRole('button')
    button.focus()
    expect(button).toHaveFocus()

    await userEvent.keyboard('{Enter}')

    // Theme should be toggled
    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })
})
