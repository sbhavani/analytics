export { FilterBuilder } from './FilterBuilder'
export { ConditionRow } from './ConditionRow'
export { ConditionGroup } from './ConditionGroup'
export { FilterPreview } from './FilterPreview'

// Re-export types and utilities
export {
  FilterTree,
  FilterCondition,
  ConditionGroup,
  ConnectorType,
  FilterOperatorType,
  createEmptyCondition,
  createEmptyGroup,
  createEmptyFilterTree,
  filterTreeToBackend,
  backendToFilterTree,
  filterTreeToDashboardFilters,
  validateFilterTree,
  AVAILABLE_DIMENSIONS,
  OPERATORS_BY_TYPE,
  getOperatorsForDimension,
  type FilterDimension
} from '../lib/filter-parser'

export { useFilterBuilder, type UseFilterBuilderReturn, type UseFilterBuilderOptions } from '../hooks/useFilterBuilder'
