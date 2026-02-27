import React, { useState, useRef, useEffect } from 'react'
import { useFilterBuilder } from './FilterBuilderContext'
import { deserializeFilterTree } from './filterTreeUtils'
import type { SavedSegment, SegmentData } from '../segments'

interface LoadTemplateDropdownProps {
  segments: Array<SavedSegment & { segment_data: SegmentData }>
  onLoadSegment?: (segmentId: number) => void
}

export function LoadTemplateDropdown({ segments, onLoadSegment }: LoadTemplateDropdownProps) {
  const { setFilterTree, clearAll } = useFilterBuilder()
  const [isOpen, setIsOpen] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleLoadSegment = (segment: SavedSegment & { segment_data: SegmentData }) => {
    // Convert segment_data.filters (flat array) to filter tree
    const filterTree = deserializeFilterTree(segment.segment_data.filters)
    setFilterTree(filterTree)
    onLoadSegment?.(segment.id)
    setIsOpen(false)
  }

  const handleClearAndLoad = () => {
    clearAll()
    setIsOpen(false)
  }

  if (segments.length === 0) {
    return (
      <div className="load-template-dropdown" data-testid="load-template-dropdown">
        <span className="load-template-dropdown__empty">No saved segments</span>
      </div>
    )
  }

  return (
    <div className="load-template-dropdown" ref={dropdownRef} data-testid="load-template-dropdown">
      <button
        type="button"
        className="load-template-dropdown__trigger"
        onClick={() => setIsOpen(!isOpen)}
      >
        Load segment ▼
      </button>

      {isOpen && (
        <div className="load-template-dropdown__menu">
          <button
            type="button"
            className="load-template-dropdown__clear"
            onClick={handleClearAndLoad}
          >
            Clear filters
          </button>

          <div className="load-template-dropdown__divider" />

          {segments.map((segment) => (
            <button
              key={segment.id}
              type="button"
              className="load-template-dropdown__item"
              onClick={() => handleLoadSegment(segment)}
            >
              <span className="load-template-dropdown__name">{segment.name}</span>
              <span className="load-template-dropdown__type">
                {segment.type === 'personal' ? 'Personal' : 'Site'}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
