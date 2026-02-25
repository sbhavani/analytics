import React from 'react'
import { FilterLogic } from '../../filtering/segments'

interface LogicSelectorProps {
  value: FilterLogic
  onChange: (logic: FilterLogic) => void
}

export function LogicSelector({ value, onChange }: LogicSelectorProps) {
  return (
    <div className="logic-selector flex items-center gap-1">
      <span className="text-sm text-gray-500">Match</span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as FilterLogic)}
        className="px-2 py-1 text-sm font-medium border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
      >
        <option value="AND">ALL conditions</option>
        <option value="OR">ANY condition</option>
      </select>
      <span className="text-sm text-gray-500">
        ({value === 'AND' ? 'must match all' : 'can match any'})
      </span>
    </div>
  )
}
