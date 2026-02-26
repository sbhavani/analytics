import React from 'react'
import { MoonIcon, SunIcon } from '@heroicons/react/24/outline'
import { useTheme, UIMode } from '../theme-context'

export default function ThemeToggle({
  className = ''
}: {
  className?: string
}) {
  const { mode, toggleMode } = useTheme()

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      toggleMode()
    }
  }

  const isDark = mode === UIMode.dark

  return (
    <button
      onClick={toggleMode}
      onKeyDown={handleKeyDown}
      className={`p-2 rounded-md text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100 hover:bg-gray-100 dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 transition-colors duration-200 ${className}`}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {isDark ? (
        <MoonIcon className="w-5 h-5" aria-hidden="true" />
      ) : (
        <SunIcon className="w-5 h-5" aria-hidden="true" />
      )}
    </button>
  )
}
