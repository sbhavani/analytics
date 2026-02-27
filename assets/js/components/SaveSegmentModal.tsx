import React, { useState } from 'react'
import { FilterTree } from '../lib/types/filter-tree'

interface SaveSegmentModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string) => void
  initialName?: string
  isExistingSegment?: boolean
}

export const SaveSegmentModal: React.FC<SaveSegmentModalProps> = ({
  isOpen,
  onClose,
  onSave,
  initialName = '',
  isExistingSegment = false
}) => {
  const [name, setName] = useState(initialName)
  const [error, setError] = useState<string | null>(null)

  if (!isOpen) return null

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    const trimmedName = name.trim()

    if (!trimmedName) {
      setError('Segment name is required')
      return
    }

    if (trimmedName.length > 100) {
      setError('Segment name must be 100 characters or less')
      return
    }

    onSave(trimmedName)
    setName('')
    setError(null)
  }

  const handleSaveAsNew = () => {
    setName('')
    setError(null)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        <div className="p-6">
          <h2 className="text-xl font-semibold mb-4">
            {isExistingSegment ? 'Save Segment' : 'Save New Segment'}
          </h2>

          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label htmlFor="segment-name" className="block text-sm font-medium text-gray-700 mb-1">
                Segment Name
              </label>
              <input
                id="segment-name"
                type="text"
                value={name}
                onChange={(e) => {
                  setName(e.target.value)
                  setError(null)
                }}
                placeholder="Enter segment name..."
                className="w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
                autoFocus
                maxLength={100}
              />
              <div className="text-sm text-gray-500 mt-1">
                {name.length}/100 characters
              </div>
              {error && (
                <p className="text-red-500 text-sm mt-1">{error}</p>
              )}
            </div>

            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              {isExistingSegment && (
                <button
                  type="button"
                  onClick={handleSaveAsNew}
                  className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-md"
                >
                  Save as New
                </button>
              )}
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SaveSegmentModal
