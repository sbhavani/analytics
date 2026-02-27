// Jest tests for filterTreeUtils

import {
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

import type { FilterTree, FilterCondition, FilterGroup } from './types'

describe('filterTreeUtils', () => {
  describe('createFilterTree', () => {
    it('should create an empty filter tree with root group', () => {
      const tree = createFilterTree()

      expect(tree.rootGroup).toBeDefined()
      expect(tree.rootGroup.operator).toBe('and')
      expect(tree.rootGroup.children).toEqual([])
      expect(tree.version).toBe(1)
    })
  })

  describe('createFilterGroup', () => {
    it('should create a filter group with default AND operator', () => {
      const group = createFilterGroup()

      expect(group.id).toBeDefined()
      expect(group.operator).toBe('and')
      expect(group.children).toEqual([])
    })

    it('should create a filter group with specified OR operator', () => {
      const group = createFilterGroup('or')

      expect(group.operator).toBe('or')
    })
  })

  describe('createFilterCondition', () => {
    it('should create a filter condition with defaults', () => {
      const condition = createFilterCondition()

      expect(condition.id).toBeDefined()
      expect(condition.dimension).toBe('')
      expect(condition.operator).toBe('is')
      expect(condition.values).toEqual([])
    })

    it('should create a filter condition with specified values', () => {
      const condition = createFilterCondition('country', 'is', ['US', 'UK'])

      expect(condition.dimension).toBe('country')
      expect(condition.operator).toBe('is')
      expect(condition.values).toEqual(['US', 'UK'])
    })
  })

  describe('addCondition', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = createFilterTree()
    })

    it('should add a condition to root group', () => {
      const newTree = addCondition(tree, { dimension: 'country', values: ['US'] })

      expect(newTree.rootGroup.children.length).toBe(1)
      expect(newTree.rootGroup.children[0].dimension).toBe('country')
      expect(newTree.rootGroup.children[0].values).toEqual(['US'])
    })

    it('should add multiple conditions to root group', () => {
      let newTree = addCondition(tree, { dimension: 'country', values: ['US'] })
      newTree = addCondition(newTree, { dimension: 'device', values: ['mobile'] })

      expect(newTree.rootGroup.children.length).toBe(2)
    })

    it('should not mutate original tree', () => {
      addCondition(tree, { dimension: 'country', values: ['US'] })

      expect(tree.rootGroup.children.length).toBe(0)
    })
  })

  describe('addGroup', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = createFilterTree()
    })

    it('should add a nested group to root', () => {
      const newTree = addGroup(tree, 'or')

      expect(newTree.rootGroup.children.length).toBe(1)
      expect(newTree.rootGroup.children[0]).toHaveProperty('operator', 'or')
    })

    it('should add a group with conditions', () => {
      let newTree = addGroup(tree, 'or')
      const nestedGroupId = newTree.rootGroup.children[0].id
      newTree = addCondition(newTree, { dimension: 'browser', values: ['Chrome'] }, nestedGroupId)

      const nestedGroup = findGroup(newTree.rootGroup, nestedGroupId)
      expect(nestedGroup?.children.length).toBe(1)
    })

    it('should throw when max depth exceeded', () => {
      let newTree = tree
      // Add nested groups up to max depth
      for (let i = 0; i < MAX_NESTING_DEPTH; i++) {
        const parentId = newTree.rootGroup.children.length > 0
          ? (newTree.rootGroup.children[0] as FilterGroup).id
          : undefined
        newTree = addGroup(newTree, 'and', parentId)
      }

      expect(() => addGroup(newTree, 'or', newTree.rootGroup.id)).toThrow()
    })
  })

  describe('removeItem', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = addCondition(tree, { dimension: 'device', values: ['mobile'] })
    })

    it('should remove a condition by id', () => {
      const conditionId = (tree.rootGroup.children[0] as FilterCondition).id
      const newTree = removeItem(tree, conditionId)

      expect(newTree.rootGroup.children.length).toBe(1)
    })
  })

  describe('deleteGroup', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = addGroup(createFilterTree(), 'or')
      tree = addCondition(tree, { dimension: 'country', values: ['US'] })
    })

    it('should delete a nested group', () => {
      const groupId = (tree.rootGroup.children[0] as FilterGroup).id
      const newTree = deleteGroup(tree, groupId)

      expect(newTree.rootGroup.children.length).toBe(1) // The condition remains
    })

    it('should not delete root group', () => {
      const newTree = deleteGroup(tree, tree.rootGroup.id)

      expect(newTree.rootGroup.id).toBe(tree.rootGroup.id)
    })
  })

  describe('updateCondition', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
    })

    it('should update condition values', () => {
      const conditionId = (tree.rootGroup.children[0] as FilterCondition).id
      const newTree = updateCondition(tree, conditionId, { values: ['UK'] })

      const condition = newTree.rootGroup.children[0] as FilterCondition
      expect(condition.values).toEqual(['UK'])
    })

    it('should update condition operator', () => {
      const conditionId = (tree.rootGroup.children[0] as FilterCondition).id
      const newTree = updateCondition(tree, conditionId, { operator: 'contains' })

      const condition = newTree.rootGroup.children[0] as FilterCondition
      expect(condition.operator).toBe('contains')
    })
  })

  describe('changeGroupOperator', () => {
    let tree: FilterTree

    beforeEach(() => {
      tree = addGroup(createFilterTree(), 'and')
      tree = addCondition(tree, { dimension: 'country', values: ['US'] })
    })

    it('should change group operator from and to or', () => {
      const groupId = (tree.rootGroup.children[0] as FilterGroup).id
      const newTree = changeGroupOperator(tree, groupId, 'or')

      const group = findGroup(newTree.rootGroup, groupId)
      expect(group?.operator).toBe('or')
    })
  })

  describe('getGroupDepth', () => {
    it('should return 1 for flat group', () => {
      const tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      expect(getGroupDepth(tree.rootGroup)).toBe(1)
    })

    it('should return 2 for single nesting', () => {
      let tree = addGroup(createFilterTree(), 'or')
      const groupId = (tree.rootGroup.children[0] as FilterGroup).id
      tree = addGroup(tree, 'and', groupId)

      expect(getGroupDepth(tree.rootGroup)).toBe(2)
    })
  })

  describe('validateFilterTree', () => {
    it('should return error for empty tree', () => {
      const tree = createFilterTree()
      const result = validateFilterTree(tree)

      expect(result.valid).toBe(false)
      expect(result.errors).toContain('Filter tree must have at least one condition')
    })

    it('should return valid for tree with conditions', () => {
      const tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      const result = validateFilterTree(tree)

      expect(result.valid).toBe(true)
      expect(result.errors).toEqual([])
    })

    it('should return error for missing dimension', () => {
      const tree = addCondition(createFilterTree(), { dimension: '', values: ['US'] })
      const result = validateFilterTree(tree)

      expect(result.valid).toBe(false)
      expect(result.errors.some(e => e.includes('missing dimension'))).toBe(true)
    })

    it('should return error for missing value', () => {
      const tree = addCondition(createFilterTree(), { dimension: 'country', values: [] })
      const result = validateFilterTree(tree)

      expect(result.valid).toBe(false)
      expect(result.errors.some(e => e.includes('missing value'))).toBe(true)
    })
  })

  describe('countFilters', () => {
    it('should count all conditions including nested', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = addGroup(tree, 'or')
      const nestedGroupId = (tree.rootGroup.children[1] as FilterGroup).id
      tree = addCondition(tree, { dimension: 'device', values: ['mobile'] }, nestedGroupId)
      tree = addCondition(tree, { dimension: 'browser', values: ['Chrome'] }, nestedGroupId)

      expect(countFilters(tree)).toBe(3)
    })
  })

  describe('serializeFilterTree', () => {
    it('should serialize simple filter', () => {
      const tree = addCondition(createFilterTree(), { dimension: 'country', operator: 'is', values: ['US'] })
      const serialized = serializeFilterTree(tree)

      expect(serialized).toEqual([['is', 'country', ['US']]])
    })

    it('should serialize multiple filters as AND', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = addCondition(tree, { dimension: 'device', values: ['mobile'] })
      const serialized = serializeFilterTree(tree)

      expect(serialized).toEqual([
        ['is', 'country', ['US']],
        ['is', 'device', ['mobile']]
      ])
    })

    it('should serialize nested groups', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = addGroup(tree, 'or')
      const groupId = (tree.rootGroup.children[1] as FilterGroup).id
      tree = addCondition(tree, { dimension: 'device', values: ['mobile'] }, groupId)

      const serialized = serializeFilterTree(tree)

      expect(serialized).toEqual([
        ['is', 'country', ['US']],
        ['or', [
          ['is', 'device', ['mobile']]
        ]]
      ])
    })
  })

  describe('deserializeFilterTree', () => {
    it('should deserialize simple filter', () => {
      const filters = [['is', 'country', ['US']]] as const
      const tree = deserializeFilterTree(filters as any)

      expect(tree.rootGroup.children.length).toBe(1)
      const condition = tree.rootGroup.children[0]
      expect(isFilterGroup(condition)).toBe(false)
      expect((condition as FilterCondition).dimension).toBe('country')
      expect((condition as FilterCondition).values).toEqual(['US'])
    })

    it('should deserialize empty array to empty tree', () => {
      const tree = deserializeFilterTree([])

      expect(tree.rootGroup.children).toEqual([])
    })

    it('should deserialize nested groups', () => {
      const filters = [
        ['is', 'country', ['US']],
        ['or', [
          ['is', 'device', ['mobile']],
          ['is', 'browser', ['Chrome']]
        ]]
      ] as const

      const tree = deserializeFilterTree(filters as any)

      expect(tree.rootGroup.children.length).toBe(2)
    })
  })

  describe('getUsedDimensions', () => {
    it('should return all unique dimensions', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = addCondition(tree, { dimension: 'device', values: ['mobile'] })
      tree = addCondition(tree, { dimension: 'country', values: ['UK'] })

      const dimensions = getUsedDimensions(tree)
      expect(dimensions).toEqual(['country', 'device'])
    })
  })

  describe('clearAllFilters', () => {
    it('should return new empty tree', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      tree = clearAllFilters()

      expect(tree.rootGroup.children).toEqual([])
    })
  })

  describe('findParentGroup', () => {
    it('should find parent group of condition', () => {
      let tree = addCondition(createFilterTree(), { dimension: 'country', values: ['US'] })
      const conditionId = (tree.rootGroup.children[0] as FilterCondition).id

      const parent = findParentGroup(tree, conditionId)

      expect(parent?.id).toBe(tree.rootGroup.id)
    })
  })

  describe('isFilterGroup', () => {
    it('should return true for FilterGroup', () => {
      const group = createFilterGroup()
      expect(isFilterGroup(group)).toBe(true)
    })

    it('should return false for FilterCondition', () => {
      const condition = createFilterCondition()
      expect(isFilterGroup(condition)).toBe(false)
    })
  })
})
