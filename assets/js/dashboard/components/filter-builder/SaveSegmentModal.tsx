import React, { useState } from 'react'
import { XMarkIcon } from '@heroicons/react/20/solid'
import classNames from 'classnames'
import { FilterGroup } from './types'
import { filterGroupToLegacyFilters } from './filter-serialization'
import { useSiteContext } from '../../site-context'
import { SegmentType } from '../../filtering/segments'

interface SaveSegmentModalProps {
  filterGroup: FilterGroup
  onClose: () => void
}

export default function SaveSegmentModal({ filterGroup, onClose }: SaveSegmentModalProps) {
  const site = useSiteContext()
  const [name, setName] = useState('')
  const [segmentType, setSegmentType] = useState<SegmentType>(SegmentType.personal)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!name.trim()) {
      setError('Please enter a segment name')
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      // Convert filter group to legacy format for storage
      const filters = filterGroupToLegacyFilters(filterGroup)

      const response = await fetch(`/api/stats/${site.domain}/segments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: name.trim(),
          type: segmentType,
          filters
        })
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Failed to save segment')
      }

      const savedSegment = await response.json()
      console.log('Segment saved:', savedSegment)

      // Close modal and notify parent
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save segment')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          onClick={onClose}
        />

        {/* Modal */}
        <div className="relative w-full max-w-md bg-white rounded-lg shadow-xl">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Save as Segment</h3>
            <button
              onClick={onClose}
              className="p-1 text-gray-400 hover:text-gray-600"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="p-4">
            {error && (
              <div className="mb-4 px-3 py-2 bg-red-50 border border-red-200 rounded-md">
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}

            <div className="mb-4">
              <label htmlFor="segment-name" className="block text-sm font-medium text-gray-700 mb-1">
                Segment Name
              </label>
              <input
                id="segment-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g., High-Value US Visitors"
                className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm"
                maxLength={255}
              />
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Segment Type
              </label>
              <div className="space-y-2">
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="segment-type"
                    value={SegmentType.personal}
                    checked={segmentType === SegmentType.personal}
                    onChange={() => setSegmentType(SegmentType.personal)}
                    className="h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Personal</span>
                  <span className="ml-1 text-xs text-gray-500">(only you can see)</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="radio"
                    name="segment-type"
                    value={SegmentType.site}
                    checked={segmentType === SegmentType.site}
                    onChange={() => setSegmentType(SegmentType.site)}
                    className="h-4 w-4 text-indigo-600 border-gray-300 focus:ring-indigo-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Site</span>
                  <span className="ml-1 text-xs text-gray-500">(all team members can see)</span>
                </label>
              </div>
            </div>

            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting || !name.trim()}
                className={classNames(
                  'px-4 py-2 text-sm font-medium text-white rounded-md transition-colors',
                  {
                    'bg-gray-400 cursor-not-allowed': isSubmitting || !name.trim(),
                    'bg-indigo-600 hover:bg-indigo-700': !isSubmitting && name.trim()
                  }
                )}
              >
                {isSubmitting ? 'Saving...' : 'Save Segment'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
