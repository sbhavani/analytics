import React from 'react'

interface FilterSummaryProps {
  summary: string
}

export function FilterSummary({ summary }: FilterSummaryProps) {
  if (!summary) {
    return (
      <p className="text-sm text-gray-500 italic">
        No filter conditions added yet. Add conditions above to build your filter.
      </p>
    )
  }

  return (
    <div className="text-sm text-gray-700 break-words">
      {summary.split(/(\sAND\s|\sOR\s|\(|\))/).map((part, index) => {
        if (part === ' AND ' || part === ' OR ') {
          return (
            <span
              key={index}
              className={`mx-1 font-medium ${
                part.trim() === 'AND' ? 'text-blue-600' : 'text-purple-600'
              }`}
            >
              {part.trim()}
            </span>
          )
        }
        if (part === '(' || part === ')') {
          return <span key={index} className="text-gray-400">{part}</span>
        }
        return <span key={index}>{part}</span>
      })}
    </div>
  )
}

export default FilterSummary
