import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { ThemeToggle } from '../dashboard/components/theme-toggle'
import '@testing-library/jest-dom'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value
    },
    clear: () => {
      store = {}
    },
    removeItem: (key: string) => {
      delete store[key]
    },
  }
})()

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
})

// Mock matchMedia
const mockMatchMedia = (matches: boolean) => {
  return jest.fn().mockImplementation((query: string) => ({
    matches: query === '(prefers-color-scheme: dark)' ? matches : false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  }))
}

describe('ThemeToggle', () => {
  beforeEach(() => {
    localStorage.clear()
    jest.clearAllMocks()

    // Set up default mock for matchMedia - defaults to light mode
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    // Mock document.querySelector for html element
    const mockHtmlElement = {
      classList: {
        add: jest.fn(),
        remove: jest.fn(),
      },
    }
    jest.spyOn(document, 'querySelector').mockImplementation((selector: string) => {
      if (selector === 'html') {
        return mockHtmlElement as unknown as Element
      }
      if (selector === 'meta[name="csrf-token"]') {
        return { getAttribute: () => 'test-csrf-token' } as unknown as Element
      }
      return null
    })
  })

  it('renders theme toggle button', () => {
    render(<ThemeToggle />)

    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    expect(button).toBeInTheDocument()
  })

  it('shows moon icon when light theme is active', () => {
    // Set up light mode preference
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    render(<ThemeToggle />)

    // Button should show moon icon (to switch to dark)
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    expect(button).toBeInTheDocument()
  })

  it('shows sun icon when dark theme is active', () => {
    // Set up dark mode preference in localStorage
    localStorage.setItem('theme_preference', 'dark')
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(true),
      writable: true,
    })

    render(<ThemeToggle isLoggedIn={false} />)

    // Button should show sun icon (to switch to light)
    const button = screen.getByRole('button', { name: /switch to light mode/i })
    expect(button).toBeInTheDocument()
  })

  it('toggles from light to dark when clicked', async () => {
    // Initial state: light mode
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    const { rerender } = render(<ThemeToggle isLoggedIn={false} />)

    // Click to toggle to dark
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    fireEvent.click(button)

    // After click, should show sun icon (switch to light mode)
    rerender(<ThemeToggle isLoggedIn={false} />)

    const darkButton = screen.getByRole('button', { name: /switch to light mode/i })
    expect(darkButton).toBeInTheDocument()
  })

  it('toggles from dark to light when clicked', () => {
    // Initial state: dark mode
    localStorage.setItem('theme_preference', 'dark')
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(true),
      writable: true,
    })

    render(<ThemeToggle isLoggedIn={false} />)

    // Click to toggle to light
    const button = screen.getByRole('button', { name: /switch to light mode/i })
    fireEvent.click(button)

    // After click, should show moon icon (switch to dark mode)
    const lightButton = screen.getByRole('button', { name: /switch to dark mode/i })
    expect(lightButton).toBeInTheDocument()
  })

  it('adds dark class to html element when dark theme is applied', () => {
    // Initial state: light mode
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    const mockHtmlElement = {
      classList: {
        add: jest.fn(),
        remove: jest.fn(),
      },
    }
    jest.spyOn(document, 'querySelector').mockImplementation((selector: string) => {
      if (selector === 'html') {
        return mockHtmlElement as unknown as Element
      }
      return null
    })

    render(<ThemeToggle isLoggedIn={false} />)

    // Click to toggle to dark
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    fireEvent.click(button)

    // Verify dark class was added
    expect(mockHtmlElement.classList.add).toHaveBeenCalledWith('dark')
  })

  it('removes dark class from html element when light theme is applied', () => {
    // Initial state: dark mode
    localStorage.setItem('theme_preference', 'dark')
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(true),
      writable: true,
    })

    const mockHtmlElement = {
      classList: {
        add: jest.fn(),
        remove: jest.fn(),
      },
    }
    jest.spyOn(document, 'querySelector').mockImplementation((selector: string) => {
      if (selector === 'html') {
        return mockHtmlElement as unknown as Element
      }
      return null
    })

    render(<ThemeToggle isLoggedIn={false} />)

    // Click to toggle to light
    const button = screen.getByRole('button', { name: /switch to light mode/i })
    fireEvent.click(button)

    // Verify dark class was removed
    expect(mockHtmlElement.classList.remove).toHaveBeenCalledWith('dark')
  })

  it('persists theme preference to localStorage for anonymous users', async () => {
    // Mock fetch to prevent actual API call
    global.fetch = jest.fn().mockResolvedValue({ ok: true })

    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    render(<ThemeToggle isLoggedIn={false} />)

    // Verify localStorage is empty initially
    expect(localStorage.getItem('theme_preference')).toBeNull()

    // Click to toggle to dark
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await fireEvent.click(button)

    // Verify localStorage was updated
    expect(localStorage.getItem('theme_preference')).toBe('dark')
  })

  it('calls API to persist theme for logged-in users', async () => {
    const mockFetch = jest.fn().mockResolvedValue({ ok: true })
    global.fetch = mockFetch

    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(false),
      writable: true,
    })

    render(<ThemeToggle isLoggedIn={true} />)

    // Click to toggle to dark
    const button = screen.getByRole('button', { name: /switch to dark mode/i })
    await fireEvent.click(button)

    // Verify fetch was called for logged-in user
    expect(mockFetch).toHaveBeenCalledWith(
      '/settings/preferences/theme',
      expect.objectContaining({
        method: 'POST',
        body: 'user[theme]=dark',
      })
    )
  })

  it('uses system preference when no stored theme exists', () => {
    // Ensure localStorage has no theme
    localStorage.clear()

    // Set up system preference for dark mode
    Object.defineProperty(window, 'matchMedia', {
      value: mockMatchMedia(true),
      writable: true,
    })

    render(<ThemeToggle />)

    // Should show sun icon because system prefers dark (so toggle shows light)
    const button = screen.getByRole('button', { name: /switch to light mode/i })
    expect(button).toBeInTheDocument()
  })
})
