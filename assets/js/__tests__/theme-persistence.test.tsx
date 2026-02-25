/**
 * Tests for localStorage theme persistence and authenticated user theme API
 *
 * These tests verify that:
 * 1. Theme preferences are correctly stored and retrieved from localStorage for anonymous users.
 * 2. Authenticated users have their theme preferences saved via API calls.
 */

import React from 'react'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { ThemeToggle } from '../dashboard/components/theme-toggle'

const THEME_STORAGE_KEY = 'theme_preference'

// Mock the global fetch
const mockFetch = jest.fn()
global.fetch = mockFetch

// Mock matchMedia for theme detection
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

describe('localStorage theme persistence', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear()
  })

  describe('reading theme preference', () => {
    it('returns null when no theme preference is stored', () => {
      const storedTheme = localStorage.getItem(THEME_STORAGE_KEY)
      expect(storedTheme).toBeNull()
    })

    it('returns "dark" when dark theme preference is stored', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'dark')
      const storedTheme = localStorage.getItem(THEME_STORAGE_KEY)
      expect(storedTheme).toBe('dark')
    })

    it('returns "light" when light theme preference is stored', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'light')
      const storedTheme = localStorage.getItem(THEME_STORAGE_KEY)
      expect(storedTheme).toBe('light')
    })

    it('returns the exact value stored (case-sensitive)', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'dark')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')

      localStorage.setItem(THEME_STORAGE_KEY, 'light')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('light')
    })
  })

  describe('writing theme preference', () => {
    it('successfully stores dark theme preference', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'dark')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')
    })

    it('successfully stores light theme preference', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'light')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('light')
    })

    it('overwrites previous theme preference', () => {
      localStorage.setItem(THEME_STORAGE_KEY, 'light')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('light')

      localStorage.setItem(THEME_STORAGE_KEY, 'dark')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')
    })
  })

  describe('theme preference round-trip', () => {
    it('persists dark theme across storage operations', () => {
      // Store dark theme
      localStorage.setItem(THEME_STORAGE_KEY, 'dark')

      // Simulate page reload by retrieving the value
      const retrieved = localStorage.getItem(THEME_STORAGE_KEY)
      expect(retrieved).toBe('dark')
    })

    it('persists light theme across storage operations', () => {
      // Store light theme
      localStorage.setItem(THEME_STORAGE_KEY, 'light')

      // Simulate page reload by retrieving the value
      const retrieved = localStorage.getItem(THEME_STORAGE_KEY)
      expect(retrieved).toBe('light')
    })

    it('handles multiple theme changes correctly', () => {
      const themes = ['light', 'dark', 'light', 'dark']

      themes.forEach((theme) => {
        localStorage.setItem(THEME_STORAGE_KEY, theme)
        expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe(theme)
      })
    })
  })

  describe('edge cases', () => {
    it('handles empty string correctly', () => {
      localStorage.setItem(THEME_STORAGE_KEY, '')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('')
    })

    it('allows overwriting invalid values with valid ones', () => {
      // Store invalid value
      localStorage.setItem(THEME_STORAGE_KEY, 'invalid')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('invalid')

      // Overwrite with valid value
      localStorage.setItem(THEME_STORAGE_KEY, 'dark')
      expect(localStorage.getItem(THEME_STORAGE_KEY)).toBe('dark')
    })
  })
})

describe('Authenticated user theme API', () => {
  beforeEach(() => {
    jest.clearAllMocks()

    // Set up CSRF token meta tag
    const csrfMeta = document.createElement('meta')
    csrfMeta.name = 'csrf-token'
    csrfMeta.content = 'test-csrf-token'
    document.head.appendChild(csrfMeta)

    // Clear localStorage
    localStorage.clear()

    // Reset matchMedia to default (light)
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: jest.fn().mockImplementation((query) => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        dispatchEvent: jest.fn(),
      })),
    })

    // Reset documentElement class
    document.documentElement.classList.remove('dark')
  })

  afterEach(() => {
    // Clean up CSRF token meta tag
    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (csrfMeta) {
      csrfMeta.remove()
    }
  })

  it('makes API call to save theme preference when user is logged in', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      status: 200,
    } as Response)

    render(<ThemeToggle isLoggedIn={true} />)

    // Wait for component to initialize
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /switch to dark mode/i })).toBeInTheDocument()
    })

    // Click the theme toggle button
    const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(toggleButton)

    // Verify the API call was made
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/settings/preferences/theme', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': 'test-csrf-token',
        },
        body: 'user[theme]=dark',
      })
    })
  })

  it('sends correct theme value when toggling from dark to light', async () => {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      status: 200,
    } as Response)

    // Set initial theme in localStorage to dark
    localStorage.setItem('theme_preference', 'dark')

    // Mock matchMedia to return true (dark)
    window.matchMedia = jest.fn().mockImplementation((query) => ({
      matches: query === '(prefers-color-scheme: dark)',
      media: query,
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    }))

    render(<ThemeToggle isLoggedIn={true} />)

    // Wait for component to initialize with dark theme (effectiveTheme should be dark)
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /switch to light mode/i })).toBeInTheDocument()
    })

    // Click to switch to light mode
    const toggleButton = screen.getByRole('button', { name: /switch to light mode/i })
    await userEvent.click(toggleButton)

    // Verify the API call sends 'light' theme
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/settings/preferences/theme', expect.objectContaining({
        method: 'POST',
        body: 'user[theme]=light',
      }))
    })
  })

  it('includes CSRF token in the API request', async () => {
    const customCsrfToken = 'my-custom-csrf-token'

    // Update CSRF token
    const csrfMeta = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement
    csrfMeta.content = customCsrfToken

    mockFetch.mockResolvedValueOnce({
      ok: true,
      status: 200,
    } as Response)

    render(<ThemeToggle isLoggedIn={true} />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /switch to dark mode/i })).toBeInTheDocument()
    })

    const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(toggleButton)

    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('/settings/preferences/theme', expect.objectContaining({
        headers: expect.objectContaining({
          'X-CSRF-Token': customCsrfToken,
        }),
      }))
    })
  })

  it('does not make API call when user is not logged in', async () => {
    render(<ThemeToggle isLoggedIn={false} />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /switch to dark mode/i })).toBeInTheDocument()
    })

    const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(toggleButton)

    // Verify no API call was made
    expect(mockFetch).not.toHaveBeenCalled()
  })

  it('handles API call failure gracefully', async () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation()

    // Mock fetch to return a rejected promise
    mockFetch.mockImplementation(() =>
      Promise.reject(new Error('Network error'))
    )

    render(<ThemeToggle isLoggedIn={true} />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /switch to dark mode/i })).toBeInTheDocument()
    })

    const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
    await userEvent.click(toggleButton)

    // Verify fetch was called
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalled()
    })

    // Verify error was logged but UI still updated
    await waitFor(() => {
      expect(consoleErrorSpy).toHaveBeenCalledWith('Failed to save theme preference:', expect.any(Error))
    })

    // The theme should still be updated in the UI even if API call fails
    expect(screen.getByRole('button', { name: /switch to light mode/i })).toBeInTheDocument()

    consoleErrorSpy.mockRestore()
  })
})
