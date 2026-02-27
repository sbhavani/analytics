import React from 'react'
import { SavedSegment, FilterTree } from '../lib/types/filter-tree'

interface SegmentListProps {
  segments: SavedSegment[]
  selectedSegmentId?: number
  onSelect: (segment: SavedSegment) => void
  onDelete?: (segmentId: number) => void
  onDuplicate?: (segmentId: number) => void
}

export const SegmentList: React.FC<SegmentListProps> = ({
  segments,
  selectedSegmentId,
  onSelect,
  onDelete,
  onDuplicate
}) => {
  if (segments.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        <p>No saved segments yet</p>
        <p className="text-sm mt-1">Create a filter and save it to see it here</p>
      </div>
    )
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })
  }

  return (
    <div className="segment-list space-y-2">
      {segments.map(segment => (
        <div
          key={segment.id}
          className={`p-3 border rounded-lg cursor-pointer transition-colors ${
            selectedSegmentId === segment.id
              ? 'border-blue-500 bg-blue-50'
              : 'hover:bg-gray-50'
          }`}
          onClick={() => onSelect(segment)}
        >
          <div className="flex justify-between items-start">
            <div className="flex-1">
              <div className="font-medium">{segment.name}</div>
              <div className="text-sm text-gray-500">
                {segment.filter_tree ? 'Advanced filter' : 'Basic filter'}
              </div>
              <div className="text-xs text-gray-400 mt-1">
                Updated {formatDate(segment.updated_at)}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-1" onClick={e => e.stopPropagation()}>
              {onDuplicate && (
                <button
                  onClick={() => onDuplicate(segment.id)}
                  className="p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded"
                  title="Duplicate"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M7 9a2 2 0 012-2h6a2 2 0 012 2v6a2 2 0 01-2 2H9a2 2 0 01-2-2V9z" />
                    <path d="M5 3a2 2 0 00-2 2v6a2 2 0 002 2V5h8a2 2 0 00-2-2H5z" />
                  </svg>
                </button>
              )}
              {onDelete && (
                <button
                  onClick={() => onDelete(segment.id)}
                  className="p-1.5 text-red-500 hover:text-red-700 hover:bg-red-50 rounded"
                  title="Delete"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                </button>
              )}
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}

export default SegmentList
