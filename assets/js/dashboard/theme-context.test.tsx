import React from 'react'
import { render, screen, act } from '@testing-library/react'
import ThemeContextProvider, { useTheme, UIMode } from './theme-context'

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: jest.fn((key: string) => store[key] || null),
    setItem: jest.fn((key: string, value: string) => {
      store[key] = value
    }),
    clear: () => {
      store = {}
    }
  }
})()

Object.defineProperty(window, 'localStorage', { value: localStorageMock })

// Mock fetch
const fetchMock = jest.fn().mockResolvedValue({ ok: true })
beforeEach(() => {
  jest.clearAllMocks()
  fetchMock.mockResolvedValue({ ok: true })
})
Object.defineProperty(window, 'fetch', { value: fetchMock })

// Mock MutationObserver
class MockMutationObserver {
  observe = jest.fn()
  disconnect = jest.fn()
}
window.MutationObserver = MockMutationObserver as unknown as typeof MutationObserver

function TestComponent() {
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

describe('ThemeContext', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    localStorageMock.clear()
    document.querySelector('html')?.classList.remove('dark')
  })

  describe('initialization', () => {
    it('defaults to light mode when html has no dark class', () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      expect(screen.getByTestId('mode').textContent).toBe('light')
    })

    it('defaults to dark mode when html has dark class', () => {
      document.querySelector('html')?.classList.add('dark')

      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      expect(screen.getByTestId('mode').textContent).toBe('dark')
    })
  })

  describe('setMode', () => {
    it('adds dark class to html when setting dark mode', async () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      const htmlElement = document.querySelector('html')
      expect(htmlElement?.classList.contains('dark')).toBe(false)

      await act(async () => {
        screen.getByTestId('set-dark').click()
      })

      expect(htmlElement?.classList.contains('dark')).toBe(true)
    })

    it('removes dark class from html when setting light mode', () => {
      document.querySelector('html')?.classList.add('dark')

      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      const htmlElement = document.querySelector('html')
      expect(htmlElement?.classList.contains('dark')).toBe(true)

      act(() => {
        screen.getByTestId('set-light').click()
      })

      expect(htmlElement?.classList.contains('dark')).toBe(false)
    })

    it('saves theme preference to localStorage when setting mode', async () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      await act(async () => {
        screen.getByTestId('set-dark').click()
      })

      expect(localStorage.setItem).toHaveBeenCalledWith(
        'theme_preference',
        'dark'
      )
    })

    it('sends theme preference to backend API when CSRF token exists', async () => {
      // Mock CSRF token meta tag
      const csrfMeta = document.createElement('meta')
      csrfMeta.name = 'csrf-token'
      csrfMeta.content = 'test-csrf-token'
      document.head.appendChild(csrfMeta)

      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      await act(async () => {
        screen.getByTestId('set-dark').click()
      })

      expect(fetchMock).toHaveBeenCalledWith('/preferences/theme', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'CSRF-Token': 'test-csrf-token'
        },
        body: 'user[theme]=dark',
        credentials: 'include'
      })

      document.head.removeChild(csrfMeta)
    })

    it('does not call backend API when CSRF token is missing', async () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      await act(async () => {
        screen.getByTestId('set-dark').click()
      })

      expect(fetchMock).not.toHaveBeenCalled()
    })
  })

  describe('toggleMode', () => {
    it('toggles from light to dark', async () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      expect(screen.getByTestId('mode').textContent).toBe('light')

      await act(async () => {
        screen.getByTestId('toggle').click()
      })

      expect(screen.getByTestId('mode').textContent).toBe('dark')
    })

    it('toggles from dark to light', () => {
      document.querySelector('html')?.classList.add('dark')

      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      expect(screen.getByTestId('mode').textContent).toBe('dark')

      act(() => {
        screen.getByTestId('toggle').click()
      })

      expect(screen.getByTestId('mode').textContent).toBe('light')
    })
  })

  describe('useTheme hook', () => {
    it('provides mode, setMode, and toggleMode', () => {
      render(
        <ThemeContextProvider>
          <TestComponent />
        </ThemeContextProvider>
      )

      // All three should be present
      expect(screen.getByTestId('mode')).toBeInTheDocument()
      expect(screen.getByTestId('set-dark')).toBeInTheDocument()
      expect(screen.getByTestId('set-light')).toBeInTheDocument()
      expect(screen.getByTestId('toggle')).toBeInTheDocument()
    })
  })
})
