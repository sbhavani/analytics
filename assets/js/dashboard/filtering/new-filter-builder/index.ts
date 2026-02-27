// New Filter Builder - Module Exports

export { FilterBuilder, useFilterBuilder, FilterBuilderProvider } from './FilterBuilder'
export { ConditionGroup } from './ConditionGroup'
export { ConditionRow } from './ConditionRow'
export { OperatorSelector, operatorRequiresValue, getOperatorOptions, getOperatorLabel } from './OperatorSelector'
export { CountFilters, FilterSummary } from './FilterSummary'
export { SaveTemplateModal } from './SaveTemplateModal'
export { LoadTemplateDropdown } from './LoadTemplateDropdown'
export { DraggableItem, SortableList } from './DraggableList'

export {
  createFilterTree,
  createFilterGroup,
  createFilterCondition,
  addCondition,
  addGroup,
  removeItem,
  deleteGroup,
  updateCondition,
  changeGroupOperator,
  moveItem,
  findGroup,
  getGroupDepth,
  validateFilterTree,
  countFilters,
  serializeFilterTree,
  deserializeFilterTree,
  getUsedDimensions,
  clearAllFilters,
  findParentGroup,
  isFilterGroup,
  MAX_NESTING_DEPTH
} from './filterTreeUtils'

export type {
  FilterOperator,
  GroupOperator,
  FilterCondition,
  FilterGroup,
  FilterTree,
  FilterDimension
} from './types'
