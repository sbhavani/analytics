import React from 'react'
import { FilterCondition, getDimensionDisplayName, getOperatorDisplayName } from '../../types/filter-expression'

interface ConditionSummaryProps {
  condition: FilterCondition
}

export function ConditionSummary({ condition }: ConditionSummaryProps) {
  const dimensionName = getDimensionDisplayName(condition.dimension)
  const operatorName = getOperatorDisplayName(condition.operator)

  const formatValue = (value: string | number | string[] | null): string => {
    if (value === null || value === undefined) return '(any)'
    if (Array.isArray(value)) return value.join(', ')
    return String(value)
  }

  return (
    <div className="flex items-center space-x-2 text-sm text-gray-700">
      <span className="font-medium">{dimensionName}</span>
      <span className="text-gray-500">{operatorName}</span>
      <span className="font-medium">{formatValue(condition.value)}</span>
    </div>
  )
}

export default ConditionSummary
