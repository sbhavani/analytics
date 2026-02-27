/**
 * @jest-environment jsdom
 */

import {
  createEmptyTree,
  createEmptyGroup,
  createCondition,
  addCondition,
  removeCondition,
  updateCondition,
  addGroup,
  removeGroup,
  updateGroupOperator,
  findNode,
  getGroupDepth,
  countConditions,
  canAddCondition,
  canAddGroup,
  serializeTree,
  parseTree
} from '../assets/js/lib/filter-tree'

describe('Filter Tree Utilities', () => {
  describe('createEmptyTree', () => {
    it('creates a tree with version 1 and empty root group', () => {
      const tree = createEmptyTree()

      expect(tree.version).toBe(1)
      expect(tree.root).toBeDefined()
      expect(tree.root.type).toBe('group')
      expect(tree.root.operator).toBe('and')
      expect(tree.root.children).toEqual([])
      expect(tree.root.id).toBeDefined()
    })
  })

  describe('createEmptyGroup', () => {
    it('creates an empty group with default AND operator', () => {
      const group = createEmptyGroup()

      expect(group.type).toBe('group')
      expect(group.operator).toBe('and')
      expect(group.children).toEqual([])
      expect(group.id).toBeDefined()
    })

    it('creates an empty group with specified OR operator', () => {
      const group = createEmptyGroup('or')

      expect(group.operator).toBe('or')
    })
  })

  describe('createCondition', () => {
    it('creates a condition with defaults', () => {
      const condition = createCondition()

      expect(condition.type).toBe('condition')
      expect(condition.attribute).toBe('')
      expect(condition.operator).toBe('is')
      expect(condition.value).toBe('')
      expect(condition.negated).toBe(false)
      expect(condition.id).toBeDefined()
    })

    it('creates a condition with specified values', () => {
      const condition = createCondition('visit:country', 'is', 'US')

      expect(condition.attribute).toBe('visit:country')
      expect(condition.operator).toBe('is')
      expect(condition.value).toBe('US')
    })
  })

  describe('addCondition', () => {
    it('adds a condition to the root group', () => {
      const tree = createEmptyTree()
      const condition = createCondition('visit:country', 'is', 'US')

      const newTree = addCondition(tree, tree.root.id, condition)

      expect(newTree.root.children).toHaveLength(1)
      expect(newTree.root.children[0]).toEqual(condition)
    })
  })

  describe('removeCondition', () => {
    it('removes a condition from the tree', () => {
      const tree = createEmptyTree()
      const condition = createCondition('visit:country', 'is', 'US')
      const treeWithCondition = addCondition(tree, tree.root.id, condition)

      const newTree = removeCondition(treeWithCondition, condition.id)

      expect(newTree.root.children).toHaveLength(0)
    })
  })

  describe('updateCondition', () => {
    it('updates condition values', () => {
      const tree = createEmptyTree()
      const condition = createCondition('visit:country', 'is', 'US')
      const treeWithCondition = addCondition(tree, tree.root.id, condition)

      const newTree = updateCondition(treeWithCondition, condition.id, { value: 'GB' })
      const updatedCondition = newTree.root.children[0]

      expect(updatedCondition.value).toBe('GB')
      expect(updatedCondition.attribute).toBe('visit:country')
    })
  })

  describe('addGroup', () => {
    it('adds a nested group to the root', () => {
      const tree = createEmptyTree()
      const nestedGroup = createEmptyGroup('or')

      const newTree = addGroup(tree, tree.root.id, nestedGroup)

      expect(newTree.root.children).toHaveLength(1)
      expect(newTree.root.children[0]).toEqual(nestedGroup)
    })
  })

  describe('countConditions', () => {
    it('counts conditions in a flat tree', () => {
      const tree = createEmptyTree()
      const condition1 = createCondition('visit:country', 'is', 'US')
      const condition2 = createCondition('visit:device', 'is', 'Mobile')
      let treeWithConditions = addCondition(tree, tree.root.id, condition1)
      treeWithConditions = addCondition(treeWithConditions, tree.root.id, condition2)

      expect(countConditions(treeWithConditions)).toBe(2)
    })

    it('counts conditions in nested groups', () => {
      const tree = createEmptyTree()
      const condition1 = createCondition('visit:country', 'is', 'US')
      const nestedGroup = createEmptyGroup('and')
      let treeWithGroup = addGroup(tree, tree.root.id, nestedGroup)
      treeWithGroup = addCondition(treeWithGroup, nestedGroup.id, condition1)

      expect(countConditions(treeWithGroup)).toBe(1)
    })
  })

  describe('canAddCondition', () => {
    it('allows adding conditions under the limit', () => {
      const tree = createEmptyTree()

      expect(canAddCondition(tree)).toBe(true)
    })
  })

  describe('canAddGroup', () => {
    it('allows adding groups at root level', () => {
      const tree = createEmptyTree()

      expect(canAddGroup(tree, tree.root.id)).toBe(true)
    })

    it('disallows adding groups beyond max depth', () => {
      // Create a tree that's already at max depth
      let tree = createEmptyTree()

      // Add nested groups to reach depth limit
      let currentGroupId = tree.root.id
      for (let i = 0; i < 4; i++) {
        const nestedGroup = createEmptyGroup('and')
        tree = addGroup(tree, currentGroupId, nestedGroup)
        currentGroupId = nestedGroup.id
      }

      // At depth 4 (0-indexed), we should still be able to add
      expect(canAddGroup(tree, currentGroupId)).toBe(true)

      // Add one more level
      const oneMoreGroup = createEmptyGroup('and')
      tree = addGroup(tree, currentGroupId, oneMoreGroup)

      // Now at depth 5, should be disallowed
      expect(canAddGroup(tree, oneMoreGroup.id)).toBe(false)
    })
  })

  describe('serializeTree and parseTree', () => {
    it('serializes and parses a tree correctly', () => {
      const tree = createEmptyTree()
      const condition = createCondition('visit:country', 'is', 'US')
      const treeWithCondition = addCondition(tree, tree.root.id, condition)

      const serialized = serializeTree(treeWithCondition)
      const parsed = parseTree(serialized)

      expect(parsed).not.toBeNull()
      expect(parsed?.version).toBe(1)
      expect(parsed?.root.children).toHaveLength(1)
      expect(parsed?.root.children[0].attribute).toBe('visit:country')
    })

    it('returns null for invalid JSON', () => {
      const result = parseTree('invalid json')

      expect(result).toBeNull()
    })
  })

  describe('findNode', () => {
    it('finds a condition by ID', () => {
      const tree = createEmptyTree()
      const condition = createCondition('visit:country', 'is', 'US')
      const treeWithCondition = addCondition(tree, tree.root.id, condition)

      const found = findNode(treeWithCondition, condition.id)

      expect(found).toEqual(condition)
    })

    it('returns null for non-existent ID', () => {
      const tree = createEmptyTree()

      const found = findNode(tree, 'non-existent-id')

      expect(found).toBeNull()
    })
  })

  describe('getGroupDepth', () => {
    it('returns 0 for root group', () => {
      const tree = createEmptyTree()

      expect(getGroupDepth(tree, tree.root.id)).toBe(0)
    })

    it('returns correct depth for nested groups', () => {
      let tree = createEmptyTree()
      const nestedGroup = createEmptyGroup('and')
      tree = addGroup(tree, tree.root.id, nestedGroup)

      expect(getGroupDepth(tree, nestedGroup.id)).toBe(1)
    })
  })
})
