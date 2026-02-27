import React, { useState } from 'react'
import { FilterOperation, FilterCondition as FilterConditionType } from '../util/filter-serializer'
import { FILTER_OPERATIONS, FILTER_OPERATIONS_DISPLAY_NAMES } from '../util/filters'

interface FilterConditionProps {
  condition: FilterConditionType
  availableDimensions: Dimension[]
  onChange: (condition: FilterConditionType) => void
  onRemove: () => void
}

interface Dimension {
  key: string
  name: string
}

export const FilterCondition: React.FC<FilterConditionProps> = ({
  condition,
  availableDimensions,
  onChange,
  onRemove
}) => {
  const [isEditing, setIsEditing] = useState(false)

  const [operation, dimension, clauses] = condition

  const handleDimensionChange = (newDimension: string) => {
    onChange([operation as FilterOperation, newDimension, clauses])
  }

  const handleOperationChange = (newOperation: string) => {
    onChange([newOperation as FilterOperation, dimension, clauses])
  }

  const handleClauseChange = (index: number, value: string) => {
    const newClauses = [...clauses]
    newClauses[index] = value
    onChange([operation as FilterOperation, dimension, newClauses])
  }

  const handleAddClause = () => {
    onChange([operation as FilterOperation, dimension, [...clauses, '']])
  }

  const handleRemoveClause = (index: number) => {
    const newClauses = clauses.filter((_, i) => i !== index)
    onChange([operation as FilterOperation, dimension, newClauses])
  }

  const getDimensionName = (key: string) => {
    const dim = availableDimensions.find(d => d.key === key)
    return dim ? dim.name : key
  }

  if (isEditing) {
    return (
      <div className="flex items-center gap-2 p-3 bg-white border border-gray-200 rounded-lg shadow-sm">
        {/* Dimension selector */}
        <select
          value={dimension}
          onChange={(e) => handleDimensionChange(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          aria-label="Select dimension"
        >
          {availableDimensions.map((dim) => (
            <option key={dim.key} value={dim.key}>
              {dim.name}
            </option>
          ))}
        </select>

        {/* Operation selector */}
        <select
          value={operation}
          onChange={(e) => handleOperationChange(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          aria-label="Select operation"
        >
          {Object.entries(FILTER_OPERATIONS).map(([key, value]) => (
            <option key={value} value={value}>
              {FILTER_OPERATIONS_DISPLAY_NAMES[key as keyof typeof FILTER_OPERATIONS_DISPLAY_NAMES] || key}
            </option>
          ))}
        </select>

        {/* Value input(s) */}
        <div className="flex items-center gap-2 flex-1">
          {clauses.map((clause, index) => (
            <div key={index} className="flex items-center gap-1">
              <input
                type="text"
                value={clause}
                onChange={(e) => handleClauseChange(index, e.target.value)}
                placeholder="Value"
                className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                aria-label={`Value ${index + 1}`}
              />
              {clauses.length > 1 && (
                <button
                  onClick={() => handleRemoveClause(index)}
                  className="text-gray-400 hover:text-red-500"
                  aria-label={`Remove value ${index + 1}`}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              )}
            </div>
          ))}
          <button
            onClick={handleAddClause}
            className="text-indigo-600 hover:text-indigo-800 text-sm"
            aria-label="Add value"
          >
            + Add
          </button>
        </div>

        {/* Save button */}
        <button
          onClick={() => setIsEditing(false)}
          className="px-3 py-2 bg-indigo-600 text-white rounded-md text-sm hover:bg-indigo-700"
        >
          Done
        </button>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-2 p-3 bg-white border border-gray-200 rounded-lg shadow-sm">
      {/* Display mode */}
      <div className="flex-1 flex items-center gap-2">
        <span className="font-medium text-gray-700">
          {getDimensionName(dimension)}
        </span>
        <span className="text-gray-500">
          {FILTER_OPERATIONS_DISPLAY_NAMES[operation as keyof typeof FILTER_OPERATIONS_DISPLAY_NAMES] || operation}
        </span>
        <span className="text-gray-700">
          {clauses.join(', ')}
        </span>
      </div>

      {/* Edit button */}
      <button
        onClick={() => setIsEditing(true)}
        className="p-2 text-gray-400 hover:text-gray-600"
        aria-label="Edit condition"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
        </svg>
      </button>

      {/* Remove button */}
      <button
        onClick={onRemove}
        className="p-2 text-gray-400 hover:text-red-500"
        aria-label="Remove condition"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>
    </div>
  )
}

export default FilterCondition
