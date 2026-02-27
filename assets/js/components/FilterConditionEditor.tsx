import React, { useState, useEffect } from 'react'
import { FilterConditionNode, FilterOperator } from '../lib/types/filter-tree'
import { getOperatorsForAttribute } from '../lib/filter-suggestions'
import { fetchFilterSuggestions, FilterSuggestion } from '../lib/filter-suggestions'
import { getAvailableAttributes } from '../lib/filter-suggestions'

interface FilterConditionEditorProps {
  condition: FilterConditionNode
  onChange: (updated: FilterConditionNode) => void
  onRemove: () => void
  siteId: string
}

export const FilterConditionEditor: React.FC<FilterConditionEditorProps> = ({
  condition,
  onChange,
  onRemove,
  siteId
}) => {
  const attributes = getAvailableAttributes()
  const operators = getOperatorsForAttribute(condition.attribute)
  const [suggestions, setSuggestions] = useState<FilterSuggestion[]>([])
  const [showSuggestions, setShowSuggestions] = useState(false)

  // Fetch suggestions when value changes for autocomplete
  useEffect(() => {
    if (condition.attribute && condition.value.length > 0) {
      const timer = setTimeout(() => {
        fetchFilterSuggestions(siteId, condition.attribute, condition.value).then(setSuggestions)
      }, 300)
      return () => clearTimeout(timer)
    }
    setSuggestions([])
  }, [condition.attribute, condition.value, siteId])

  const handleAttributeChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({ ...condition, attribute: e.target.value, value: '' })
  }

  const handleOperatorChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({ ...condition, operator: e.target.value as FilterOperator })
  }

  const handleValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange({ ...condition, value: e.target.value })
    setShowSuggestions(true)
  }

  const handleSuggestionClick = (suggestion: FilterSuggestion) => {
    onChange({ ...condition, value: suggestion.value })
    setShowSuggestions(false)
  }

  const handleNegatedChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange({ ...condition, negated: e.target.checked })
  }

  const selectedAttribute = attributes.find(a => a.key === condition.attribute)

  return (
    <div className="filter-condition-editor flex items-center gap-2 p-3 bg-white border rounded-md shadow-sm">
      {/* Attribute Selector */}
      <select
        value={condition.attribute}
        onChange={handleAttributeChange}
        className="px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
        aria-label="Select attribute"
      >
        <option value="">Select attribute...</option>
        <optgroup label="Visit Properties">
          {attributes.filter(a => a.type === 'visit').map(attr => (
            <option key={attr.key} value={attr.key}>{attr.label}</option>
          ))}
        </optgroup>
        <optgroup label="Event Properties">
          {attributes.filter(a => a.type === 'event').map(attr => (
            <option key={attr.key} value={attr.key}>{attr.label}</option>
          ))}
        </optgroup>
      </select>

      {/* Operator Selector */}
      <select
        value={condition.operator}
        onChange={handleOperatorChange}
        className="px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
        aria-label="Select operator"
        disabled={!condition.attribute}
      >
        {operators.map(op => (
          <option key={op.value} value={op.value}>{op.label}</option>
        ))}
      </select>

      {/* Value Input with Autocomplete */}
      <div className="relative flex-1">
        <input
          type="text"
          value={condition.value}
          onChange={handleValueChange}
          onFocus={() => setShowSuggestions(true)}
          onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
          placeholder={condition.operator === 'has_done' || condition.operator === 'has_not_done' ? 'Any goal' : 'Enter value...'}
          className="w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
          disabled={condition.operator === 'has_done' || condition.operator === 'has_not_done'}
          aria-label="Enter value"
        />

        {/* Autocomplete Suggestions */}
        {showSuggestions && suggestions.length > 0 && (
          <ul className="absolute z-10 w-full mt-1 bg-white border rounded-md shadow-lg max-h-48 overflow-y-auto">
            {suggestions.map((suggestion, index) => (
              <li
                key={index}
                onClick={() => handleSuggestionClick(suggestion)}
                className="px-3 py-2 cursor-pointer hover:bg-gray-100"
              >
                {suggestion.label || suggestion.value}
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Negation Toggle */}
      <label className="flex items-center gap-1 text-sm">
        <input
          type="checkbox"
          checked={condition.negated}
          onChange={handleNegatedChange}
          className="rounded"
        />
        <span>NOT</span>
      </label>

      {/* Remove Button */}
      <button
        onClick={onRemove}
        className="p-2 text-red-600 hover:bg-red-50 rounded-md"
        aria-label="Remove condition"
        title="Remove condition"
      >
        <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
        </svg>
      </button>
    </div>
  )
}

export default FilterConditionEditor
