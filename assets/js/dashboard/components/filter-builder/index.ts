/**
 * Filter Builder Component - Main Export
 * Advanced filter builder UI for creating custom visitor segments
 */

export { FilterBuilder } from './FilterBuilder'
export { FilterGroup } from './FilterGroup'
export { FilterCondition } from './FilterCondition'
export { ValueInput } from './ValueInput'
export { PropertySelect, getPropertyDisplayName } from './PropertySelect'
export { SaveSegmentModal } from './SaveSegmentModal'

// Types
export type {
  FilterCondition as FilterConditionType,
  FilterGroup as FilterGroupType,
  FilterRoot,
  FilterOperator,
  PropertyType,
  VisitorProperty,
  SegmentData,
  FilterPreview,
  ValidationError,
  FilterBuilderState,
  SavedSegmentInfo,
  HistoryEntry,
  FilterBuilderProps
} from './types'

// Utilities
export {
  VISITOR_PROPERTIES,
  getPropertyByKey,
  getOperatorsForProperty,
  getPropertyType,
  generateId,
  getOperatorDisplayName,
  getAllOperators
} from './properties'

export {
  convertToFlatFilters,
  parseFlatFilters,
  createEmptyFilterRoot,
  createFilterCondition,
  createFilterGroup,
  validateFilter,
  getNestingDepth,
  countConditions,
  hasMaxConditions,
  sanitizeSegmentName,
  validateSegmentName
} from './filter-utils'
