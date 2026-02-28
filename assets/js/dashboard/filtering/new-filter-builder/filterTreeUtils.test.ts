import {
  createCondition,
  createGroup,
  createFilterTree,
  addCondition,
  updateCondition,
  deleteCondition,
  addNestedGroup,
  updateConnector,
  isFilterValid,
  filterTreeToLegacyFilters,
  countConditions,
  hasOrLogic,
  hasNestedGroups,
  generateFilterSummary
} from './filterTreeUtils'

describe('filterTreeUtils', () => {
  describe('createCondition', () => {
    it('creates a condition with default values', () => {
      const condition = createCondition()
      expect(condition.id).toBeDefined()
      expect(condition.attribute).toBe('')
      expect(condition.operator).toBe('equals')
      expect(condition.value).toBe('')
      expect(condition.isNegated).toBe(false)
    })

    it('creates a condition with overrides', () => {
      const condition = createCondition({
        attribute: 'country',
        operator: 'contains',
        value: 'US'
      })
      expect(condition.attribute).toBe('country')
      expect(condition.operator).toBe('contains')
      expect(condition.value).toBe('US')
    })
  })

  describe('createGroup', () => {
    it('creates a group with default values', () => {
      const group = createGroup()
      expect(group.id).toBeDefined()
      expect(group.connector).toBe('AND')
      expect(group.conditions).toEqual([])
      expect(group.nestedGroups).toEqual([])
    })
  })

  describe('createFilterTree', () => {
    it('creates a filter tree with root group', () => {
      const tree = createFilterTree()
      expect(tree.rootGroup).toBeDefined()
      expect(tree.rootGroup.id).toBe('root')
    })
  })

  describe('addCondition', () => {
    it('adds a condition to the root group', () => {
      const tree = createFilterTree()
      const condition = createCondition({ attribute: 'country', value: 'US' })
      const newTree = addCondition(tree.rootGroup.id, condition)

      expect(newTree.rootGroup.conditions).toHaveLength(1)
      expect(newTree.rootGroup.conditions[0].attribute).toBe('country')
    })

    it('adds multiple conditions', () => {
      let tree = createFilterTree()
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US' }))
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'browser', value: 'Chrome' }))

      expect(tree.rootGroup.conditions).toHaveLength(2)
    })
  })

  describe('updateCondition', () => {
    it('updates an existing condition', () => {
      const tree = createFilterTree()
      const condition = createCondition({ attribute: 'country', value: 'US' })
      let newTree = addCondition(tree.rootGroup.id, condition)
      const conditionId = newTree.rootGroup.conditions[0].id

      newTree = updateCondition(newTree, conditionId, { value: 'DE' })

      expect(newTree.rootGroup.conditions[0].value).toBe('DE')
    })
  })

  describe('deleteCondition', () => {
    it('removes a condition from the tree', () => {
      const tree = createFilterTree()
      const condition = createCondition({ attribute: 'country', value: 'US' })
      let newTree = addCondition(tree.rootGroup.id, condition)
      const conditionId = newTree.rootGroup.conditions[0].id

      newTree = deleteCondition(newTree, conditionId)

      expect(newTree.rootGroup.conditions).toHaveLength(0)
    })
  })

  describe('addNestedGroup', () => {
    it('adds a nested group to the root', () => {
      const tree = createFilterTree()
      const nestedGroup = createGroup()
      const result = addNestedGroup(tree.rootGroup.id, nestedGroup)

      expect(result.tree.rootGroup.nestedGroups).toHaveLength(1)
      expect(result.error).toBeUndefined()
    })

    it('returns error when max depth exceeded', () => {
      let tree = createFilterTree()

      // Add nested groups up to depth 5
      let groupId = tree.rootGroup.id
      for (let i = 0; i < 5; i++) {
        const nested = createGroup()
        const result = addNestedGroup(groupId, nested)
        if (result.tree.rootGroup.nestedGroups.length > 0) {
          groupId = result.tree.rootGroup.nestedGroups[0].id
          tree = result.tree
        }
      }

      // This should fail at depth 5
      const result = addNestedGroup(groupId, createGroup())
      expect(result.error).toBe('Maximum nesting depth of 5 levels exceeded')
    })
  })

  describe('updateConnector', () => {
    it('changes group connector from AND to OR', () => {
      const tree = createFilterTree()
      const newTree = updateConnector(tree, tree.rootGroup.id, 'OR')

      expect(newTree.rootGroup.connector).toBe('OR')
    })
  })

  describe('isFilterValid', () => {
    it('returns false for empty tree', () => {
      const tree = createFilterTree()
      expect(isFilterValid(tree)).toBe(false)
    })

    it('returns true when condition has all required fields', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: 'US', operator: 'equals' })
      )
      expect(isFilterValid(newTree)).toBe(true)
    })

    it('returns false when condition is missing attribute', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: '', value: 'US' })
      )
      expect(isFilterValid(newTree)).toBe(false)
    })

    it('returns false when condition is missing value (for operators needing value)', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: '', operator: 'equals' })
      )
      expect(isFilterValid(newTree)).toBe(false)
    })

    it('returns true for is_set operator without value', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: '', operator: 'is_set' })
      )
      expect(isFilterValid(newTree)).toBe(true)
    })
  })

  describe('filterTreeToLegacyFilters', () => {
    it('converts single condition to legacy format', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: 'US', operator: 'equals' })
      )

      const filters = filterTreeToLegacyFilters(newTree)
      expect(filters).toEqual([['is', 'country', ['US']]])
    })

    it('converts multiple conditions', () => {
      let tree = createFilterTree()
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US', operator: 'equals' }))
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'browser', value: 'Chrome', operator: 'equals' }))

      const filters = filterTreeToLegacyFilters(tree)
      expect(filters).toEqual([
        ['is', 'country', ['US']],
        ['is', 'browser', ['Chrome']]
      ])
    })

    it('handles does_not_equal operator', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: 'US', operator: 'does_not_equal' })
      )

      const filters = filterTreeToLegacyFilters(newTree)
      expect(filters).toEqual([['is_not', 'country', ['US']]])
    })
  })

  describe('countConditions', () => {
    it('counts conditions in nested groups', () => {
      let tree = createFilterTree()
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US' }))
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'browser', value: 'Chrome' }))

      // Add nested group with condition
      const nested = createGroup()
      nested.conditions.push(createCondition({ attribute: 'device', value: 'mobile' }))

      const result = addNestedGroup(tree.rootGroup.id, nested)
      tree = result.tree

      expect(countConditions(tree)).toBe(3)
    })
  })

  describe('hasOrLogic', () => {
    it('returns false for AND-only tree', () => {
      const tree = createFilterTree()
      expect(hasOrLogic(tree)).toBe(false)
    })

    it('returns true when connector is OR', () => {
      const tree = updateConnector(createFilterTree(), 'root', 'OR')
      expect(hasOrLogic(tree)).toBe(true)
    })
  })

  describe('hasNestedGroups', () => {
    it('returns false for flat tree', () => {
      const tree = createFilterTree()
      expect(hasNestedGroups(tree)).toBe(false)
    })

    it('returns true when nested groups exist', () => {
      const tree = createFilterTree()
      const result = addNestedGroup(tree.rootGroup.id, createGroup())
      expect(hasNestedGroups(result.tree)).toBe(true)
    })
  })

  describe('generateFilterSummary', () => {
    it('generates summary for single condition', () => {
      const tree = createFilterTree()
      const newTree = addCondition(
        tree.rootGroup.id,
        createCondition({ attribute: 'country', value: 'US', operator: 'equals' })
      )

      const summary = generateFilterSummary(newTree)
      expect(summary).toBe('country = US')
    })

    it('generates summary with AND connector', () => {
      let tree = createFilterTree()
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US', operator: 'equals' }))
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'browser', value: 'Chrome', operator: 'equals' }))

      const summary = generateFilterSummary(tree)
      expect(summary).toBe('country = US AND browser = Chrome')
    })

    it('generates summary with OR connector', () => {
      let tree = createFilterTree()
      tree = updateConnector(tree, 'root', 'OR')
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US', operator: 'equals' }))
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'DE', operator: 'equals' }))

      const summary = generateFilterSummary(tree)
      expect(summary).toBe('country = US OR country = DE')
    })

    it('generates summary with nested groups', () => {
      let tree = createFilterTree()
      tree = addCondition(tree.rootGroup.id, createCondition({ attribute: 'country', value: 'US', operator: 'equals' }))

      const nested = createGroup()
      nested.connector = 'OR'
      nested.conditions.push(createCondition({ attribute: 'browser', value: 'Chrome', operator: 'equals' }))
      nested.conditions.push(createCondition({ attribute: 'browser', value: 'Firefox', operator: 'equals' }))

      const result = addNestedGroup(tree.rootGroup.id, nested)
      tree = result.tree

      const summary = generateFilterSummary(tree)
      expect(summary).toBe('country = US AND (browser = Chrome OR browser = Firefox)')
    })
  })
})
