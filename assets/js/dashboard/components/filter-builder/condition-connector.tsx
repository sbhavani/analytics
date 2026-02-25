import React from 'react'

interface ConditionConnectorProps {
  connector: 'AND' | 'OR'
  onChange: (connector: 'AND' | 'OR') => void
}

export function ConditionConnector({ connector, onChange }: ConditionConnectorProps) {
  return (
    <div className="flex items-center py-1">
      <div className="flex-1 border-t border-gray-200"></div>
      <select
        value={connector}
        onChange={(e) => onChange(e.target.value as 'AND' | 'OR')}
        className="mx-2 px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 border border-gray-200 rounded hover:bg-gray-200"
      >
        <option value="AND">AND</option>
        <option value="OR">OR</option>
      </select>
      <div className="flex-1 border-t border-gray-200"></div>
    </div>
  )
}

export default ConditionConnector
