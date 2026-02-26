import type { Segment } from '../../../types/filter-builder'
import React from 'react'

interface SegmentListProps {
  segments: Segment[]
  selectedSegmentId: number | null
  onSelect: (segmentId: number) => void
  onDelete: (segmentId: number) => void
  isLoading?: boolean
}

export function SegmentList({
  segments,
  selectedSegmentId,
  onSelect,
  onDelete,
  isLoading = false
}: SegmentListProps) {
  if (isLoading) {
    return (
      <div className="p-4 text-center text-gray-500">
        <svg
          className="w-5 h-5 animate-spin mx-auto mb-2"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
          />
        </svg>
        Loading segments...
      </div>
    )
  }

  if (segments.length === 0) {
    return (
      <div className="p-4 text-center text-gray-500">
        No saved segments yet. Create a filter and save it as a segment.
      </div>
    )
  }

  return (
    <div className="space-y-1 max-h-64 overflow-y-auto">
      {segments.map((segment) => (
        <div
          key={segment.id}
          className={`flex items-center justify-between p-2 rounded-md ${
            selectedSegmentId === segment.id
              ? 'bg-blue-50 border border-blue-200'
              : 'hover:bg-gray-50 border border-transparent'
          }`}
        >
          <button
            type="button"
            onClick={() => onSelect(segment.id)}
            className="flex-1 text-left text-sm font-medium text-gray-700 truncate"
          >
            {segment.name}
            <span className="block text-xs text-gray-400">
              {segment.type === 'personal' ? 'Personal' : 'Site-wide'} •{' '}
              {new Date(segment.updated_at).toLocaleDateString()}
            </span>
          </button>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation()
              onDelete(segment.id)
            }}
            className="p-1 text-gray-400 hover:text-red-500 transition-colors"
            title="Delete segment"
          >
            <svg
              className="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        </div>
      ))}
    </div>
  )
}
