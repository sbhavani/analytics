import React from 'react'
import { XMarkIcon } from '@heroicons/react/20/solid'
import {
  FilterCondition,
  FilterOperatorType
} from '../../filtering/segments'
import {
  FILTER_OPERATIONS,
  getAvailableFilterModals,
  supportsContains,
  supportsIsNot
} from '../../util/filters'
import { useSiteContext } from '../../site-context'

interface ConditionRowProps {
  condition: FilterCondition
  onChange: (updates: Partial<FilterCondition>) => void
  onRemove: () => void
}

const DIMENSIONS = [
  { value: 'country', label: 'Country' },
  { value: 'region', label: 'Region' },
  { value: 'city', label: 'City' },
  { value: 'device', label: 'Device' },
  { value: 'browser', label: 'Browser' },
  { value: 'browser_version', label: 'Browser Version' },
  { value: 'os', label: 'Operating System' },
  { value: 'os_version', label: 'OS Version' },
  { value: 'source', label: 'Source' },
  { value: 'referrer', label: 'Referrer' },
  { value: 'utm_medium', label: 'UTM Medium' },
  { value: 'utm_source', label: 'UTM Source' },
  { value: 'utm_campaign', label: 'UTM Campaign' },
  { value: 'page', label: 'Page' },
  { value: 'entry_page', label: 'Entry Page' },
  { value: 'exit_page', label: 'Exit Page' },
  { value: 'hostname', label: 'Hostname' }
]

const OPERATORS: { value: FilterOperatorType; label: string }[] = [
  { value: 'is', label: 'is' },
  { value: 'is_not', label: 'is not' },
  { value: 'contains', label: 'contains' },
  { value: 'contains_not', label: 'does not contain' }
]

export function ConditionRow({ condition, onChange, onRemove }: ConditionRowProps) {
  const site = useSiteContext()

  const availableDimensions = DIMENSIONS

  const getAvailableOperators = (dimension: string) => {
    return OPERATORS.filter(op => {
      if (op.value === 'is_not' && !supportsIsNot(dimension)) return false
      if ((op.value === 'contains' || op.value === 'contains_not') && !supportsContains(dimension)) return false
      return true
    })
  }

  return (
    <div className="condition-row flex items-start gap-2 p-3 bg-white border border-gray-200 rounded">
      {/* Dimension Selector */}
      <div className="flex-1 min-w-[120px]">
        <select
          value={condition.dimension}
          onChange={(e) => onChange({ dimension: e.target.value, value: [] })}
          className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        >
          <option value="">Select dimension</option>
          {availableDimensions.map(dim => (
            <option key={dim.value} value={dim.value}>
              {dim.label}
            </option>
          ))}
        </select>
      </div>

      {/* Operator Selector */}
      <div className="w-32">
        <select
          value={condition.operator}
          onChange={(e) => onChange({ operator: e.target.value as FilterOperatorType })}
          className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        >
          {getAvailableOperators(condition.dimension).map(op => (
            <option key={op.value} value={op.value}>
              {op.label}
            </option>
          ))}
        </select>
      </div>

      {/* Value Input */}
      <div className="flex-1 min-w-[150px]">
        {condition.operator === 'contains' || condition.operator === 'contains_not' ? (
          <input
            type="text"
            value={condition.value[0] || ''}
            onChange={(e) => onChange({ value: [e.target.value] })}
            placeholder="Enter value..."
            className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        ) : (
          <input
            type="text"
            value={condition.value[0] || ''}
            onChange={(e) => onChange({ value: [e.target.value] })}
            placeholder="Enter value..."
            className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        )}
      </div>

      {/* Remove Button */}
      <button
        onClick={onRemove}
        className="p-1.5 text-gray-400 hover:text-red-500 transition-colors"
        title="Remove condition"
      >
        <XMarkIcon className="w-5 h-5" />
      </button>
    </div>
  )
}
