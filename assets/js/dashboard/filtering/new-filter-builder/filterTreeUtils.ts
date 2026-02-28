/**
 * Filter tree utility functions for the Advanced Filter Builder
 */

import {
  FilterCondition,
  FilterGroup,
  FilterTree,
  LegacyFilter,
  FilterAttribute
} from './types'

// Generate unique IDs
let idCounter = 0
export function generateId(): string {
  return `fb-${Date.now()}-${++idCounter}`
}

// Create a new empty condition
export function createCondition(overrides: Partial<FilterCondition> = {}): FilterCondition {
  return {
    id: generateId(),
    attribute: '',
    operator: 'equals',
    value: '',
    isNegated: false,
    ...overrides
  }
}

// Create a new empty group
export function createGroup(overrides: Partial<FilterGroup> = {}): FilterGroup {
  return {
    id: generateId(),
    connector: 'AND',
    conditions: [],
    nestedGroups: [],
    ...overrides
  }
}

// Create a new empty filter tree
export function createFilterTree(): FilterTree {
  return {
    rootGroup: createGroup({ id: 'root' })
  }
}

// Find a group by ID recursively
export function findGroupById(
  tree: FilterTree,
  groupId: string
): FilterGroup | null {
  if (tree.rootGroup.id === groupId) {
    return tree.rootGroup
  }
  return findGroupInGroup(tree.rootGroup, groupId)
}

function findGroupInGroup(
  group: FilterGroup,
  groupId: string
): FilterGroup | null {
  if (group.id === groupId) {
    return group
  }
  for (const nested of group.nestedGroups) {
    const found = findGroupInGroup(nested, groupId)
    if (found) return found
  }
  return null
}

// Find a condition by ID recursively
export function findConditionById(
  tree: FilterTree,
  conditionId: string
): { condition: FilterCondition; groupId: string } | null {
  return findConditionInGroup(tree.rootGroup, conditionId)
}

function findConditionInGroup(
  group: FilterGroup,
  conditionId: string
): { condition: FilterCondition; groupId: string } | null {
  const idx = group.conditions.findIndex(c => c.id === conditionId)
  if (idx !== -1) {
    return { condition: group.conditions[idx], groupId: group.id }
  }
  for (const nested of group.nestedGroups) {
    const found = findConditionInGroup(nested, conditionId)
    if (found) return found
  }
  return null
}

// Update a condition
export function updateCondition(
  tree: FilterTree,
  conditionId: string,
  updates: Partial<FilterCondition>
): FilterTree {
  const result = findConditionInGroup(tree.rootGroup, conditionId)
  if (!result) return tree

  const { groupId } = result

  return {
    rootGroup: updateConditionInGroup(tree.rootGroup, conditionId, groupId, updates)
  }
}

function updateConditionInGroup(
  group: FilterGroup,
  conditionId: string,
  targetGroupId: string,
  updates: Partial<FilterCondition>
): FilterGroup {
  if (group.id === targetGroupId) {
    return {
      ...group,
      conditions: group.conditions.map(c =>
        c.id === conditionId ? { ...c, ...updates } : c
      )
    }
  }

  return {
    ...group,
    nestedGroups: group.nestedGroups.map(g =>
      updateConditionInGroup(g, conditionId, targetGroupId, updates)
    )
  }
}

// Delete a condition
export function deleteCondition(
  tree: FilterTree,
  conditionId: string
): FilterTree {
  return {
    rootGroup: deleteConditionFromGroup(tree.rootGroup, conditionId)
  }
}

function deleteConditionFromGroup(
  group: FilterGroup,
  conditionId: string
): FilterGroup {
  return {
    ...group,
    conditions: group.conditions.filter(c => c.id !== conditionId),
    nestedGroups: group.nestedGroups.map(g => deleteConditionFromGroup(g, conditionId))
  }
}

// Add a condition to a group
export function addCondition(
  tree: FilterTree,
  groupId: string,
  condition: FilterCondition
): FilterTree {
  return {
    rootGroup: addConditionToGroup(tree.rootGroup, groupId, condition)
  }
}

function addConditionToGroup(
  group: FilterGroup,
  groupId: string,
  condition: FilterCondition
): FilterGroup {
  if (group.id === groupId) {
    return {
      ...group,
      conditions: [...group.conditions, condition]
    }
  }

  return {
    ...group,
    nestedGroups: group.nestedGroups.map(g =>
      addConditionToGroup(g, groupId, condition)
    )
  }
}

// Add a nested group
export function addNestedGroup(
  tree: FilterTree,
  parentGroupId: string,
  group: FilterGroup
): { tree: FilterTree; error?: string } {
  // Check depth limit (max 5 levels)
  const depth = getGroupDepth(tree.rootGroup, parentGroupId, 0)
  if (depth >= 5) {
    return { tree, error: 'Maximum nesting depth of 5 levels exceeded' }
  }

  return {
    tree: {
      rootGroup: addNestedGroupToGroup(tree.rootGroup, parentGroupId, group)
    }
  }
}

function getGroupDepth(
  group: FilterGroup,
  targetId: string,
  currentDepth: number
): number {
  if (group.id === targetId) {
    return currentDepth
  }

  let maxDepth = currentDepth
  for (const nested of group.nestedGroups) {
    const depth = getGroupDepth(nested, targetId, currentDepth + 1)
    maxDepth = Math.max(maxDepth, depth)
  }
  return maxDepth
}

function addNestedGroupToGroup(
  group: FilterGroup,
  parentGroupId: string,
  newGroup: FilterGroup
): FilterGroup {
  if (group.id === parentGroupId) {
    return {
      ...group,
      nestedGroups: [...group.nestedGroups, newGroup]
    }
  }

  return {
    ...group,
    nestedGroups: group.nestedGroups.map(g =>
      addNestedGroupToGroup(g, parentGroupId, newGroup)
    )
  }
}

// Delete a nested group
export function deleteNestedGroup(
  tree: FilterTree,
  groupId: string
): FilterTree {
  // Cannot delete root group
  if (groupId === 'root') {
    return tree
  }

  return {
    rootGroup: deleteNestedGroupFromGroup(tree.rootGroup, groupId)
  }
}

function deleteNestedGroupFromGroup(
  group: FilterGroup,
  groupId: string
): FilterGroup {
  return {
    ...group,
    nestedGroups: group.nestedGroups
      .filter(g => g.id !== groupId)
      .map(g => deleteNestedGroupFromGroup(g, groupId))
  }
}

// Update connector
export function updateConnector(
  tree: FilterTree,
  groupId: string,
  connector: 'AND' | 'OR'
): FilterTree {
  return {
    rootGroup: updateConnectorInGroup(tree.rootGroup, groupId, connector)
  }
}

function updateConnectorInGroup(
  group: FilterGroup,
  groupId: string,
  connector: 'AND' | 'OR'
): FilterGroup {
  if (group.id === groupId) {
    return { ...group, connector }
  }

  return {
    ...group,
    nestedGroups: group.nestedGroups.map(g =>
      updateConnectorInGroup(g, groupId, connector)
    )
  }
}

// Check if filter is valid
export function isFilterValid(tree: FilterTree): boolean {
  return isGroupValid(tree.rootGroup)
}

function isGroupValid(group: FilterGroup): boolean {
  // Must have at least one condition or nested group
  if (group.conditions.length === 0 && group.nestedGroups.length === 0) {
    return false
  }

  // All conditions must be valid
  for (const condition of group.conditions) {
    if (!isConditionValid(condition)) {
      return false
    }
  }

  // All nested groups must be valid
  for (const nested of group.nestedGroups) {
    if (!isGroupValid(nested)) {
      return false
    }
  }

  return true
}

function isConditionValid(condition: FilterCondition): boolean {
  // Must have an attribute selected
  if (!condition.attribute) {
    return false
  }

  // Operators that need a value
  const needsValue = ['equals', 'does_not_equal', 'contains', 'does_not_contain']
  if (needsValue.includes(condition.operator) && !condition.value) {
    return false
  }

  return true
}

// Convert filter tree to legacy format for API
export function filterTreeToLegacyFilters(tree: FilterTree): LegacyFilter[] {
  return flattenGroupToLegacyFilters(tree.rootGroup)
}

function flattenGroupToLegacyFilters(group: FilterGroup): LegacyFilter[] {
  const filters: LegacyFilter[] = []

  for (const condition of group.conditions) {
    const filter = conditionToLegacyFilter(condition)
    if (filter) {
      filters.push(filter)
    }
  }

  for (const nested of group.nestedGroups) {
    const nestedFilters = flattenGroupToLegacyFilters(nested)
    filters.push(...nestedFilters)
  }

  return filters
}

function conditionToLegacyFilter(condition: FilterCondition): LegacyFilter | null {
  if (!condition.attribute || !isConditionValid(condition)) {
    return null
  }

  const { attribute, operator, value, isNegated } = condition

  // Map our operator to legacy format
  let legacyOperator: string
  switch (operator) {
    case 'equals':
      legacyOperator = isNegated ? 'is_not' : 'is'
      break
    case 'does_not_equal':
      legacyOperator = 'is_not'
      break
    case 'contains':
      legacyOperator = isNegated ? 'does_not_contain' : 'contains'
      break
    case 'does_not_contain':
      legacyOperator = 'does_not_contain'
      break
    case 'is_set':
      legacyOperator = 'is_not_set' // Inverted logic
      break
    case 'is_not_set':
      legacyOperator = 'is_set' // Inverted logic
      break
    default:
      legacyOperator = 'is'
  }

  // For set/not_set operators, use empty array
  const clause = ['is_set', 'is_not_set'].includes(operator)
    ? []
    : [value]

  return [legacyOperator, attribute, clause as [string]]
}

// Count total conditions
export function countConditions(tree: FilterTree): number {
  return countConditionsInGroup(tree.rootGroup)
}

function countConditionsInGroup(group: FilterGroup): number {
  let count = group.conditions.length
  for (const nested of group.nestedGroups) {
    count += countConditionsInGroup(nested)
  }
  return count
}

// Check if tree has OR logic
export function hasOrLogic(tree: FilterTree): boolean {
  return hasOrInGroup(tree.rootGroup)
}

function hasOrInGroup(group: FilterGroup): boolean {
  if (group.connector === 'OR') return true

  for (const nested of group.nestedGroups) {
    if (hasOrInGroup(nested)) return true
  }

  return false
}

// Check if tree has nested groups
export function hasNestedGroups(tree: FilterTree): boolean {
  return hasNestedGroupsInGroup(tree.rootGroup)
}

function hasNestedGroupsInGroup(group: FilterGroup): boolean {
  if (group.nestedGroups.length > 0) return true

  for (const nested of group.nestedGroups) {
    if (hasNestedGroupsInGroup(nested)) return true
  }

  return false
}

// Generate human-readable filter summary
export function generateFilterSummary(tree: FilterTree): string {
  return generateGroupSummary(tree.rootGroup)
}

function generateGroupSummary(group: FilterGroup): string {
  const parts: string[] = []

  // Add conditions
  for (const condition of group.conditions) {
    parts.push(formatCondition(condition))
  }

  // Add nested groups
  for (const nested of group.nestedGroups) {
    parts.push(`(${generateGroupSummary(nested)})`)
  }

  if (parts.length === 0) return ''

  return parts.join(` ${group.connector} `)
}

function formatCondition(condition: FilterCondition): string {
  const attrLabel = condition.attribute || 'Attribute'
  const opLabel = getOperatorLabel(condition.operator)
  const value = condition.value || 'value'

  if (['is_set', 'is_not_set'].includes(condition.operator)) {
    return `${attrLabel} ${opLabel}`
  }

  return `${attrLabel} ${opLabel} ${value}`
}

function getOperatorLabel(operator: string): string {
  const labels: Record<string, string> = {
    equals: '=',
    does_not_equal: '!=',
    contains: 'contains',
    does_not_contain: 'does not contain',
    is_set: 'is set',
    is_not_set: 'is not set'
  }
  return labels[operator] || operator
}
