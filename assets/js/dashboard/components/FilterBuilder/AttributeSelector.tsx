import { VISITOR_ATTRIBUTES } from '../../util/filter-attributes'
import React, { forwardRef } from 'react'

interface AttributeSelectorProps {
  value: string
  onChange: (value: string) => void
  onKeyDown?: (e: React.KeyboardEvent<HTMLSelectElement>) => void
  disabled?: boolean
}

export const AttributeSelector = forwardRef<HTMLSelectElement, AttributeSelectorProps>(
  function AttributeSelector({ value, onChange, onKeyDown, disabled = false }, ref) {
    return (
      <select
        ref={ref}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={onKeyDown}
        disabled={disabled}
        className="px-3 py-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 min-w-[150px]"
        aria-label="Select attribute"
      >
        <option value="">Select attribute...</option>
        {VISITOR_ATTRIBUTES.map((attr) => (
          <option key={attr.id} value={attr.id}>
            {attr.name}
          </option>
        ))}
      </select>
    )
  }
)
