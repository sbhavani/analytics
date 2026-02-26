import {
  FilterCondition,
  FilterGroup,
  FilterTree,
  FilterTreeNode,
  ApiFilterGroup,
  ApiFilterCondition,
  ApiFilterTreeNode
} from './types'

/**
 * Generates a unique ID for filter conditions and groups.
 */
function generateId(): string {
  return crypto.randomUUID()
}

/**
 * Creates a new FilterCondition with a unique ID.
 */
export function createCondition(
  dimension: string = '',
  operator: string = '',
  value: string | string[] = ''
): FilterCondition {
  const stringValue = Array.isArray(value) ? value.join(', ') : value
  return {
    id: generateId(),
    dimension,
    operator,
    value: stringValue
  }
}

/**
 * Creates a new FilterGroup with a unique ID.
 */
export function createGroup(
  operator: 'and' | 'or' = 'and',
  children: FilterTreeNode[] = []
): FilterGroup {
  return {
    id: generateId(),
    operator,
    children,
  }
}

/**
 * Validates a single filter condition.
 * Returns an error message if invalid, undefined if valid.
 */
export function validateCondition(condition: FilterCondition): string | undefined {
  if (!condition.dimension) {
    return 'Please select a field'
  }

  if (!condition.operator) {
    return 'Please select an operator'
  }

  const isValueRequired = !['is_not', 'contains_not', 'has_not_done'].includes(
    condition.operator
  )

  if (isValueRequired) {
    if (Array.isArray(condition.value)) {
      if (condition.value.length === 0) {
        return 'Please enter at least one value'
      }
    } else if (!condition.value || condition.value.trim() === '') {
      return 'Please enter a value'
    }
  }

  return undefined
}

/**
 * Serializes a filter tree to JSON for API submission.
 * Converts internal FilterGroup structure to the API format.
 * Removes internal IDs from the output.
 *
 * @param rootGroup - The root FilterGroup to serialize
 * @returns JSON string suitable for API submission
 */
export function serializeFilterTree(rootGroup: FilterGroup): string {
  const apiFormat = convertToApiFormat(rootGroup)
  return JSON.stringify(apiFormat)
}

/**
 * Recursively converts internal FilterTreeNode to API format.
 * Removes internal IDs from the output.
 */
function convertToApiFormat(node: FilterTreeNode): ApiFilterTreeNode {
  if ('children' in node) {
    // It's a FilterGroup
    return {
      operator: node.operator,
      children: node.children.map(convertToApiFormat),
    } as ApiFilterGroup
  } else {
    // It's a FilterCondition
    return {
      dimension: node.dimension,
      operator: node.operator,
      value: node.value,
    } as ApiFilterCondition
  }
}

/**
 * Deserializes a filter tree from the API response format.
 * The API returns: { operator: "and", children: [...] }
 * We convert it to the internal FilterGroup structure with unique IDs.
 */
export function deserializeFilterTree(apiFilter: ApiFilterGroup): FilterTree {
  return deserializeGroup(apiFilter)
}

function deserializeGroup(apiGroup: ApiFilterGroup): FilterGroup {
  return {
    id: generateId(),
    operator: apiGroup.operator,
    children: apiGroup.children.map((child) => deserializeNode(child))
  }
}

function deserializeNode(node: ApiFilterTreeNode): FilterCondition | FilterGroup {
  // Check if it's a group (has operator and children)
  if ('operator' in node && 'children' in node) {
    return deserializeGroup(node as ApiFilterGroup)
  }

  // Otherwise, it's a condition in the legacy array format: ['is', 'country', ['US']]
  // or object format: { dimension, operator, value }
  if (Array.isArray(node)) {
    return deserializeConditionFromArray(node)
  }

  // Object format: { dimension, operator, value }
  return deserializeConditionFromObject(node)
}

function deserializeConditionFromArray(arr: unknown[]): FilterCondition {
  // Legacy API format: ['is', 'country', ['US']]
  const [operation, dimension, clauses] = arr

  return createCondition(
    String(dimension || ''),
    mapApiOperationToOperator(String(operation || '')),
    Array.isArray(clauses) ? clauses.join(', ') : ''
  )
}

function deserializeConditionFromObject(obj: ApiFilterCondition): FilterCondition {
  return createCondition(
    obj.dimension,
    obj.operator,
    obj.value
  )
}

function mapApiOperationToOperator(apiOperation: string): string {
  const operationMap: Record<string, string> = {
    is: 'is',
    is_not: 'is_not',
    contains: 'contains',
    contains_not: 'contains_not',
    has_not_done: 'has_not_done'
  }
  return operationMap[apiOperation] || 'is'
}
