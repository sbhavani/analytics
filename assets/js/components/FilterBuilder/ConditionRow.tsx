import React from 'react'
import { FilterCondition } from '../lib/filterBuilder/types'
import { FieldSelect } from './FieldSelect'
import { OperatorSelect } from './OperatorSelect'
import { ValueInput } from './ValueInput'

interface ConditionRowProps {
  condition: FilterCondition
  onUpdate: (updates: Partial<FilterCondition>) => void
  onRemove: () => void
  connector?: 'AND' | 'OR'
  showConnector?: boolean
}

export function ConditionRow({
  condition,
  onUpdate,
  onRemove,
  connector,
  showConnector,
}: ConditionRowProps) {
  return (
    <div className="flex items-center gap-2 p-3 bg-white border border-gray-200 rounded-lg dark:bg-gray-800 dark:border-gray-700">
      {showConnector && connector && (
        <div className="flex-shrink-0 px-2 py-1 text-xs font-semibold text-indigo-600 bg-indigo-50 rounded dark:bg-indigo-900/30 dark:text-indigo-400">
          {connector}
        </div>
      )}

      <div className="flex-1 min-w-0 grid grid-cols-1 sm:grid-cols-3 gap-2">
        <FieldSelect
          value={condition.field}
          onChange={(field) => onUpdate({ field, operator: '', value: '' })}
        />

        <OperatorSelect
          field={condition.field}
          value={condition.operator}
          onChange={(operator) => onUpdate({ operator, value: '' })}
        />

        <ValueInput
          field={condition.field}
          operator={condition.operator}
          value={condition.value}
          onChange={(value) => onUpdate({ value })}
        />
      </div>

      <button
        type="button"
        onClick={onRemove}
        className="flex-shrink-0 p-2 text-gray-400 hover:text-red-500 transition-colors"
        title="Remove condition"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="w-5 h-5"
          viewBox="0 0 20 20"
          fill="currentColor"
        >
          <path
            fillRule="evenodd"
            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
            clipRule="evenodd"
          />
        </svg>
      </button>
    </div>
  )
}
