import React, { useState, useCallback, useRef, useEffect } from 'react'
import { validateSegmentName, sanitizeSegmentName } from './filter-utils'
import type { FilterRoot } from './types'

interface SaveSegmentModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string) => Promise<void>
  filterRoot?: FilterRoot
  isValid?: boolean
}

export function SaveSegmentModal({
  isOpen,
  onClose,
  onSave,
  filterRoot,
  isValid = true
}: SaveSegmentModalProps) {
  const [segmentName, setSegmentName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  // Focus input when modal opens
  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus()
    }
  }, [isOpen])

  // Reset state when modal closes
  useEffect(() => {
    if (!isOpen) {
      setSegmentName('')
      setError(null)
      setIsLoading(false)
    }
  }, [isOpen])

  const handleSave = useCallback(async () => {
    const validation = validateSegmentName(segmentName)
    if (!validation.isValid) {
      setError(validation.error || 'Invalid segment name')
      return
    }

    if (!isValid) {
      setError('Please fix filter errors before saving')
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const sanitizedName = sanitizeSegmentName(segmentName)
      await onSave(sanitizedName)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save segment')
    } finally {
      setIsLoading(false)
    }
  }, [segmentName, isValid, onSave, onClose])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSave()
    } else if (e.key === 'Escape') {
      onClose()
    }
  }, [handleSave, onClose])

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setSegmentName(e.target.value)
    // Clear error when user starts typing
    if (error) {
      setError(null)
    }
  }, [error])

  if (!isOpen) return null

  const canSave = segmentName.trim().length > 0 && isValid && !isLoading

  return (
    <div
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      onClick={(e) => {
        // Close on backdrop click
        if (e.target === e.currentTarget) {
          onClose()
        }
      }}
    >
      <div
        className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md mx-4 overflow-hidden"
        onKeyDown={handleKeyDown}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
            Save Segment
          </h3>
          <button
            onClick={onClose}
            className="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
            aria-label="Close"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Body */}
        <div className="px-6 py-4">
          <label
            htmlFor="segment-name"
            className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
          >
            Segment Name
          </label>
          <input
            ref={inputRef}
            id="segment-name"
            type="text"
            value={segmentName}
            onChange={handleInputChange}
            placeholder="Enter a name for this segment..."
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-gray-100 placeholder-gray-400"
            maxLength={255}
          />
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            Max 255 characters. Special characters will be removed.
          </p>

          {/* Error message */}
          {error && (
            <div className="mt-3 p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
              <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
            </div>
          )}

          {/* Filter summary */}
          {filterRoot && (
            <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-md">
              <p className="text-xs text-gray-500 dark:text-gray-400">
                This segment will save {filterRoot.conditions.length} condition(s) and {filterRoot.groups.length} group(s).
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 px-6 py-4 bg-gray-50 dark:bg-gray-800/50 border-t border-gray-200 dark:border-gray-700">
          <button
            onClick={onClose}
            disabled={isLoading}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={!canSave}
            className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                    fill="none"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
                Saving...
              </span>
            ) : (
              'Save Segment'
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

export default SaveSegmentModal
