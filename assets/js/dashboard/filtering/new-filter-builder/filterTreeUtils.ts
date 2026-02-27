// Filter Tree Utility Functions

import { Filter, FilterClause } from '../dashboard-state'
import { FILTER_OPERATIONS } from '../util/filters'
import type {
  FilterCondition,
  FilterGroup,
  FilterTree,
  FilterOperator,
  GroupOperator,
  SerializedFilter
} from './types'

const generateId = (): string => {
  return Math.random().toString(36).substring(2, 15)
}

export const MAX_NESTING_DEPTH = 3

// Create a new empty filter tree
export const createFilterTree = (): FilterTree => ({
  rootGroup: createFilterGroup('and'),
  version: 1
})

// Create a new filter group
export const createFilterGroup = (operator: GroupOperator = 'and'): FilterGroup => ({
  id: generateId(),
  operator,
  children: []
})

// Create a new filter condition
export const createFilterCondition = (
  dimension: string = '',
  operator: FilterOperator = FILTER_OPERATIONS.is as FilterOperator,
  values: string[] = []
): FilterCondition => ({
  id: generateId(),
  dimension,
  operator,
  values
})

// Add a condition to a group
export const addCondition = (
  tree: FilterTree,
  condition: Partial<FilterCondition>,
  targetGroupId?: string
): FilterTree => {
  const newCondition = createFilterCondition(
    condition.dimension,
    condition.operator,
    condition.values
  )

  if (!targetGroupId) {
    // Add to root group
    return {
      ...tree,
      rootGroup: {
        ...tree.rootGroup,
        children: [...tree.rootGroup.children, newCondition]
      }
    }
  }

  // Add to specific group (recursive)
  return {
    ...tree,
    rootGroup: addConditionToGroup(tree.rootGroup, targetGroupId, newCondition)
  }
}

const addConditionToGroup = (
  group: FilterGroup,
  targetGroupId: string,
  condition: FilterCondition
): FilterGroup => {
  if (group.id === targetGroupId) {
    return {
      ...group,
      children: [...group.children, condition]
    }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (isFilterGroup(child)) {
        return addConditionToGroup(child, targetGroupId, condition)
      }
      return child
    })
  }
}

// Add a nested group
export const addGroup = (
  tree: FilterTree,
  operator: GroupOperator = 'or',
  parentGroupId?: string
): FilterTree => {
  const depth = getGroupDepth(tree.rootGroup)

  if (depth >= MAX_NESTING_DEPTH) {
    throw new Error(`Maximum nesting depth of ${MAX_NESTING_DEPTH} exceeded`)
  }

  const newGroup = createFilterGroup(operator)

  if (!parentGroupId) {
    // Add to root group
    return {
      ...tree,
      rootGroup: {
        ...tree.rootGroup,
        children: [...tree.rootGroup.children, newGroup]
      }
    }
  }

  // Add to specific parent group
  return {
    ...tree,
    rootGroup: addGroupToParent(tree.rootGroup, parentGroupId, newGroup)
  }
}

const addGroupToParent = (
  group: FilterGroup,
  parentGroupId: string,
  newGroup: FilterGroup
): FilterGroup => {
  if (group.id === parentGroupId) {
    return {
      ...group,
      children: [...group.children, newGroup]
    }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (isFilterGroup(child)) {
        return addGroupToParent(child, parentGroupId, newGroup)
      }
      return child
    })
  }
}

// Remove a condition or group by ID
export const removeItem = (tree: FilterTree, itemId: string): FilterTree => {
  return {
    ...tree,
    rootGroup: removeItemFromGroup(tree.rootGroup, itemId)
  }
}

const removeItemFromGroup = (group: FilterGroup, itemId: string): FilterGroup => {
  const filteredChildren = group.children.filter(child => {
    if (isFilterGroup(child)) {
      return child.id !== itemId
    }
    return child.id !== itemId
  })

  // Recursively remove from nested groups
  const childrenWithNestedRemoved = filteredChildren.map(child => {
    if (isFilterGroup(child)) {
      return removeItemFromGroup(child, itemId)
    }
    return child
  })

  return {
    ...group,
    children: childrenWithNestedRemoved
  }
}

// Delete an entire group (and all its contents)
export const deleteGroup = (tree: FilterTree, groupId: string): FilterTree => {
  // Can't delete root group
  if (groupId === tree.rootGroup.id) {
    return tree
  }

  return {
    ...tree,
    rootGroup: deleteGroupFromGroup(tree.rootGroup, groupId)
  }
}

const deleteGroupFromGroup = (group: FilterGroup, groupId: string): FilterGroup => {
  // Filter out the group to delete
  const children = group.children
    .filter(child => {
      if (isFilterGroup(child)) {
        return child.id !== groupId
      }
      return true
    })
    .map(child => {
      if (isFilterGroup(child)) {
        return deleteGroupFromGroup(child, groupId)
      }
      return child
    })

  return { ...group, children }
}

// Update a condition
export const updateCondition = (
  tree: FilterTree,
  conditionId: string,
  updates: Partial<FilterCondition>
): FilterTree => {
  return {
    ...tree,
    rootGroup: updateConditionInGroup(tree.rootGroup, conditionId, updates)
  }
}

const updateConditionInGroup = (
  group: FilterGroup,
  conditionId: string,
  updates: Partial<FilterCondition>
): FilterGroup => {
  return {
    ...group,
    children: group.children.map(child => {
      if (!isFilterGroup(child) && child.id === conditionId) {
        return { ...child, ...updates }
      }
      if (isFilterGroup(child)) {
        return updateConditionInGroup(child, conditionId, updates)
      }
      return child
    })
  }
}

// Change group operator (AND/OR)
export const changeGroupOperator = (
  tree: FilterTree,
  groupId: string,
  newOperator: GroupOperator
): FilterTree => {
  return {
    ...tree,
    rootGroup: changeOperatorInGroup(tree.rootGroup, groupId, newOperator)
  }
}

const changeOperatorInGroup = (
  group: FilterGroup,
  groupId: string,
  newOperator: GroupOperator
): FilterGroup => {
  if (group.id === groupId) {
    return { ...group, operator: newOperator }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (isFilterGroup(child)) {
        return changeOperatorInGroup(child, groupId, newOperator)
      }
      return child
    })
  }
}

// Move an item within a group (for drag-and-drop reordering)
export const moveItem = (
  tree: FilterTree,
  itemId: string,
  newIndex: number,
  targetGroupId?: string
): FilterTree => {
  const group = targetGroupId ? findGroup(tree.rootGroup, targetGroupId) : tree.rootGroup

  if (!group) return tree

  const currentIndex = group.children.findIndex(child => child.id === itemId)
  if (currentIndex === -1) return tree

  const newChildren = [...group.children]
  const [removed] = newChildren.splice(currentIndex, 1)
  newChildren.splice(newIndex, 0, removed)

  if (targetGroupId && targetGroupId !== tree.rootGroup.id) {
    return {
      ...tree,
      rootGroup: replaceGroupChildren(tree.rootGroup, targetGroupId, newChildren)
    }
  }

  return {
    ...tree,
    rootGroup: { ...tree.rootGroup, children: newChildren }
  }
}

const replaceGroupChildren = (
  group: FilterGroup,
  groupId: string,
  children: (FilterGroup | FilterCondition)[]
): FilterGroup => {
  if (group.id === groupId) {
    return { ...group, children }
  }

  return {
    ...group,
    children: group.children.map(child => {
      if (isFilterGroup(child)) {
        return replaceGroupChildren(child, groupId, children)
      }
      return child
    })
  }
}

// Find a group by ID
export const findGroup = (group: FilterGroup, groupId: string): FilterGroup | null => {
  if (group.id === groupId) return group

  for (const child of group.children) {
    if (isFilterGroup(child)) {
      const found = findGroup(child, groupId)
      if (found) return found
    }
  }

  return null
}

// Get the depth of nesting
export const getGroupDepth = (group: FilterGroup): number => {
  let maxDepth = 1

  for (const child of group.children) {
    if (isFilterGroup(child)) {
      const childDepth = getGroupDepth(child) + 1
      maxDepth = Math.max(maxDepth, childDepth)
    }
  }

  return maxDepth
}

// Check if item is a FilterGroup
export const isFilterGroup = (item: FilterGroup | FilterCondition): item is FilterGroup => {
  return 'operator' in item && 'children' in item
}

// Validate the filter tree
export const validateFilterTree = (tree: FilterTree): { valid: boolean; errors: string[] } => {
  const errors: string[] = []

  // Check root group has children
  if (tree.rootGroup.children.length === 0) {
    errors.push('Filter tree must have at least one condition')
  }

  // Check depth
  const depth = getGroupDepth(tree.rootGroup)
  if (depth > MAX_NESTING_DEPTH) {
    errors.push(`Maximum nesting depth of ${MAX_NESTING_DEPTH} exceeded`)
  }

  // Validate each condition
  const validateCondition = (condition: FilterCondition, path: string) => {
    if (!condition.dimension) {
      errors.push(`Condition at ${path} missing dimension`)
    }
    if (!condition.operator) {
      errors.push(`Condition at ${path} missing operator`)
    }
    // Value is required unless operator is is_set or is_not_set
    if (!['is_set', 'is_not_set'].includes(condition.operator) && condition.values.length === 0) {
      errors.push(`Condition at ${path} missing value`)
    }
  }

  const validateGroup = (group: FilterGroup, path: string) => {
    if (group.children.length === 0) {
      errors.push(`Group at ${path} has no children`)
    }

    group.children.forEach((child, index) => {
      if (isFilterGroup(child)) {
        validateGroup(child, `${path}/group[${index}]`)
      } else {
        validateCondition(child, `${path}/condition[${index}]`)
      }
    })
  }

  validateGroup(tree.rootGroup, 'root')

  return { valid: errors.length === 0, errors }
}

// Count total filters in tree
export const countFilters = (tree: FilterTree): number => {
  return countFiltersInGroup(tree.rootGroup)
}

const countFiltersInGroup = (group: FilterGroup): number => {
  return group.children.reduce((count, child) => {
    if (isFilterGroup(child)) {
      return count + countFiltersInGroup(child)
    }
    return count + 1
  }, 0)
}

// Serialize filter tree to legacy flat array format
export const serializeFilterTree = (tree: FilterTree): Filter[] => {
  return serializeGroup(tree.rootGroup)
}

const serializeGroup = (group: FilterGroup): Filter[] => {
  const serializedChildren = group.children.map(child => {
    if (isFilterGroup(child)) {
      const nested = serializeGroup(child)
      if (nested.length === 1) {
        return [group.operator as FilterOperator, ...nested[0]] as Filter
      }
      return [group.operator as FilterOperator, nested] as Filter
    }
    return [child.operator, child.dimension, child.values] as Filter
  })

  return serializedChildren
}

// Deserialize flat filter array to filter tree
export const deserializeFilterTree = (filters: Filter[]): FilterTree => {
  if (filters.length === 0) {
    return createFilterTree()
  }

  const rootGroup = deserializeToGroup(filters, 'and')
  return {
    rootGroup,
    version: 1
  }
}

const deserializeToGroup = (filters: Filter[], defaultOperator: GroupOperator): FilterGroup => {
  // Check if this is a group with explicit operator
  if (filters.length === 1 && Array.isArray(filters[0][1])) {
    const [op, children] = filters[0] as [GroupOperator, Filter[]]
    return {
      id: generateId(),
      operator: op,
      children: children.map(child => {
        if (isNestedFilter(child)) {
          return deserializeToGroup([child], 'and')
        }
        return deserializeCondition(child)
      })
    }
  }

  // Check if filters use AND/OR operators
  const hasAnd = filters.some(f => f[0] === 'and')
  const hasOr = filters.some(f => f[0] === 'or')

  if (hasAnd || hasOr) {
    // This is a mixed group
    const children: (FilterGroup | FilterCondition)[] = []
    let currentOp: GroupOperator = 'and'

    for (const filter of filters) {
      if (filter[0] === 'and' || filter[0] === 'or') {
        if (Array.isArray(filter[1])) {
          currentOp = filter[0]
          const nestedFilters = filter[1] as Filter[]
          children.push(deserializeToGroup(nestedFilters, currentOp))
        }
      } else {
        children.push(deserializeCondition(filter))
      }
    }

    return {
      id: generateId(),
      operator: defaultOperator,
      children
    }
  }

  // Simple flat filters - all implicitly ANDed
  return {
    id: generateId(),
    operator: 'and',
    children: filters.map(deserializeCondition)
  }
}

const deserializeCondition = (filter: Filter): FilterCondition => {
  const [operator, dimension, values] = filter
  return {
    id: generateId(),
    operator: operator as FilterOperator,
    dimension: dimension as string,
    values: values as string[]
  }
}

const isNestedFilter = (filter: Filter): boolean => {
  return Array.isArray(filter[1])
}

// Get all dimensions used in the tree
export const getUsedDimensions = (tree: FilterTree): string[] => {
  const dimensions = new Set<string>()

  const scanGroup = (group: FilterGroup) => {
    for (const child of group.children) {
      if (isFilterGroup(child)) {
        scanGroup(child)
      } else {
        dimensions.add(child.dimension)
      }
    }
  }

  scanGroup(tree.rootGroup)
  return Array.from(dimensions)
}

// Clear all filters
export const clearAllFilters = (): FilterTree => {
  return createFilterTree()
}

// Find parent group of an item
export const findParentGroup = (
  tree: FilterTree,
  itemId: string
): FilterGroup | null => {
  return findParentGroupOfItem(tree.rootGroup, itemId)
}

const findParentGroupOfItem = (
  group: FilterGroup,
  itemId: string
): FilterGroup | null => {
  for (const child of group.children) {
    if (child.id === itemId) {
      return group
    }
    if (isFilterGroup(child)) {
      const found = findParentGroupOfItem(child, itemId)
      if (found) return found
    }
  }
  return null
}
