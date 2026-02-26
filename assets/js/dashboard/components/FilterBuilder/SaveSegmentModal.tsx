import React, { useState } from 'react'

interface SaveSegmentModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (name: string, type: 'personal' | 'site') => void
  isSaving?: boolean
  existingName?: string
  visitorCount?: number
}

export function SaveSegmentModal({
  isOpen,
  onClose,
  onSave,
  isSaving = false,
  existingName = '',
  visitorCount
}: SaveSegmentModalProps) {
  const [name, setName] = useState(existingName)
  const [type, setType] = useState<'personal' | 'site'>('personal')
  const showZeroVisitorsWarning = visitorCount === 0

  if (!isOpen) return null

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (name.trim()) {
      onSave(name.trim(), type)
      onClose()
    }
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        {/* Background overlay */}
        <div
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          onClick={onClose}
        />

        {/* Modal panel */}
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <form onSubmit={handleSubmit}>
            <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
              <div className="sm:flex sm:items-start">
                <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
                  <h3 className="text-lg leading-6 font-medium text-gray-900">
                    {existingName ? 'Update Segment' : 'Save Segment'}
                  </h3>
                  <div className="mt-4 space-y-4">
                    {/* Segment Name */}
                    <div>
                      <label
                        htmlFor="segment-name"
                        className="block text-sm font-medium text-gray-700"
                      >
                        Segment Name
                      </label>
                      <input
                        type="text"
                        id="segment-name"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="e.g., US Mobile Users"
                        className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                        required
                      />
                    </div>

                    {/* Segment Type */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Segment Type
                      </label>
                      <div className="mt-2 space-y-2">
                        <label className="inline-flex items-center">
                          <input
                            type="radio"
                            name="segment-type"
                            value="personal"
                            checked={type === 'personal'}
                            onChange={() => setType('personal')}
                            className="form-radio h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                          />
                          <span className="ml-2 text-sm text-gray-700">
                            Personal - Only you can see and edit
                          </span>
                        </label>
                        <label className="inline-flex items-center">
                          <input
                            type="radio"
                            name="segment-type"
                            value="site"
                            checked={type === 'site'}
                            onChange={() => setType('site')}
                            className="form-radio h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
                          />
                          <span className="ml-2 text-sm text-gray-700">
                            Site-wide - All team members can see and edit
                          </span>
                        </label>
                      </div>
                    </div>

                    {/* Warning for zero visitors */}
                    {showZeroVisitorsWarning && (
                      <div className="rounded-md bg-amber-50 p-4">
                        <div className="flex">
                          <div className="flex-shrink-0">
                            <svg
                              className="h-5 w-5 text-amber-400"
                              viewBox="0 0 20 20"
                              fill="currentColor"
                            >
                              <path
                                fillRule="evenodd"
                                d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                clipRule="evenodd"
                              />
                            </svg>
                          </div>
                          <div className="ml-3">
                            <h3 className="text-sm font-medium text-amber-800">
                              No visitors match this filter
                            </h3>
                            <div className="mt-2 text-sm text-amber-700">
                              <p>
                                This segment will not match any visitors. Consider adjusting your filter conditions.
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
            <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
              <button
                type="submit"
                disabled={isSaving || !name.trim()}
                className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSaving ? 'Saving...' : existingName ? 'Update' : 'Save'}
              </button>
              <button
                type="button"
                onClick={onClose}
                disabled={isSaving}
                className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
