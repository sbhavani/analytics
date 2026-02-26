import React, {
  createContext,
  ReactNode,
  useCallback,
  useContext,
  useLayoutEffect,
  useRef,
  useState
} from 'react'

export enum UIMode {
  light = 'light',
  dark = 'dark'
}

interface ThemeContextValue {
  mode: UIMode
  setMode: (mode: UIMode) => void
  toggleMode: () => void
}

const defaultValue: ThemeContextValue = {
  mode: UIMode.light,
   
  setMode: () => {},
   
  toggleMode: () => {}
}

export const ThemeContext = createContext(defaultValue)

function parseUIMode(element: Element | null): UIMode {
  return element?.classList.contains('dark') ? UIMode.dark : UIMode.light
}

function getInitialMode(): UIMode {
  // First check localStorage for user preference
  const stored = localStorage.getItem('theme_preference')
  if (stored === UIMode.dark || stored === UIMode.light) {
    return stored
  }

  // Fall back to checking the HTML element (may have server-side or system preference)
  return parseUIMode(document.querySelector('html'))
}

export default function ThemeContextProvider({
  children
}: {
  children: ReactNode
}) {
  const observerRef = useRef<MutationObserver | null>(null)
  const [mode, setModeState] = useState<UIMode>(getInitialMode)

  const setMode = useCallback((newMode: UIMode) => {
    const htmlElement = document.querySelector('html')
    if (htmlElement) {
      if (newMode === UIMode.dark) {
        htmlElement.classList.add('dark')
      } else {
        htmlElement.classList.remove('dark')
      }
    }
    setModeState(newMode)

    // Persist to localStorage for immediate UI state
    localStorage.setItem('theme_preference', newMode)

    // Sync to backend API
    const csrfToken = document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content')

    if (csrfToken) {
      fetch('/preferences/theme', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'CSRF-Token': csrfToken
        },
        body: `user[theme]=${newMode}`,
        credentials: 'include'
      }).catch((err) => {
        console.error('Failed to save theme preference:', err)
      })
    }
  }, [])

  const toggleMode = useCallback(() => {
    const newMode = mode === UIMode.light ? UIMode.dark : UIMode.light
    setMode(newMode)
  }, [mode, setMode])

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
            return setModeState(parseUIMode(mutation.target as Element))
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

  return (
    <ThemeContext.Provider value={{ mode, setMode, toggleMode }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  return useContext(ThemeContext)
}
