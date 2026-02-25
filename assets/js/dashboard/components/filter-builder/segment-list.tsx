import React from 'react'
import { SavedSegment } from '../../filtering/segments'

interface SegmentListProps {
  segments: SavedSegment[]
  selectedSegmentId?: number
  onSelect: (segment: SavedSegment) => void
  onCreateNew?: () => void
}

export function SegmentList({ segments, selectedSegmentId, onSelect, onCreateNew }: SegmentListProps) {
  const [isOpen, setIsOpen] = React.useState(false)

  const selectedSegment = segments.find(s => s.id === selectedSegmentId)

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center justify-between w-full px-3 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        <span>
          {selectedSegment ? selectedSegment.name : 'Load a segment...'}
        </span>
        <svg className="w-5 h-5 ml-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-64 overflow-y-auto">
          {onCreateNew && (
            <button
              type="button"
              onClick={() => {
                onCreateNew()
                setIsOpen(false)
              }}
              className="w-full px-3 py-2 text-left text-sm text-indigo-600 hover:bg-indigo-50 flex items-center"
            >
              <svg className="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Create new segment
            </button>
          )}

          {segments.length === 0 && (
            <div className="px-3 py-2 text-sm text-gray-500">
              No saved segments
            </div>
          )}

          {segments.map((segment) => (
            <button
              key={segment.id}
              type="button"
              onClick={() => {
                onSelect(segment)
                setIsOpen(false)
              }}
              className={`w-full px-3 py-2 text-left text-sm hover:bg-gray-100 ${
                segment.id === selectedSegmentId ? 'bg-indigo-50 text-indigo-700' : 'text-gray-900'
              }`}
            >
              <div className="font-medium">{segment.name}</div>
              <div className="text-xs text-gray-500">
                {segment.type === 'site' ? 'Site segment' : 'Personal segment'}
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export default SegmentList
