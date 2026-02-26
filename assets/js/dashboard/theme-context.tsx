import React, {
  createContext,
  ReactNode,
  useContext,
  useLayoutEffect,
  useRef,
  useState
} from 'react'
import { setItem, getItem } from './util/storage'

export enum UIMode {
  light = 'light',
  dark = 'dark'
}

const THEME_STORAGE_KEY = 'theme_preference'

function getInitialMode(): UIMode {
  // First check localStorage for saved preference
  const savedPreference = getItem(THEME_STORAGE_KEY)
  if (savedPreference === 'light' || savedPreference === 'dark') {
    return savedPreference
  }

  // Then check system preference
  if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
    return UIMode.dark
  }

  // Default to light
  return UIMode.light
}

function applyTheme(mode: UIMode): void {
  const htmlElement = document.querySelector('html')
  if (htmlElement) {
    if (mode === UIMode.dark) {
      htmlElement.classList.add('dark')
    } else {
      htmlElement.classList.remove('dark')
    }
  }
}

const defaultValue = { mode: UIMode.light }

const ThemeContext = createContext(defaultValue)

function parseUIMode(element: Element | null): UIMode {
  return element?.classList.contains('dark') ? UIMode.dark : UIMode.light
}

interface ThemeContextValue {
  mode: UIMode
  toggleTheme: () => void
}

export default function ThemeContextProvider({
  children
}: {
  children: ReactNode
}) {
  const observerRef = useRef<MutationObserver | null>(null)
  const [mode, setMode] = useState<UIMode>(getInitialMode)

  // Listen for system preference changes in real-time
  useLayoutEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = (e: MediaQueryListEvent) => {
      // Only auto-switch if user hasn't set a manual preference
      const savedPreference = getItem(THEME_STORAGE_KEY)
      if (!savedPreference) {
        const newMode = e.matches ? UIMode.dark : UIMode.light
        setMode(newMode)
        applyTheme(newMode)
      }
    }

    mediaQuery.addEventListener('change', handleChange)
    return () => mediaQuery.removeEventListener('change', handleChange)
  }, [])

  // Apply theme on mount
  useLayoutEffect(() => {
    applyTheme(mode)
  }, [mode])

  // Listen for system preference changes
  useLayoutEffect(() => {
    const htmlElement = document.querySelector('html')
    const currentObserver = observerRef.current
    if (htmlElement && !currentObserver) {
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (
            mutation.type === 'attributes' &&
            mutation.attributeName === 'class'
          ) {
            return setMode(parseUIMode(mutation.target as Element))
          }
        })
      })
      observerRef.current = observer
      observer.observe(htmlElement, {
        attributes: true,
        attributeFilter: ['class']
      })
    }
    return () => currentObserver?.disconnect()
  }, [])

  const toggleTheme = () => {
    const newMode = mode === UIMode.light ? UIMode.dark : UIMode.light
    setMode(newMode)
    applyTheme(newMode)
    setItem(THEME_STORAGE_KEY, newMode)
  }

  const value: ThemeContextValue = { mode, toggleTheme }

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  )
}

export function useTheme() {
  return useContext(ThemeContext) as ThemeContextValue
}
