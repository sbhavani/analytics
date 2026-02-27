/**
 * Filter Tree Utility Functions
 * Provides manipulation functions for the filter tree structure
 */

import {
  FilterTree,
  FilterGroupNode,
  FilterConditionNode,
  FilterNode,
  FilterOperator,
  GroupOperator
} from './types/filter-tree'

/**
 * Creates an empty filter tree with a single root group
 */
export function createEmptyTree(): FilterTree {
  return {
    version: 1,
    root: createEmptyGroup()
  }
}

/**
 * Creates an empty group node
 */
export function createEmptyGroup(operator: GroupOperator = 'and'): FilterGroupNode {
  return {
    id: generateId(),
    type: 'group',
    operator,
    children: []
  }
}

/**
 * Creates a new condition node with defaults
 */
export function createCondition(
  attribute: string = '',
  operator: FilterOperator = 'is',
  value: string = ''
): FilterConditionNode {
  return {
    id: generateId(),
    type: 'condition',
    attribute,
    operator,
    value,
    negated: false
  }
}

/**
 * Adds a condition to a group
 */
export function addCondition(
  tree: FilterTree,
  parentId: string,
  condition: FilterConditionNode
): FilterTree {
  return {
    ...tree,
    root: addConditionToGroup(tree.root, parentId, condition)
  }
}

function addConditionToGroup(
  group: FilterGroupNode,
  targetId: string,
  condition: FilterConditionNode
): FilterGroupNode {
  if (group.id === targetId) {
    return {
      ...group,
      children: [...group.children, condition]
    }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (child.type === 'group') {
        return addConditionToGroup(child, targetId, condition)
      }
      return child
    })
  }
}

/**
 * Removes a condition from the tree
 */
export function removeCondition(tree: FilterTree, conditionId: string): FilterTree {
  return {
    ...tree,
    root: removeConditionFromGroup(tree.root, conditionId)
  }
}

function removeConditionFromGroup(
  group: FilterGroupNode,
  targetId: string
): FilterGroupNode {
  return {
    ...group,
    children: group.children
      .filter(child => {
        if (child.type === 'condition' && child.id === targetId) {
          return false
        }
        return true
      })
      .map(child => {
        if (child.type === 'group') {
          return removeConditionFromGroup(child, targetId)
        }
        return child
      })
  }
}

/**
 * Updates a condition in the tree
 */
export function updateCondition(
  tree: FilterTree,
  conditionId: string,
  updates: Partial<FilterConditionNode>
): FilterTree {
  return {
    ...tree,
    root: updateConditionInGroup(tree.root, conditionId, updates)
  }
}

function updateConditionInGroup(
  group: FilterGroupNode,
  targetId: string,
  updates: Partial<FilterConditionNode>
): FilterGroupNode {
  return {
    ...group,
    children: group.children.map(child => {
      if (child.type === 'condition' && child.id === targetId) {
        return { ...child, ...updates }
      }
      if (child.type === 'group') {
        return updateConditionInGroup(child, targetId, updates)
      }
      return child
    })
  }
}

/**
 * Adds a nested group to a parent group
 */
export function addGroup(
  tree: FilterTree,
  parentId: string,
  group: FilterGroupNode = createEmptyGroup()
): FilterTree {
  return {
    ...tree,
    root: addGroupToParent(tree.root, parentId, group)
  }
}

function addGroupToParent(
  group: FilterGroupNode,
  targetId: string,
  newGroup: FilterGroupNode
): FilterGroupNode {
  if (group.id === targetId) {
    return {
      ...group,
      children: [...group.children, newGroup]
    }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (child.type === 'group') {
        return addGroupToParent(child, targetId, newGroup)
      }
      return child
    })
  }
}

/**
 * Removes a group from the tree
 */
export function removeGroup(tree: FilterTree, groupId: string): FilterTree {
  // Can't remove the root group
  if (groupId === tree.root.id) {
    return tree
  }

  return {
    ...tree,
    root: removeGroupFromParent(tree.root, groupId)
  }
}

function removeGroupFromParent(
  group: FilterGroupNode,
  targetId: string
): FilterGroupNode {
  return {
    ...group,
    children: group.children
      .filter(child => {
        if (child.type === 'group' && child.id === targetId) {
          return false
        }
        return true
      })
      .map(child => {
        if (child.type === 'group') {
          return removeGroupFromParent(child, targetId)
        }
        return child
      })
  }
}

/**
 * Updates a group's operator
 */
export function updateGroupOperator(
  tree: FilterTree,
  groupId: string,
  operator: GroupOperator
): FilterTree {
  return {
    ...tree,
    root: updateGroupOperatorInGroup(tree.root, groupId, operator)
  }
}

function updateGroupOperatorInGroup(
  group: FilterGroupNode,
  targetId: string,
  operator: GroupOperator
): FilterGroupNode {
  if (group.id === targetId) {
    return { ...group, operator }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (child.type === 'group') {
        return updateGroupOperatorInGroup(child, targetId, operator)
      }
      return child
    })
  }
}

/**
 * Finds a node by ID
 */
export function findNode(tree: FilterTree, nodeId: string): FilterNode | null {
  return findNodeInGroup(tree.root, nodeId)
}

function findNodeInGroup(group: FilterGroupNode, nodeId: string): FilterNode | null {
  for (const child of group.children) {
    if (child.id === nodeId) {
      return child
    }
    if (child.type === 'group') {
      const found = findNodeInGroup(child, nodeId)
      if (found) return found
    }
  }
  return null
}

/**
 * Gets the parent of a node
 */
export function getParent(
  tree: FilterTree,
  nodeId: string
): FilterGroupNode | null {
  return getParentInGroup(tree.root, nodeId, null)
}

function getParentInGroup(
  group: FilterGroupNode,
  nodeId: string,
  parent: FilterGroupNode | null
): FilterGroupNode | null {
  for (const child of group.children) {
    if (child.id === nodeId) {
      return group
    }
    if (child.type === 'group') {
      const found = getParentInGroup(child, nodeId, group)
      if (found) return found
    }
  }
  return parent
}

/**
 * Calculates the depth of a group in the tree
 */
export function getGroupDepth(tree: FilterTree, groupId: string): number {
  return getGroupDepthInGroup(tree.root, groupId, 0)
}

function getGroupDepthInGroup(
  group: FilterGroupNode,
  targetId: string,
  currentDepth: number
): number {
  if (group.id === targetId) {
    return currentDepth
  }

  for (const child of group.children) {
    if (child.type === 'group') {
      const depth = getGroupDepthInGroup(child, targetId, currentDepth + 1)
      if (depth >= 0) return depth
    }
  }

  return -1
}

/**
 * Counts total conditions in the tree
 */
export function countConditions(tree: FilterTree): number {
  return countConditionsInGroup(tree.root)
}

function countConditionsInGroup(group: FilterGroupNode): number {
  let count = 0
  for (const child of group.children) {
    if (child.type === 'condition') {
      count++
    } else if (child.type === 'group') {
      count += countConditionsInGroup(child)
    }
  }
  return count
}

/**
 * Checks if we can add more conditions (max 100)
 */
export function canAddCondition(tree: FilterTree): boolean {
  return countConditions(tree) < 100
}

/**
 * Checks if we can add a nested group (max depth 5)
 */
export function canAddGroup(tree: FilterTree, parentId: string): boolean {
  return getGroupDepth(tree, parentId) < 4 // 0-indexed, so 4 = 5 levels
}

/**
 * Serializes the filter tree to JSON string
 */
export function serializeTree(tree: FilterTree): string {
  return JSON.stringify(tree)
}

/**
 * Parses a JSON string to filter tree
 */
export function parseTree(json: string): FilterTree | null {
  try {
    const parsed = JSON.parse(json)
    if (parsed.version && parsed.root) {
      return parsed as FilterTree
    }
    return null
  } catch {
    return null
  }
}

/**
 * Generates a unique ID for nodes
 */
function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`
}
