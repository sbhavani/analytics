import React, { useState, useEffect } from 'react'
import { FilterTree } from './FilterBuilder'

interface Segment {
  id: string
  name: string
  filter_tree?: FilterTree
  visitor_count?: number
  created_at: string
  updated_at: string
}

interface SegmentListProps {
  siteId: string
  onSelectSegment: (segment: Segment) => void
  onDeleteSegment: (segmentId: string) => Promise<void>
  onCreateNew: () => void
  apiBaseUrl?: string
}

export function SegmentList({
  siteId,
  onSelectSegment,
  onDeleteSegment,
  onCreateNew,
  apiBaseUrl = '/api'
}: SegmentListProps) {
  const [segments, setSegments] = useState<Segment[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null)

  // Fetch segments
  useEffect(() => {
    async function fetchSegments() {
      setIsLoading(true)
      try {
        const response = await fetch(`${apiBaseUrl}/sites/${siteId}/segments`)
        if (!response.ok) {
          throw new Error('Failed to fetch segments')
        }
        const data = await response.json()
        setSegments(data.segments || [])
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setIsLoading(false)
      }
    }

    fetchSegments()
  }, [siteId, apiBaseUrl])

  // Filter segments by search query
  const filteredSegments = segments.filter(segment =>
    segment.name.toLowerCase().includes(searchQuery.toLowerCase())
  )

  // Handle delete
  const handleDelete = async (segmentId: string) => {
    try {
      await onDeleteSegment(segmentId)
      setSegments(prev => prev.filter(s => s.id !== segmentId))
      setDeleteConfirm(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete segment')
    }
  }

  // Format date
  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  if (isLoading) {
    return (
      <div className="segment-list p-4">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
          <div className="space-y-3">
            <div className="h-16 bg-gray-200 rounded"></div>
            <div className="h-16 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="segment-list">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold">Saved Segments</h3>
        <button
          onClick={onCreateNew}
          className="create-new-btn flex items-center gap-1 px-3 py-1.5 text-sm bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Segment
        </button>
      </div>

      {/* Search */}
      <div className="mb-4">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search segments..."
          className="w-full px-3 py-2 border rounded-md"
          aria-label="Search segments"
        />
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md" role="alert">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}

      {/* Segment List */}
      {filteredSegments.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          {searchQuery ? 'No segments match your search' : 'No saved segments yet'}
        </div>
      ) : (
        <ul className="space-y-2" role="listbox" aria-label="Segments">
          {filteredSegments.map(segment => (
            <li
              key={segment.id}
              className="segment-item flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50"
              role="option"
              aria-selected={false}
            >
              <button
                onClick={() => onSelectSegment(segment)}
                className="flex-1 text-left"
              >
                <div className="font-medium">{segment.name}</div>
                <div className="text-sm text-gray-500">
                  Updated {formatDate(segment.updated_at)}
                  {segment.visitor_count !== undefined && (
                    <span className="ml-2">• {segment.visitor_count.toLocaleString()} visitors</span>
                  )}
                </div>
              </button>

              <div className="flex items-center gap-2">
                {/* Delete Button */}
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    setDeleteConfirm(segment.id)
                  }}
                  className="delete-btn p-2 text-gray-400 hover:text-red-500 rounded-md"
                  aria-label={`Delete ${segment.name}`}
                  title="Delete segment"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-sm w-full mx-4">
            <h3 className="text-lg font-semibold mb-2">Delete Segment?</h3>
            <p className="text-gray-600 mb-4">
              Are you sure you want to delete this segment? This action cannot be undone.
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-md"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDelete(deleteConfirm)}
                className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export type { Segment }
