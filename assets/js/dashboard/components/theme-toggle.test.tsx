import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ThemeToggle from '../components/theme-toggle'
import ThemeContextProvider, {
  UIMode,
  ThemeContext
} from '../theme-context'

describe('ThemeToggle', () => {
  beforeEach(() => {
    // Reset html class to light mode before each test
    document.documentElement.classList.remove('dark')
    localStorage.clear()
  })

  it('renders sun icon in light mode', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByLabelText('Switch to dark mode')).toBeInTheDocument()
    // SunIcon should be rendered in light mode
    const svg = document.querySelector('svg')
    expect(svg).toBeInTheDocument()
  })

  it('renders moon icon in dark mode', () => {
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByLabelText('Switch to light mode')).toBeInTheDocument()
  })

  it('calls toggleMode when clicked', async () => {
    const user = userEvent.setup()

    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    await user.click(button)

    // After clicking, mode should toggle to dark
    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  it('calls toggleMode when Enter key is pressed', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    fireEvent.keyDown(button, { key: 'Enter', code: 'Enter' })

    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  it('calls toggleMode when Space key is pressed', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    fireEvent.keyDown(button, { key: ' ', code: 'Space' })

    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  it('toggles theme on Enter key press', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    fireEvent.keyDown(button, { key: 'Enter', code: 'Enter' })

    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  it('toggles theme on Space key press', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    fireEvent.keyDown(button, { key: ' ', code: 'Space' })

    expect(document.documentElement.classList.contains('dark')).toBe(true)
  })

  it('applies custom className', () => {
    const customClass = 'my-custom-class'

    render(
      <ThemeContextProvider>
        <ThemeToggle className={customClass} />
      </ThemeContextProvider>
    )

    const button = screen.getByRole('button')
    expect(button).toHaveClass(customClass)
  })

  it('has correct aria-label for light mode', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByRole('button')).toHaveAttribute(
      'aria-label',
      'Switch to dark mode'
    )
  })

  it('has correct aria-label for dark mode', () => {
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByRole('button')).toHaveAttribute(
      'aria-label',
      'Switch to light mode'
    )
  })

  it('has correct title for light mode', () => {
    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByRole('button')).toHaveAttribute(
      'title',
      'Switch to dark mode'
    )
  })

  it('has correct title for dark mode', () => {
    document.documentElement.classList.add('dark')

    render(
      <ThemeContextProvider>
        <ThemeToggle />
      </ThemeContextProvider>
    )

    expect(screen.getByRole('button')).toHaveAttribute(
      'title',
      'Switch to light mode'
    )
  })
})

describe('ThemeToggle with mock context', () => {
  it('uses toggleMode from ThemeContext', () => {
    const mockToggleMode = jest.fn()

    const mockContextValue = {
      mode: UIMode.light,
      setMode: jest.fn(),
      toggleMode: mockToggleMode
    }

    render(
      <ThemeContext.Provider value={mockContextValue}>
        <ThemeToggle />
      </ThemeContext.Provider>
    )

    const button = screen.getByRole('button')
    fireEvent.click(button)

    expect(mockToggleMode).toHaveBeenCalledTimes(1)
  })

  it('displays correct icon based on mode from context', () => {
    const mockContextValue = {
      mode: UIMode.dark,
      setMode: jest.fn(),
      toggleMode: jest.fn()
    }

    render(
      <ThemeContext.Provider value={mockContextValue}>
        <ThemeToggle />
      </ThemeContext.Provider>
    )

    expect(screen.getByLabelText('Switch to light mode')).toBeInTheDocument()
  })
})
