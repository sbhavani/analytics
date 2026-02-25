import React from 'react'
import { FilterDimension, getDimensionDisplayName } from '../../types/filter-expression'
import { FILTER_MODAL_TO_FILTER_GROUP } from '../../util/filters'

interface DimensionSelectorProps {
  value: FilterDimension
  onChange: (dimension: FilterDimension) => void
  disabled?: boolean
}

const DIMENSION_GROUPS = [
  {
    label: 'Location',
    dimensions: ['country', 'region', 'city'] as FilterDimension[]
  },
  {
    label: 'Device',
    dimensions: ['device', 'screen', 'browser', 'browser_version', 'os', 'os_version'] as FilterDimension[]
  },
  {
    label: 'Traffic',
    dimensions: ['source', 'referrer', 'channel'] as FilterDimension[]
  },
  {
    label: 'UTM Tags',
    dimensions: ['utm_medium', 'utm_source', 'utm_campaign', 'utm_term', 'utm_content'] as FilterDimension[]
  },
  {
    label: 'Pages',
    dimensions: ['page', 'entry_page', 'exit_page', 'hostname'] as FilterDimension[]
  },
  {
    label: 'Goals',
    dimensions: ['goal'] as FilterDimension[]
  },
  {
    label: 'Properties',
    dimensions: ['props'] as FilterDimension[]
  }
]

export function DimensionSelector({ value, onChange, disabled }: DimensionSelectorProps) {
  const [isOpen, setIsOpen] = React.useState(false)

  const allDimensions = React.useMemo(() => {
    const dims: FilterDimension[] = []
    for (const group of DIMENSION_GROUPS) {
      dims.push(...group.dimensions)
    }
    return dims
  }, [])

  const handleSelect = (dimension: FilterDimension) => {
    onChange(dimension)
    setIsOpen(false)
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => !disabled && setIsOpen(!isOpen)}
        disabled={disabled}
        className="flex items-center justify-between w-full px-3 py-2 text-sm font-medium text-gray-900 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <span>{getDimensionDisplayName(value)}</span>
        <svg className="w-5 h-5 ml-2 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-80 overflow-y-auto">
          {DIMENSION_GROUPS.map((group) => (
            <div key={group.label}>
              <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase bg-gray-50">
                {group.label}
              </div>
              {group.dimensions.map((dimension) => (
                <button
                  key={dimension}
                  type="button"
                  onClick={() => handleSelect(dimension)}
                  className={`w-full px-3 py-2 text-left text-sm hover:bg-gray-100 ${
                    dimension === value ? 'bg-indigo-50 text-indigo-700' : 'text-gray-900'
                  }`}
                >
                  {getDimensionDisplayName(dimension)}
                </button>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default DimensionSelector
