import React from 'react'
import { MoonIcon, SunIcon } from '@heroicons/react/24/outline'
import { useTheme, UIMode } from '../theme-context'

export default function ThemeToggle() {
  const { mode, toggleTheme } = useTheme()
  const isDark = mode === UIMode.dark

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      toggleTheme()
    }
  }

  return (
    <button
      onClick={toggleTheme}
      onKeyDown={handleKeyDown}
      className="relative inline-flex h-9 w-9 items-center justify-center rounded-md border border-gray-300 dark:border-gray-600 bg-transparent text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900"
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      role="switch"
      aria-checked={isDark}
      tabIndex={0}
    >
      <span className="sr-only">
        {isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      </span>
      {isDark ? (
        <MoonIcon className="h-5 w-5" />
      ) : (
        <SunIcon className="h-5 w-5" />
      )}
    </button>
  )
}
