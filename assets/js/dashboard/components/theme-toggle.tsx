import { SunIcon, MoonIcon } from '@heroicons/react/24/outline'
import React, { useEffect, useState } from 'react'

interface ThemeToggleProps {
  isLoggedIn?: boolean
}

export function ThemeToggle({ isLoggedIn = false }: ThemeToggleProps) {
  const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system')
  const [effectiveTheme, setEffectiveTheme] = useState<'light' | 'dark'>('light')

  useEffect(() => {
    // Get initial theme from localStorage or default to system
    const storedTheme = localStorage.getItem('theme_preference') as 'light' | 'dark' | 'system' | null
    const initialTheme = storedTheme || 'system'
    setTheme(initialTheme)
    updateEffectiveTheme(initialTheme)
  }, [])

  useEffect(() => {
    // Listen for system theme changes
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    const handleChange = () => {
      if (theme === 'system') {
        updateEffectiveTheme('system')
      }
    }

    mediaQuery.addEventListener('change', handleChange)
    return () => mediaQuery.removeEventListener('change', handleChange)
  }, [theme])

  const updateEffectiveTheme = (themePreference: 'light' | 'dark' | 'system') => {
    let effective: 'light' | 'dark'

    if (themePreference === 'system') {
      effective = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    } else {
      effective = themePreference
    }

    setEffectiveTheme(effective)

    // Apply theme to document
    const html = document.querySelector('html')
    if (html) {
      if (effective === 'dark') {
        html.classList.add('dark')
      } else {
        html.classList.remove('dark')
      }
    }
  }

  const toggleTheme = async () => {
    const newTheme = effectiveTheme === 'light' ? 'dark' : 'light'
    setTheme(newTheme)
    updateEffectiveTheme(newTheme)

    // Persist theme preference
    if (isLoggedIn) {
      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        await fetch('/settings/preferences/theme', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'X-CSRF-Token': csrfToken || '',
          },
          body: `user[theme]=${newTheme}`,
        })
      } catch (error) {
        console.error('Failed to save theme preference:', error)
      }
    } else {
      // For anonymous users, use localStorage
      try {
        localStorage.setItem('theme_preference', newTheme)
      } catch (error) {
        // localStorage might be unavailable (private browsing, etc.)
        console.warn('Could not save theme to localStorage:', error)
      }
    }
  }

  return (
    <button
      onClick={toggleTheme}
      className="relative p-2 rounded-md transition-colors duration-150 hover:bg-gray-100 dark:hover:bg-gray-800 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 dark:focus-visible:ring-offset-gray-900"
      aria-label={`Switch to ${effectiveTheme === 'light' ? 'dark' : 'light'} mode`}
      title={`Switch to ${effectiveTheme === 'light' ? 'dark' : 'light'} mode`}
    >
      {effectiveTheme === 'light' ? (
        <MoonIcon className="w-5 h-5 text-gray-700 dark:text-gray-300" />
      ) : (
        <SunIcon className="w-5 h-5 text-gray-700 dark:text-gray-300" />
      )}
    </button>
  )
}

export default ThemeToggle
