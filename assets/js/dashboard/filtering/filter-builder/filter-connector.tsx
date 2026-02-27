import React from 'react'

interface FilterConnectorProps {
  filterType: 'and' | 'or'
  onChange: (filterType: 'and' | 'or') => void
  disabled?: boolean
}

export const FilterConnector: React.FC<FilterConnectorProps> = ({
  filterType,
  onChange,
  disabled = false
}) => {
  return (
    <div className="flex items-center gap-1">
      <button
        onClick={() => onChange('and')}
        disabled={disabled}
        className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
          filterType === 'and'
            ? 'bg-indigo-100 text-indigo-700 border border-indigo-300'
            : 'bg-gray-100 text-gray-600 border border-gray-300 hover:bg-gray-200'
        } ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
        aria-pressed={filterType === 'and'}
        aria-label="AND connector"
      >
        AND
      </button>
      <button
        onClick={() => onChange('or')}
        disabled={disabled}
        className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
          filterType === 'or'
            ? 'bg-indigo-100 text-indigo-700 border border-indigo-300'
            : 'bg-gray-100 text-gray-600 border border-gray-300 hover:bg-gray-200'
        } ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
        aria-pressed={filterType === 'or'}
        aria-label="OR connector"
      >
        OR
      </button>
    </div>
  )
}

export default FilterConnector
