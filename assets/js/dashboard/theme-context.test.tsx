import React from 'react'
import { render, screen, act, waitFor } from '@testing-library/react'
import ThemeContextProvider, { useTheme, UIMode } from './theme-context'

function TestComponent() {
  const { mode } = useTheme()

  return <div data-testid="theme-mode">{mode}</div>
}

describe('ThemeContext', () => {
  beforeEach(() => {
    // Reset the html element classList before each test
    document.documentElement.className = ''
  })

  it('provides light mode when html has no dark class', () => {
    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.light)
  })

  it('provides dark mode when html has dark class', () => {
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.dark)
  })

  it('updates mode when html class changes to dark', async () => {
    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.light)

    // Simulate class change to dark
    await act(async () => {
      document.documentElement.classList.add('dark')
      // Wait for mutation observer to fire
      await new Promise((resolve) => setTimeout(resolve, 100))
    })

    await waitFor(() => {
      expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.dark)
    })
  })

  it('updates mode when html class changes from dark to light', async () => {
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.dark)

    // Simulate class change to light
    await act(async () => {
      document.documentElement.classList.remove('dark')
      // Wait for mutation observer to fire
      await new Promise((resolve) => setTimeout(resolve, 100))
    })

    await waitFor(() => {
      expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.light)
    })
  })

  it('handles html without dark class (light mode)', () => {
    // Explicitly set no classes
    document.documentElement.className = ''

    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.light)
  })

  it('handles html with multiple classes including dark', () => {
    document.documentElement.className = 'dark theme-dark some-other-class'

    render(
      <ThemeContextProvider>
        <TestComponent />
      </ThemeContextProvider>
    )

    expect(screen.getByTestId('theme-mode').textContent).toBe(UIMode.dark)
  })
})

describe('UIMode enum', () => {
  it('has correct light value', () => {
    expect(UIMode.light).toBe('light')
  })

  it('has correct dark value', () => {
    expect(UIMode.dark).toBe('dark')
  })
})
