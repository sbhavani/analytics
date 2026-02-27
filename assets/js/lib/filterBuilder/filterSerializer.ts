import { FilterTree } from './types'

export function serializeForAPI(tree: FilterTree): object {
  return JSON.stringify(tree)
}

export function deserializeFromAPI(json: string): FilterTree {
  try {
    const parsed = JSON.parse(json)
    if (parsed.rootGroup) {
      return parsed as FilterTree
    }
    throw new Error('Invalid filter tree structure')
  } catch (e) {
    console.error('Failed to deserialize filter tree:', e)
    throw e
  }
}

export function serializeForStorage(tree: FilterTree): string {
  return JSON.stringify(tree)
}

export function deserializeFromStorage(str: string): FilterTree {
  return deserializeFromAPI(str)
}

export function serializeConditionValue(value: string, operator: string): string {
  if (operator === 'is_one_of' || operator === 'is_not_one_of') {
    return value.split(',').map((v) => v.trim()).join('|')
  }
  return value
}

export function deserializeConditionValue(value: string, operator: string): string {
  if (operator === 'is_one_of' || operator === 'is_not_one_of') {
    return value.split('|').join(', ')
  }
  return value
}

export function escapeFilterValue(value: string): string {
  return value
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t')
}

export function unescapeFilterValue(value: string): string {
  return value
    .replace(/\\t/g, '\t')
    .replace(/\\r/g, '\r')
    .replace(/\\n/g, '\n')
    .replace(/\\"/g, '"')
    .replace(/\\\\/g, '\\')
}
