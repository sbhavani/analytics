import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import ThemeContextProvider, { useTheme, UIMode } from './theme-context'

function TestConsumer() {
  const { mode, setMode, toggleMode } = useTheme()

  return (
    <div>
      <span data-testid="mode">{mode}</span>
      <button data-testid="set-dark" onClick={() => setMode(UIMode.dark)}>
        Set Dark
      </button>
      <button data-testid="set-light" onClick={() => setMode(UIMode.light)}>
        Set Light
      </button>
      <button data-testid="toggle" onClick={toggleMode}>
        Toggle
      </button>
    </div>
  )
}

describe('ThemeContext localStorage persistence', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear()
    // Reset html element to default state
    document.documentElement.classList.remove('dark')
  })

  it('saves theme preference to localStorage when setMode is called with dark', () => {
    render(
      <ThemeContextProvider>
        <TestConsumer />
      </ThemeContextProvider>
    )

    fireEvent.click(screen.getByTestId('set-dark'))

    expect(localStorage.getItem('theme_preference')).toBe('dark')
  })

  it('saves theme preference to localStorage when setMode is called with light', () => {
    // Start with dark mode to ensure we can switch to light
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <TestConsumer />
      </ThemeContextProvider>
    )

    fireEvent.click(screen.getByTestId('set-light'))

    expect(localStorage.getItem('theme_preference')).toBe('light')
  })

  it('saves theme preference to localStorage when toggleMode is called', () => {
    render(
      <ThemeContextProvider>
        <TestConsumer />
      </ThemeContextProvider>
    )

    // Initially light mode, toggle should make it dark
    fireEvent.click(screen.getByTestId('toggle'))

    expect(localStorage.getItem('theme_preference')).toBe('dark')
  })

  it('persists dark theme across toggle cycles', () => {
    render(
      <ThemeContextProvider>
        <TestConsumer />
      </ThemeContextProvider>
    )

    // Toggle to dark
    fireEvent.click(screen.getByTestId('toggle'))
    expect(localStorage.getItem('theme_preference')).toBe('dark')

    // Toggle back to light
    fireEvent.click(screen.getByTestId('toggle'))
    expect(localStorage.getItem('theme_preference')).toBe('light')

    // Toggle to dark again
    fireEvent.click(screen.getByTestId('toggle'))
    expect(localStorage.getItem('theme_preference')).toBe('dark')
  })

  it('updates the DOM to reflect theme changes', () => {
    render(
      <ThemeContextProvider>
        <TestConsumer />
      </ThemeContextProvider>
    )

    expect(document.documentElement.classList.contains('dark')).toBe(false)

    fireEvent.click(screen.getByTestId('set-dark'))

    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })
})
