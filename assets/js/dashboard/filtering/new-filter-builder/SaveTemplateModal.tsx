import React, { useState, useCallback } from 'react'
import { XMarkIcon } from '@heroicons/react/24/outline'

interface SaveTemplateModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string) => void
  filterSummary?: string
}

export function SaveTemplateModal({
  isOpen,
  onClose,
  onSave,
  filterSummary
}: SaveTemplateModalProps) {
  const [name, setName] = useState('')
  const [error, setError] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  const handleSave = useCallback(() => {
    const trimmedName = name.trim()

    if (!trimmedName) {
      setError('Please enter a segment name')
      return
    }

    if (trimmedName.length > 100) {
      setError('Segment name must be 100 characters or less')
      return
    }

    setIsSaving(true)
    try {
      onSave(trimmedName)
      setName('')
      setError('')
      onClose()
    } finally {
      setIsSaving(false)
    }
  }, [name, onSave, onClose])

  const handleCancel = useCallback(() => {
    setName('')
    setError('')
    onClose()
  }, [onClose])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSave()
    } else if (e.key === 'Escape') {
      handleCancel()
    }
  }, [handleSave, handleCancel])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
        onClick={handleCancel}
        aria-hidden="true"
      />

      {/* Modal */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div
          className="relative w-full max-w-md bg-white rounded-lg shadow-xl"
          role="dialog"
          aria-modal="true"
          aria-labelledby="save-modal-title"
          onKeyDown={handleKeyDown}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
            <h3
              id="save-modal-title"
              className="text-lg font-semibold text-gray-900"
            >
              Save Segment
            </h3>
            <button
              type="button"
              onClick={handleCancel}
              className="text-gray-400 hover:text-gray-500"
              aria-label="Close"
            >
              <XMarkIcon className="h-5 w-5" />
            </button>
          </div>

          {/* Body */}
          <div className="px-6 py-4">
            <label
              htmlFor="segment-name"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Segment Name
            </label>
            <input
              id="segment-name"
              type="text"
              value={name}
              onChange={(e) => {
                setName(e.target.value)
                if (error) setError('')
              }}
              placeholder="e.g., High-Value US Users"
              className={`
                w-full px-3 py-2 border rounded-md shadow-sm
                focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500
                ${error
                  ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                  : 'border-gray-300'
                }
              `}
              autoFocus
            />
            {error && (
              <p className="mt-2 text-sm text-red-600">{error}</p>
            )}

            {/* Filter preview */}
            {filterSummary && (
              <div className="mt-4 p-3 bg-gray-50 rounded-md">
                <p className="text-xs text-gray-500 mb-1">Filter:</p>
                <p className="text-sm text-gray-700 line-clamp-2">{filterSummary}</p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50 rounded-b-lg">
            <button
              type="button"
              onClick={handleCancel}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={isSaving || !name.trim()}
              className={`
                px-4 py-2 text-sm font-medium rounded-md
                ${name.trim()
                  ? 'text-white bg-indigo-600 hover:bg-indigo-700'
                  : 'text-gray-400 bg-gray-300 cursor-not-allowed'
                }
              `}
            >
              {isSaving ? 'Saving...' : 'Save Segment'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default SaveTemplateModal
