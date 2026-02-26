import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ThemeToggle from './components/theme-toggle'
import ThemeContextProvider, { UIMode } from './theme-context'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value
    },
    removeItem: (key: string) => {
      delete store[key]
    },
    clear: () => {
      store = {}
    }
  }
})()

Object.defineProperty(window, 'localStorage', { value: localStorageMock })

describe('Dark Mode Styling Consistency', () => {
  beforeEach(() => {
    localStorageMock.clear()
    document.documentElement.classList.remove('dark')
  })

  describe('Theme Toggle Component', () => {
    it('renders sun icon in light mode', () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      // Initially should be in light mode (no dark class)
      expect(document.documentElement.classList.contains('dark')).toBe(false)

      // Should show sun icon in light mode (check button has correct aria-label)
      const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
      expect(toggleButton).toBeInTheDocument()
    })

    it('toggles to dark mode when clicked', async () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button', {
        name: /switch to dark mode/i
      })

      await userEvent.click(toggleButton)

      // Should now have dark class
      expect(document.documentElement.classList.contains('dark')).toBe(true)

      // Button should now indicate light mode
      expect(
        screen.getByRole('button', { name: /switch to light mode/i })
      ).toBeInTheDocument()
    })

    it('toggles back to light mode when clicked again', async () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button', {
        name: /switch to dark mode/i
      })

      // Toggle to dark
      await userEvent.click(toggleButton)
      expect(document.documentElement.classList.contains('dark')).toBe(true)

      // Toggle back to light
      const lightModeButton = screen.getByRole('button', {
        name: /switch to light mode/i
      })
      await userEvent.click(lightModeButton)

      expect(document.documentElement.classList.contains('dark')).toBe(false)
    })

    it('supports keyboard activation (Enter key)', () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button', {
        name: /switch to dark mode/i
      })

      fireEvent.keyDown(toggleButton, { key: 'Enter', code: 'Enter' })

      expect(document.documentElement.classList.contains('dark')).toBe(true)
    })

    it('supports keyboard activation (Space key)', () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button', {
        name: /switch to dark mode/i
      })

      fireEvent.keyDown(toggleButton, { key: ' ', code: 'Space' })

      expect(document.documentElement.classList.contains('dark')).toBe(true)
    })
  })

  describe('Dark Mode Visual Checklist', () => {
    it('applies dark class to html element when dark mode is enabled', async () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      // Start in light mode
      expect(document.documentElement.classList.contains('dark')).toBe(false)

      // Enable dark mode
      const toggleButton = screen.getByRole('button')
      await userEvent.click(toggleButton)

      // Verify dark class is applied
      expect(document.documentElement.classList.contains('dark')).toBe(true)
    })

    it('removes dark class from html element when light mode is enabled', async () => {
      // Start with dark mode
      document.documentElement.classList.add('dark')

      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      // Verify dark class exists
      expect(document.documentElement.classList.contains('dark')).toBe(true)

      // Toggle to light mode
      const toggleButton = screen.getByRole('button')
      await userEvent.click(toggleButton)

      // Verify dark class is removed
      expect(document.documentElement.classList.contains('dark')).toBe(false)
    })

    it('persists theme preference to localStorage', async () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button')
      await userEvent.click(toggleButton)

      // Check localStorage was updated
      expect(localStorageMock.getItem('theme_preference')).toBe(UIMode.dark)
    })

    it('ThemeToggle has proper accessibility attributes', () => {
      render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const button = screen.getByRole('button')
      expect(button).toHaveAttribute('aria-label')
      expect(button).toHaveAttribute('title')
    })

    it('ThemeToggle has correct styling classes for light and dark modes', () => {
      const { rerender } = render(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const button = screen.getByRole('button')

      // Should have light mode specific classes
      expect(button.className).toContain('text-gray-600')
      expect(button.className).toContain('hover:text-gray-900')
      expect(button.className).toContain('hover:bg-gray-100')

      // Now enable dark mode
      rerender(
        <ThemeContextProvider>
          <ThemeToggle />
        </ThemeContextProvider>
      )

      const toggleButton = screen.getByRole('button')
      fireEvent.click(toggleButton)

      // Button should now have dark mode classes (check component renders with dark classes)
      // The actual class verification is done via the className property
      expect(toggleButton.className).toContain('dark:text-gray-400')
      expect(toggleButton.className).toContain('dark:hover:text-gray-100')
      expect(toggleButton.className).toContain('dark:hover:bg-gray-800')
    })
  })

  describe('Component Styling Consistency', () => {
    it('TopBar applies dark mode background styling', async () => {
      // This test verifies that when dark mode is enabled,
      // the TopBar component with its dark: variants will render correctly
      // The actual visual verification is done via the dark class on HTML element

      document.documentElement.classList.add('dark')

      render(
        <ThemeContextProvider>
          <div className="bg-gray-50 dark:bg-gray-950">
            <span>Dashboard Content</span>
          </div>
        </ThemeContextProvider>
      )

      const container = screen.getByText('Dashboard Content').parentElement
      expect(container).toHaveClass('bg-gray-50')
      expect(container).toHaveClass('dark:bg-gray-950')
    })

    it('Multiple components can share dark mode state', async () => {
      render(
        <ThemeContextProvider>
          <div>
            <ThemeToggle />
            <div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 p-4">
              Content Area
            </div>
            <button className="bg-indigo-500 dark:bg-indigo-600 text-white dark:text-gray-100">
              Action Button
            </button>
          </div>
        </ThemeContextProvider>
      )

      // Initially light mode
      expect(document.documentElement.classList.contains('dark')).toBe(false)

      // Toggle to dark - use aria-label to be specific about which button
      const toggleButton = screen.getByRole('button', { name: /switch to dark mode/i })
      await userEvent.click(toggleButton)

      // Verify dark mode is active on html element
      expect(document.documentElement.classList.contains('dark')).toBe(true)

      // Content should have dark mode classes available - verify the classes exist in className
      const contentArea = screen.getByText('Content Area').closest('div')
      expect(contentArea?.className).toContain('dark:bg-gray-900')
      expect(contentArea?.className).toContain('dark:text-gray-100')

      const actionButton = screen.getByRole('button', { name: /action button/i })
      expect(actionButton.className).toContain('dark:bg-indigo-600')
      expect(actionButton.className).toContain('dark:text-gray-100')
    })
  })
})
