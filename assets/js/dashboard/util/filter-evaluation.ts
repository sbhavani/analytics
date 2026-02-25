// Filter evaluation utilities for the Advanced Filter Builder feature

import { FilterGroup, FilterGroupItem, FilterCondition, isFilterGroup } from '../components/filter-builder/types'

// Visitor data type - represents a visitor's attributes
export interface VisitorData {
  [key: string]: string | number | boolean | null | undefined
}

/**
 * Evaluate a single filter condition against visitor data
 */
export function evaluateCondition(condition: FilterCondition, visitor: VisitorData): boolean {
  const { field, operator, value } = condition
  const fieldValue = visitor[field]

  // Handle null/undefined field values
  if (fieldValue === null || fieldValue === undefined) {
    return operator === 'is_not_set' || operator === 'is_not'
  }

  switch (operator) {
    case 'is':
      return fieldValue === value

    case 'is_not':
      return fieldValue !== value

    case 'contains':
      return String(fieldValue).toLowerCase().includes(String(value).toLowerCase())

    case 'contains_not':
      return !String(fieldValue).toLowerCase().includes(String(value).toLowerCase())

    case 'greater_than':
      return Number(fieldValue) > Number(value)

    case 'less_than':
      return Number(fieldValue) < Number(value)

    case 'is_set':
      return fieldValue !== null && fieldValue !== undefined

    case 'is_not_set':
      return fieldValue === null || fieldValue === undefined

    default:
      return false
  }
}

/**
 * Evaluate a filter group against visitor data
 * Handles AND/OR logical operators
 */
export function evaluateFilterGroup(group: FilterGroup, visitor: VisitorData): boolean {
  const { children, operator } = group

  if (children.length === 0) {
    return true // Empty group evaluates to true
  }

  if (operator === 'AND') {
    // AND: all children must evaluate to true
    return children.every((child) => evaluateFilterItem(child, visitor))
  } else {
    // OR: at least one child must evaluate to true
    return children.some((child) => evaluateFilterItem(child, visitor))
  }
}

/**
 * Evaluate a filter group item (either a condition or a nested group)
 */
export function evaluateFilterItem(item: FilterGroupItem, visitor: VisitorData): boolean {
  if (isFilterGroup(item)) {
    return evaluateFilterGroup(item, visitor)
  } else {
    return evaluateCondition(item, visitor)
  }
}

/**
 * Check if a visitor matches a complete filter definition
 */
export function evaluateFilter(rootGroup: FilterGroup, visitor: VisitorData): boolean {
  return evaluateFilterGroup(rootGroup, visitor)
}

/**
 * Filter a list of visitors based on a filter group
 */
export function filterVisitors(visitors: VisitorData[], rootGroup: FilterGroup): VisitorData[] {
  return visitors.filter((visitor) => evaluateFilter(rootGroup, visitor))
}
