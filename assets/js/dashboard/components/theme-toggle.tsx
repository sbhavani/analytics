import React, { useState } from 'react'
import { SunIcon, MoonIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
import { useTheme, UIMode } from '../theme-context'

const THEME_STORAGE_KEY = 'theme_preference'

function setStoredTheme(theme: string): void {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, theme)
  } catch {
    // localStorage unavailable
  }
}

export function ThemeToggle({ className = '' }: { className?: string }) {
  const { mode } = useTheme()
  const [isLoading, setIsLoading] = useState(false)
  // Optimistic UI: track pending theme for instant visual feedback
  const [pendingMode, setPendingMode] = useState<UIMode | null>(null)

  // Use pending mode if available, otherwise use actual mode
  const displayMode = pendingMode ?? mode

  const toggleTheme = async () => {
    const newTheme = mode === UIMode.dark ? 'light' : 'dark'
    const newMode = newTheme === 'dark' ? UIMode.dark : UIMode.light

    // Optimistic update - immediately update local state for instant feedback
    setPendingMode(newMode)

    // Optimistic update - immediately update local state
    const htmlElement = document.querySelector('html')
    if (newTheme === 'dark') {
      htmlElement?.classList.add('dark')
    } else {
      htmlElement?.classList.remove('dark')
    }

    // Store locally first
    setStoredTheme(newTheme)

    // Then sync with backend
    setIsLoading(true)
    try {
      const response = await fetch('/settings/preferences/theme', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user: { theme: newTheme }
        }),
        credentials: 'same-origin'
      })

      if (!response.ok) {
        // Revert on failure
        const revertedTheme = mode === UIMode.dark ? 'light' : 'dark'
        if (revertedTheme === 'dark') {
          htmlElement?.classList.add('dark')
        } else {
          htmlElement?.classList.remove('dark')
        }
        setStoredTheme(revertedTheme)
        // Clear pending mode to revert UI
        setPendingMode(null)
        console.error('Failed to update theme preference')
      }
    } catch (error) {
      // Network error - localStorage already updated, that's good enough
      console.error('Error updating theme:', error)
    } finally {
      setIsLoading(false)
      // Clear pending mode - MutationObserver will sync with actual state
      setPendingMode(null)
    }
  }

  return (
    <button
      onClick={toggleTheme}
      disabled={isLoading}
      className={`relative p-2 rounded-md text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors ${className}`}
      aria-label={displayMode === UIMode.dark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={displayMode === UIMode.dark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {isLoading ? (
        <ArrowPathIcon className="w-5 h-5 animate-spin" />
      ) : displayMode === UIMode.dark ? (
        <SunIcon className="w-5 h-5" />
      ) : (
        <MoonIcon className="w-5 h-5" />
      )}
    </button>
  )
}
